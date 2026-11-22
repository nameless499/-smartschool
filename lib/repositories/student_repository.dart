import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/student_model.dart';

class StudentRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<Student>> getAllStudents() async {
    final response = await _client.from('students').select();
    return response.map<Student>((json) => Student.fromJson(json)).toList();
  }

  Future<Student?> getStudentByStudentId(String studentId) async {
    final response = await _client
        .from('students')
        .select()
        .eq('student_id', studentId)
        .maybeSingle();
    if (response == null) return null;
    return Student.fromJson(response);
  }

  Future<void> saveStudent(Student student) async {
    final existing = await getStudentByStudentId(student.studentId);
    if (existing != null) {
      await _client
          .from('students')
          .update(student.toJson())
          .eq('student_id', student.studentId);
    } else {
      await _client.from('students').insert(student.toJson());
    }
  }

  Future<void> deleteStudent(String studentId) async {
    await _client.from('students').delete().eq('student_id', studentId);
  }
}
