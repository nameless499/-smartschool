import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_drawer.dart';
import '../../routes/app_routes.dart';
import 'student_detail_screen.dart';

class StudentRecordsScreen extends StatefulWidget {
  const StudentRecordsScreen({super.key});

  @override
  State<StudentRecordsScreen> createState() => _StudentRecordsScreenState();
}

class _StudentRecordsScreenState extends State<StudentRecordsScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allStudents = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _isLoading = true;

  // Filter & Sort State
  String _selectedCourse = 'All';
  List<String> _courses = ['All'];
  String _sortOption = 'Name (A-Z)';

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);
  static const Color _bgColor = Color(0xFFF3F7F5);

  @override
  void initState() {
    super.initState();
    _loadStudents();
    _searchController.addListener(_filterAndSort);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final res = await Supabase.instance.client
          .from('students')
          .select()
          .order('full_name');

      final students = List<Map<String, dynamic>>.from(res);

      final uniqueCourses =
          students
              .map((s) => s['course'] as String? ?? 'Unknown')
              .where((c) => c.isNotEmpty && c != 'Unknown')
              .toSet()
              .toList()
            ..sort();

      setState(() {
        _allStudents = students;
        _courses = ['All', ...uniqueCourses];
        _isLoading = false;
      });
      _filterAndSort();
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  void _filterAndSort() {
    final q = _searchController.text.toLowerCase().trim();

    // 1. Filter
    List<Map<String, dynamic>> result = _allStudents.where((s) {
      final matchesCourse =
          _selectedCourse == 'All' || s['course'] == _selectedCourse;
      final matchesSearch =
          (s['full_name'] ?? '').toLowerCase().contains(q) ||
          (s['student_id'] ?? '').toLowerCase().contains(q);
      return matchesCourse && matchesSearch;
    }).toList();

    // 2. Sort
    result.sort((a, b) {
      if (_sortOption == 'Name (A-Z)') {
        return (a['full_name'] ?? '').toString().toLowerCase().compareTo(
          (b['full_name'] ?? '').toString().toLowerCase(),
        );
      } else if (_sortOption == 'Name (Z-A)') {
        return (b['full_name'] ?? '').toString().toLowerCase().compareTo(
          (a['full_name'] ?? '').toString().toLowerCase(),
        );
      } else if (_sortOption == 'Student ID') {
        return (a['student_id'] ?? '').toString().compareTo(
          (b['student_id'] ?? '').toString(),
        );
      } else if (_sortOption == 'Course') {
        return (a['course'] ?? '').toString().compareTo(
          (b['course'] ?? '').toString(),
        );
      }
      return 0;
    });

    setState(() => _filtered = result);
  }

  @override
  Widget build(BuildContext context) {
    final role = context.read<AuthProvider>().role ?? 'registrar';

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'Student Records',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _brandGreenDark,
          ),
        ),
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _brandGreenDark),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (role == 'admin') {
              context.go(AppRoutes.adminDashboard);
            } else {
              context.go(AppRoutes.registrarDashboard);
            }
          },
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort Records',
            icon: const Icon(Icons.sort_rounded, color: _brandGreenDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              setState(() => _sortOption = value);
              _filterAndSort();
            },
            itemBuilder: (context) => [
              _buildSortItem('Name (A-Z)'),
              _buildSortItem('Name (Z-A)'),
              _buildSortItem('Student ID'),
              _buildSortItem('Course'),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                // ==========================================
                // 1. SEARCH BAR & FILTER CHIPS
                // ==========================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by name or student ID...',
                          hintStyle: GoogleFonts.poppins(
                            color: Colors.grey.shade400,
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: _brandGreen,
                            size: 22,
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => _searchController.clear(),
                                )
                              : null,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: _brandGreen,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (!_isLoading && _courses.length > 1)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _courses.map((course) {
                              final isSelected = _selectedCourse == course;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8.0),
                                child: ChoiceChip(
                                  label: Text(
                                    course,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: _brandGreen,
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  side: BorderSide(
                                    color: isSelected
                                        ? _brandGreen
                                        : Colors.grey.shade300,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() => _selectedCourse = course);
                                      _filterAndSort();
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),

                // ==========================================
                // 2. STUDENT TABLE
                // ==========================================
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _brandGreen),
                        )
                      : _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.people_outline_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No students found.',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadStudents,
                          color: _brandGreen,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                            itemCount: _filtered.length + 1, // +1 for header
                            itemBuilder: (context, i) {
                              if (i == 0) return _buildTableHeader();
                              return _buildTableRow(_filtered[i - 1]);
                            },
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // TABLE HEADER
  // ==========================================
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 40), // Space for the avatar
          _buildHeaderText('Student Name', flex: 3),
          _buildHeaderText('Student ID', flex: 2),
          _buildHeaderText('Course', flex: 2),
          const SizedBox(width: 24), // Space for arrow
        ],
      ),
    );
  }

  Widget _buildHeaderText(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // ==========================================
  // TABLE ROW
  // ==========================================
  Widget _buildTableRow(Map<String, dynamic> s) {
    final name = s['full_name'] as String? ?? '?';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return InkWell(
      onTap: () => context.push(AppRoutes.studentDetail, extra: s),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: _brandGreen.withValues(alpha: 0.1),
              child: Text(
                initial,
                style: const TextStyle(
                  color: _brandGreen,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Name
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: _brandGreenDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Student ID
            Expanded(
              flex: 2,
              child: Text(
                '${s['student_id'] ?? 'No ID'}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Course
            Expanded(
              flex: 2,
              child: Text(
                s['course'] ?? 'No Course',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: _brandGreen,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Arrow
            const SizedBox(
              width: 24,
              child: Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuEntry<String> _buildSortItem(String option) {
    final isSelected = _sortOption == option;
    return PopupMenuItem<String>(
      value: option,
      child: Row(
        children: [
          if (isSelected)
            const Icon(Icons.check_rounded, size: 18, color: _brandGreen)
          else
            const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(
            option,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
