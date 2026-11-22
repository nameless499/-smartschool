class ParsedStudentData {
  // ============================================================
  // CORE INFORMATION
  // ============================================================
  final String studentId;
  final String fullName;
  final String course;
  final String yearLevel;
  final String semester;
  final String schoolYear;

  // ============================================================
  // PERSONAL INFORMATION
  // ============================================================
  final String firstName;
  final String middleName;
  final String lastName;
  final String dateOfBirth;
  final String sex;
  final String civilStatus;
  final String religion;
  final String placeOfBirth;
  final String contactNumber;
  final String email;
  final String spouseName;

  // ============================================================
  // ENROLLMENT
  // ============================================================
  final String dateEnrolled;

  // ============================================================
  // FINANCIAL
  // ============================================================
  final String financierName;
  final String financierContact;

  // ============================================================
  // PRELIMINARY EDUCATION
  // ============================================================
  final String elementarySchool;
  final String elementaryAddress;
  final String elementaryYear;
  final String juniorHighSchool;
  final String juniorHighAddress;
  final String juniorHighYear;
  final String seniorHighSchool;
  final String seniorHighAddress;
  final String seniorHighYear;

  // ============================================================
  // CONFIDENCE FLAGS (Core fields only)
  // ============================================================
  final bool studentIdConfident;
  final bool fullNameConfident;
  final bool courseConfident;
  final bool yearLevelConfident;
  final bool semesterConfident;
  final bool schoolYearConfident;

  const ParsedStudentData({
    // Core
    required this.studentId,
    required this.fullName,
    required this.course,
    required this.yearLevel,
    required this.semester,
    required this.schoolYear,
    // Personal
    this.firstName = '',
    this.middleName = '',
    this.lastName = '',
    this.dateOfBirth = '',
    this.sex = '',
    this.civilStatus = '',
    this.religion = '',
    this.placeOfBirth = '',
    this.contactNumber = '',
    this.email = '',
    this.spouseName = '',
    // Enrollment
    this.dateEnrolled = '',
    // Financial
    this.financierName = '',
    this.financierContact = '',
    // Education
    this.elementarySchool = '',
    this.elementaryAddress = '',
    this.elementaryYear = '',
    this.juniorHighSchool = '',
    this.juniorHighAddress = '',
    this.juniorHighYear = '',
    this.seniorHighSchool = '',
    this.seniorHighAddress = '',
    this.seniorHighYear = '',
    // Confidence
    this.studentIdConfident = false,
    this.fullNameConfident = false,
    this.courseConfident = false,
    this.yearLevelConfident = false,
    this.semesterConfident = false,
    this.schoolYearConfident = false,
  });

  /// Returns a new instance with updated values (for editing)
  ParsedStudentData copyWith({
    String? studentId,
    String? fullName,
    String? course,
    String? yearLevel,
    String? semester,
    String? schoolYear,
    String? firstName,
    String? middleName,
    String? lastName,
    String? dateOfBirth,
    String? sex,
    String? civilStatus,
    String? religion,
    String? placeOfBirth,
    String? contactNumber,
    String? email,
    String? spouseName,
    String? dateEnrolled,
    String? financierName,
    String? financierContact,
    String? elementarySchool,
    String? elementaryAddress,
    String? elementaryYear,
    String? juniorHighSchool,
    String? juniorHighAddress,
    String? juniorHighYear,
    String? seniorHighSchool,
    String? seniorHighAddress,
    String? seniorHighYear,
    bool? studentIdConfident,
    bool? fullNameConfident,
    bool? courseConfident,
    bool? yearLevelConfident,
    bool? semesterConfident,
    bool? schoolYearConfident,
  }) {
    return ParsedStudentData(
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      semester: semester ?? this.semester,
      schoolYear: schoolYear ?? this.schoolYear,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      sex: sex ?? this.sex,
      civilStatus: civilStatus ?? this.civilStatus,
      religion: religion ?? this.religion,
      placeOfBirth: placeOfBirth ?? this.placeOfBirth,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      spouseName: spouseName ?? this.spouseName,
      dateEnrolled: dateEnrolled ?? this.dateEnrolled,
      financierName: financierName ?? this.financierName,
      financierContact: financierContact ?? this.financierContact,
      elementarySchool: elementarySchool ?? this.elementarySchool,
      elementaryAddress: elementaryAddress ?? this.elementaryAddress,
      elementaryYear: elementaryYear ?? this.elementaryYear,
      juniorHighSchool: juniorHighSchool ?? this.juniorHighSchool,
      juniorHighAddress: juniorHighAddress ?? this.juniorHighAddress,
      juniorHighYear: juniorHighYear ?? this.juniorHighYear,
      seniorHighSchool: seniorHighSchool ?? this.seniorHighSchool,
      seniorHighAddress: seniorHighAddress ?? this.seniorHighAddress,
      seniorHighYear: seniorHighYear ?? this.seniorHighYear,
      studentIdConfident: studentIdConfident ?? this.studentIdConfident,
      fullNameConfident: fullNameConfident ?? this.fullNameConfident,
      courseConfident: courseConfident ?? this.courseConfident,
      yearLevelConfident: yearLevelConfident ?? this.yearLevelConfident,
      semesterConfident: semesterConfident ?? this.semesterConfident,
      schoolYearConfident: schoolYearConfident ?? this.schoolYearConfident,
    );
  }

  /// Returns true if all core fields have confidence
  bool get isComplete =>
      studentIdConfident &&
      fullNameConfident &&
      courseConfident &&
      yearLevelConfident &&
      semesterConfident &&
      schoolYearConfident;

  /// Converts to JSON (for saving later)
  Map<String, dynamic> toJson() => {
    'student_id': studentId,
    'full_name': fullName,
    'course': course,
    'year_level': yearLevel,
    'semester': semester,
    'school_year': schoolYear,
    'first_name': firstName,
    'middle_name': middleName,
    'last_name': lastName,
    'date_of_birth': dateOfBirth,
    'sex': sex,
    'civil_status': civilStatus,
    'religion': religion,
    'place_of_birth': placeOfBirth,
    'contact_number': contactNumber,
    'email': email.isEmpty ? null : email,
    'spouse_name': spouseName,
    'date_enrolled': dateEnrolled,
    'financier_name': financierName,
    'financier_contact': financierContact,
    'elementary_school': elementarySchool,
    'elementary_address': elementaryAddress,
    'elementary_year': elementaryYear,
    'junior_high_school': juniorHighSchool,
    'junior_high_address': juniorHighAddress,
    'junior_high_year': juniorHighYear,
    'senior_high_school': seniorHighSchool,
    'senior_high_address': seniorHighAddress,
    'senior_high_year': seniorHighYear,
  };
}
