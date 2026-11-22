class Student {
  final String id;
  final String studentId;
  final String fullName;
  final String course;
  final String yearLevel;
  final String semester;
  final String schoolYear;
  final String status;
  final String? email;
  final DateTime createdAt;
  final DateTime updatedAt;

  Student({
    required this.id,
    required this.studentId,
    required this.fullName,
    required this.course,
    required this.yearLevel,
    required this.semester,
    required this.schoolYear,
    required this.status,
    this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      fullName: json['full_name'] as String,
      course: json['course'] as String,
      yearLevel: json['year_level'] as String,
      semester: json['semester'] as String,
      schoolYear: json['school_year'] as String,
      status: json['status'] as String? ?? 'Enrolled',
      email: json['email'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'student_id': studentId,
      'full_name': fullName,
      'course': course,
      'year_level': yearLevel,
      'semester': semester,
      'school_year': schoolYear,
      'status': status,
      'email': email,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  Student copyWith({
    String? id,
    String? studentId,
    String? fullName,
    String? course,
    String? yearLevel,
    String? semester,
    String? schoolYear,
    String? status,
    String? email,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Student(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      fullName: fullName ?? this.fullName,
      course: course ?? this.course,
      yearLevel: yearLevel ?? this.yearLevel,
      semester: semester ?? this.semester,
      schoolYear: schoolYear ?? this.schoolYear,
      status: status ?? this.status,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
