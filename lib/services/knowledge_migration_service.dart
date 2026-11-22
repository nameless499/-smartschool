import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'embedding_service.dart';

class KnowledgeMigrationService {
  static Future<void> migrateAllKnowledge(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final embeddingService = EmbeddingService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('Generating Embeddings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Please wait while we generate embeddings for the knowledge base...',
            ),
          ],
        ),
      ),
    );

    try {
      await embeddingService.migrateAllKnowledge();
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '✅ Knowledge base embeddings generated successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error: $e')));
      }
    }
  }
}
