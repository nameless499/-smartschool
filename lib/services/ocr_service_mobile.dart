import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class MobileOCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  Future<String> extractText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(
        inputImage,
      );
      // Combine all text blocks
      String fullText = '';
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          fullText += line.text + '\n';
        }
      }
      return fullText.trim();
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  void dispose() {
    _textRecognizer.close();
  }
}
