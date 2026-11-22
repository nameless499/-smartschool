import 'package:smartschool/models/parsed_student_data.dart';

class ParserService {
  /// Extracts structured student data from raw OCR text.
  /// Uses regex patterns to find labels and values.
  static ParsedStudentData parse(String rawText) {
    // Normalize text: replace newlines and multiple spaces with single space
    final text = rawText.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Helper to extract value after a label
    String? extractValue(String labelPattern) {
      // Look for label followed by colon or whitespace, then capture the value
      final regex = RegExp(
        '$labelPattern\\s*[:\\-]?\\s*([^\\n\\r,;]+)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(text);
      if (match != null) {
        return match.group(1)?.trim();
      }
      return null;
    }

    // Define label patterns (case-insensitive)
    final studentIdPattern = r'(?:student\s*(?:id|number|no\.?)|id\s*no\.?)';
    final namePattern = r'(?:full\s*name|name|student\s*name)';
    final coursePattern = r'(?:course|program|degree|curriculum)';
    final yearPattern = r'(?:year\s*(?:level|standing)|year)';
    final semesterPattern = r'(?:semester|term)';
    final schoolYearPattern = r'(?:school\s*year|academic\s*year|s\.y\.?)';

    // Extract values
    String studentId = extractValue(studentIdPattern) ?? '';
    String fullName = extractValue(namePattern) ?? '';
    String course = extractValue(coursePattern) ?? '';
    String yearLevel = extractValue(yearPattern) ?? '';
    String semester = extractValue(semesterPattern) ?? '';
    String schoolYear = extractValue(schoolYearPattern) ?? '';

    // Additional fallback: try to detect patterns like "20230015" for ID, etc.
    if (studentId.isEmpty) {
      // Look for a 8-digit number at start of line or after "ID"
      final idRegex = RegExp(r'\b(\d{8})\b');
      final idMatch = idRegex.firstMatch(text);
      if (idMatch != null) {
        studentId = idMatch.group(1)!;
      }
    }
    if (fullName.isEmpty) {
      // Try to find a name pattern: two words capitalized
      final nameRegex = RegExp(r'\b([A-Z][a-z]+(?:\s+[A-Z][a-z]+)+)\b');
      final nameMatch = nameRegex.firstMatch(text);
      if (nameMatch != null) {
        fullName = nameMatch.group(1)!;
      }
    }
    // More fallbacks can be added as needed.

    // Clean up common OCR errors
    studentId = _cleanValue(studentId);
    fullName = _cleanValue(fullName);
    course = _cleanValue(course);
    yearLevel = _cleanValue(yearLevel);
    semester = _cleanValue(semester);
    schoolYear = _cleanValue(schoolYear);

    // Determine confidence: if the field is non-empty and length > 2, assume confident
    final bool studentIdConfident =
        studentId.isNotEmpty && studentId.length >= 8;
    final bool fullNameConfident =
        fullName.isNotEmpty && fullName.split(' ').length >= 2;
    final bool courseConfident = course.isNotEmpty && course.length >= 3;
    final bool yearLevelConfident =
        yearLevel.isNotEmpty &&
        (yearLevel.contains(RegExp(r'\d')) || yearLevel.contains('Year'));
    final bool semesterConfident =
        semester.isNotEmpty &&
        (semester.contains(RegExp(r'\d')) || semester.contains('Semester'));
    final bool schoolYearConfident =
        schoolYear.isNotEmpty && schoolYear.contains(RegExp(r'\d{4}'));

    return ParsedStudentData(
      studentId: studentId,
      fullName: fullName,
      course: course,
      yearLevel: yearLevel,
      semester: semester,
      schoolYear: schoolYear,
      studentIdConfident: studentIdConfident,
      fullNameConfident: fullNameConfident,
      courseConfident: courseConfident,
      yearLevelConfident: yearLevelConfident,
      semesterConfident: semesterConfident,
      schoolYearConfident: schoolYearConfident,
    );
  }

  /// Clean common OCR artifacts
  static String _cleanValue(String value) {
    // Remove trailing punctuation, extra spaces
    value = value.replaceAll(RegExp(r'[,\.;:]+$'), '').trim();
    // Replace multiple spaces with single
    value = value.replaceAll(RegExp(r'\s+'), ' ');
    return value;
  }
}
