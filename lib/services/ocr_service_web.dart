import 'dart:io';
import 'ocr_service.dart';

class WebOCRService implements OCRService {
  @override
  Future<String> extractText(File imageFile) async {
    // Simulate OCR by returning a dummy text
    await Future.delayed(const Duration(seconds: 1));
    return '''
Student ID: 20230015
Name: Juan Dela Cruz
Course: BS Information Technology
Year Level: 3rd Year
Semester: 1st Semester
School Year: 2026-2027
''';
  }

  @override
  void dispose() {
    // No resources to release on web; can leave empty.
    // If you had any controllers or streams, close them here.
  }
}
