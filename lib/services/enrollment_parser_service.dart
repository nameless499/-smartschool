import '../models/parsed_student_data.dart';

class EnrollmentParserService {
  static ParsedStudentData parse(String rawText) {
    // 1. Clean the text but KEEP newlines (crucial for this form)
    final text = rawText.replaceAll('\r\n', '\n').trim();
    final flatText = text.replaceAll(RegExp(r'[ \t]+'), ' ');

    // Helper 1: Extract value AFTER a label (e.g., "Date of Birth: 05/15/2008")
    String extractAfter(String labelPattern) {
      final regex = RegExp(
        '$labelPattern\\s*[:\\-]?\\s*([^\\n]+)',
        caseSensitive: false,
      );
      final match = regex.firstMatch(flatText);
      return match?.group(1)?.trim() ?? '';
    }

    // Helper 2: Extract value BEFORE a label (e.g., "Juan Dela Cruz \n Family Name")
    String extractBefore(String labelPattern) {
      final regex = RegExp(
        '([^\\n]+)\\n\\s*$labelPattern',
        caseSensitive: false,
      );
      final match = regex.firstMatch(text);
      return match?.group(1)?.trim() ?? '';
    }

    // Helper 3: Extract from a specific section block (for Education table)
    String extractEdu(String label, int index) {
      final regex = RegExp('([^\\n]+)\\s+$label', caseSensitive: false);
      final match = regex.firstMatch(flatText);
      if (match != null) {
        final parts = match.group(1)!.trim().split(RegExp(r'\s{2,}'));
        if (parts.length > index) return parts[index].trim();
        if (parts.isNotEmpty) return parts.first.trim();
      }
      return '';
    }

    // ============================================================
    // CORE INFORMATION
    // ============================================================
    String studentId = extractAfter(r'Student\s*I\.D\.\s*#?');
    if (studentId.isEmpty) {
      final idRegex = RegExp(r'\b(\d{6,10})\b');
      final m = idRegex.firstMatch(flatText);
      if (m != null) studentId = m.group(1)!;
    }

    String dateEnrolled = extractAfter(r'Date\s*Enrolled');
    String course = extractAfter(r'Course\s*to\s*Take');

    // ============================================================
    // NAME
    // ============================================================
    String lastName = extractBefore(r'Family\s*Name');
    String firstName = extractBefore(r'Given\s*Name');
    String middleName = extractBefore(r'Middle\s*Name');

    if (firstName.isEmpty && lastName.isEmpty) {
      final nameLine = extractAfter(r'(?:Name)');
      final parts = nameLine.split(' ');
      if (parts.length >= 2) {
        firstName = parts[0];
        lastName = parts.last;
      }
    }

    String fullName = [
      firstName,
      middleName,
      lastName,
    ].where((s) => s.isNotEmpty).join(' ');

    // ============================================================
    // PERSONAL INFO
    // ============================================================
    String dob = extractAfter(r'Date\s*of\s*Birth');
    String sex = extractAfter(r'\bSex\b');
    String civilStatus = extractAfter(r'Civil\s*Status');
    String religion = extractAfter(r'Religion');
    String placeOfBirth = extractAfter(r'Place\s*Birth');
    String email = extractAfter(r'email\s*add\.?');
    String spouseName = extractAfter(r'Name\s*of\s*Husband\s*/?\s*Wife.*?:?');
    String contactNumber = extractAfter(r'Contact\s*no\.?');

    // ============================================================
    // FINANCIAL
    // ============================================================
    String financierName = extractAfter(
      r'Person\s*Responsible\s*to\s*Finance.*?:?',
    );

    final allContacts =
        RegExp(r'Contact\s*no\.?\s*[:\-]?\s*([0-9\-\s]+)', caseSensitive: false)
            .allMatches(flatText)
            .map((m) => m.group(1)?.trim() ?? '')
            .where((s) => s.isNotEmpty)
            .toList();
    String financierContact = allContacts.length > 1 ? allContacts[1] : '';

    // ============================================================
    // PRELIMINARY EDUCATION
    // ============================================================
    String elemSchool = extractEdu(r'Elementary\s*School', 0);
    String elemAddress = extractEdu(r'Elementary\s*School', 1);
    String elemYear = extractAfter(r'Elementary\s*School.*?Year\s*Graduated');

    String jhsSchool = extractEdu(r'Junior\s*High\s*School', 0);
    String jhsAddress = extractEdu(r'Junior\s*High\s*School', 1);
    String jhsYear = extractAfter(r'Junior\s*High\s*School.*?Year\s*Graduated');

    String shsSchool = extractEdu(r'Senior\s*High\s*School', 0);
    String shsAddress = extractEdu(r'Senior\s*High\s*School', 1);
    String shsYear = extractAfter(r'Senior\s*High\s*School.*?Year\s*Graduated');

    // ============================================================
    // CLEANUP & VALIDATION
    // ============================================================
    studentId = studentId.replaceAll(RegExp(r'[^0-9]'), '');
    if (studentId.length > 10) studentId = studentId.substring(0, 10);

    String clean(String val) {
      if (val.contains('Family Name'))
        return val.split('Family Name').first.trim();
      if (val.contains('Given Name'))
        return val.split('Given Name').first.trim();
      if (val.contains('Middle Name'))
        return val.split('Middle Name').first.trim();
      return val.trim();
    }

    firstName = clean(firstName);
    lastName = clean(lastName);
    middleName = clean(middleName);

    final bool idConfident = studentId.length >= 6;
    final bool nameConfident = firstName.isNotEmpty && lastName.isNotEmpty;

    return ParsedStudentData(
      studentId: studentId,
      fullName: fullName,
      course: course,
      yearLevel: '1st Year',
      semester: '1st Semester',
      schoolYear: '2026-2027',
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      dateOfBirth: dob,
      sex: sex,
      civilStatus: civilStatus,
      religion: religion,
      placeOfBirth: placeOfBirth,
      contactNumber: contactNumber,
      email: email,
      spouseName: spouseName,
      dateEnrolled: dateEnrolled,
      financierName: financierName,
      financierContact: financierContact,
      elementarySchool: elemSchool,
      elementaryAddress: elemAddress,
      elementaryYear: elemYear,
      juniorHighSchool: jhsSchool,
      juniorHighAddress: jhsAddress,
      juniorHighYear: jhsYear,
      seniorHighSchool: shsSchool,
      seniorHighAddress: shsAddress,
      seniorHighYear: shsYear,
      studentIdConfident: idConfident,
      fullNameConfident: nameConfident,
    );
  }
}
