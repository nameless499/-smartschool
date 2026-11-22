import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';
import 'embedding_service.dart';

class ChatbotService {
  final SupabaseClient _client = Supabase.instance.client;

  // ============================================================
  // GROQ CLOUD API CONFIGURATION
  // ============================================================
  static const String groqUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // 👇 PASTE YOUR NEW API KEY HERE (Delete the old one in Groq Console!)
  static const String groqApiKey =
      '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';

  // 👇 CURRENT ACTIVE MODEL
  static const String groqModel = 'openai/gpt-oss-20b';

  final EmbeddingService _embeddingService = EmbeddingService();

  /// Generate a response using semantic search (vector embeddings)
  Future<String> generateResponse(String userMessage, Student? student) async {
    try {
      // 1. Convert user question to embedding
      final questionEmbedding = await _embeddingService.generateEmbedding(
        userMessage,
      );

      // 2. Find similar knowledge using pgvector
      final knowledge = await _semanticSearch(questionEmbedding);

      // 3. Build the prompt
      final prompt = _buildPrompt(userMessage, student, knowledge);

      // 4. Call Groq
      return await _callGroq(prompt);
    } catch (e) {
      // Fallback: if embedding fails, use keyword search
      try {
        final knowledge = await _keywordSearch(userMessage);
        final prompt = _buildPrompt(userMessage, student, knowledge);
        return await _callGroq(prompt);
      } catch (fallbackError) {
        return 'System Error: Could not process your question. Please try again.';
      }
    }
  }

  /// Semantic search using pgvector
  Future<List<Map<String, dynamic>>> _semanticSearch(
    List<double> embedding,
  ) async {
    final response = await _client.rpc(
      'find_similar_knowledge',
      params: {
        'query_embedding': embedding,
        'match_threshold': 0.5,
        'max_results': 3,
      },
    );
    return response;
  }

  /// Fallback: keyword search
  Future<List<Map<String, dynamic>>> _keywordSearch(String query) async {
    final response = await _client
        .from('chatbot_knowledge')
        .select()
        .eq('active', true)
        .ilike('question', '%$query%')
        .limit(3);
    return response;
  }

  String _buildPrompt(
    String userMessage,
    Student? student,
    List<dynamic> knowledge,
  ) {
    String studentInfo = '';
    if (student != null) {
      studentInfo =
          '''
Student Information:
- Name: ${student.fullName}
- Student ID: ${student.studentId}
- Course: ${student.course}
- Year Level: ${student.yearLevel}
- Semester: ${student.semester}
- School Year: ${student.schoolYear}
''';
    }

    String knowledgeText = '';
    if (knowledge.isNotEmpty) {
      knowledgeText = 'Registrar Knowledge Base Context:\n';
      for (var item in knowledge) {
        final question = item['question'] ?? '';
        final answer = item['answer'] ?? '';
        knowledgeText += 'Q: $question\nA: $answer\n\n';
      }
    }

    // 👇 DYNAMIC BUT STRICT SYSTEM PROMPT
    return '''
You are the SmartSchool AI Assistant for Medina College. You are smart, conversational, and helpful.

YOUR ONLY SCOPE:
You only handle inquiries regarding:
1. Document Requests (Transcript of Records, Good Moral, Certificate of Enrollment, etc.)
2. Registrar policies (fees, processing times, requirements)
3. The student's own enrollment information (their course, year level, etc.)

YOUR RULES:
- If the student asks a question that falls within your scope, answer it dynamically and naturally using the provided context.
- If the student asks about out-of-scope topics (like class schedules, grades, professors, or campus events), you must politely decline. Say something like: "I apologize, but my scope is limited to document requests and registrar policies. I cannot assist with class schedules, grades, or other concerns."
- Never invent (hallucinate) registrar policies. Only use the knowledge base context provided below. If you don't know the answer based on the context, politely say you don't have that information and suggest they contact the Registrar's Office.

$studentInfo
$knowledgeText

Student Question: $userMessage

Respond dynamically based on your scope and rules:
''';
  }

  /// Call the Groq Cloud API
  Future<String> _callGroq(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(groqUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqApiKey',
        },
        body: jsonEncode({
          'model': groqModel,
          'messages': [
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      );

      // 🟢 SUCCESS
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      // 🔴 ERROR HANDLING
      else {
        print('--- GROQ API ERROR ---');
        print('Status Code: ${response.statusCode}');
        print('Response Body: ${response.body}');

        if (response.statusCode == 401) {
          return 'Error: Invalid API Key. Please check your Groq API key in the code.';
        } else if (response.statusCode == 429) {
          return 'Error: Rate limit exceeded. Please wait a moment and try again.';
        } else {
          return 'Error ${response.statusCode}: Unable to reach AI service. Check debug console.';
        }
      }
    } catch (e) {
      print('--- NETWORK ERROR ---');
      print('Error Details: $e');
      return 'Error: Network connection failed. Are you connected to the internet?';
    }
  }
}
