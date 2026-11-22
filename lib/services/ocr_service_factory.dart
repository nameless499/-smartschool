import 'dart:io';
import 'ocr_service.dart';
import 'ocr_service_mobile.dart';
import 'ocr_service_web.dart';

class OCRServiceFactory {
  static OCRService create() {
    if (Platform.isAndroid || Platform.isIOS) {
      return MobileOCRService() as OCRService;
    } else {
      // Web, Windows, macOS, Linux
      return WebOCRService() as OCRService;
    }
  }
}
