import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class EmbeddingService {
  static const String ollamaEmbeddingUrl =
      'http://localhost:11434/api/embeddings';

  /// Generate an embedding vector for a text string using Ollama
  Future<List<double>> generateEmbedding(String text) async {
    try {
      final response = await http.post(
        Uri.parse(ollamaEmbeddingUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': 'all-minilm', // lightweight embedding model
          'prompt': text,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final embedding = data['embedding'] as List<dynamic>;
        return embedding.map((e) => e as double).toList();
      } else {
        throw Exception('Failed to generate embedding: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error generating embedding: $e');
    }
  }

  /// Generate embeddings for all knowledge base entries (migration)
  Future<void> migrateAllKnowledge() async {
    final supabase = Supabase.instance.client;

    // Get all knowledge entries without embeddings
    // Use .filter() for null check (works with Supabase v2)
    final entries = await supabase
        .from('chatbot_knowledge')
        .select()
        .filter('embedding', 'is', null);

    for (var entry in entries) {
      try {
        // Combine question and answer for better context
        final text =
            'Question: ${entry['question']}\nAnswer: ${entry['answer']}';
        final embedding = await generateEmbedding(text);

        // Update the record with the embedding
        await supabase
            .from('chatbot_knowledge')
            .update({'embedding': embedding})
            .eq('id', entry['id']);
      } catch (e) {
        // Continue with next entry if one fails
        print('Error embedding entry ${entry['id']}: $e');
      }
    }
  }
}
