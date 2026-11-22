import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OCRService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Extracts text from the given image file.
  /// Returns a string containing all recognized text.
  Future<String> extractText(File imageFile) async {
    try {
      // Convert File to InputImage
      final inputImage = InputImage.fromFile(imageFile);
      // Process the image
      final RecognizedText recognisedText = await _textRecognizer.processImage(
        inputImage,
      );
      // Collect all text blocks
      final String fullText = recognisedText.text;
      return fullText;
    } catch (e) {
      throw Exception('OCR failed: $e');
    }
  }

  /// Disposes the recognizer when done.
  void dispose() {
    _textRecognizer.close();
  }
}
