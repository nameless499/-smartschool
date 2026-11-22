import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class StudentDetailScreen extends StatefulWidget {
  final Map<String, dynamic> student;
  const StudentDetailScreen({super.key, required this.student});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Map<String, dynamic> _student;

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);
  static const Color _bgColor = Color(0xFFF3F7F5);

  @override
  void initState() {
    super.initState();
    _student = Map.from(widget.student);
  }

  @override
  Widget build(BuildContext context) {
    final name = _student['full_name'] ?? 'Unknown Student';
    final status = _student['status'] ?? 'Enrolled';
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _bgColor,
      // 👇 Removed extendBodyBehindAppBar to fix layout gaps
      appBar: AppBar(
        title: Text(
          'Student Profile',
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
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==========================================
                  // 1. HEADER CARD (Avatar + Name + Status)
                  // ==========================================
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: isDesktop
                          ? [
                              BoxShadow(
                                color: _brandGreen.withValues(alpha: 0.08),
                                blurRadius: 40,
                                spreadRadius: 10,
                                offset: const Offset(0, 20),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.03),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        // Avatar with outer ring
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _brandGreen.withValues(alpha: 0.1),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: _brandGreenDark,
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: GoogleFonts.poppins(
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: _brandGreenDark,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Student ID: ${_student['student_id'] ?? 'N/A'}',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Status Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: status.toLowerCase() == 'enrolled'
                                ? _brandGreen.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: status.toLowerCase() == 'enrolled'
                                  ? _brandGreen.withValues(alpha: 0.3)
                                  : Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: status.toLowerCase() == 'enrolled'
                                  ? _brandGreen
                                  : Colors.orange.shade800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ==========================================
                  // 2. ACADEMIC INFORMATION
                  // ==========================================
                  _buildSection('Academic Information', Icons.school_rounded, [
                    _buildRow('Course', _student['course']),
                    _buildRow('Year Level', _student['year_level']),
                    _buildRow('Semester', _student['semester']),
                    _buildRow('School Year', _student['school_year']),
                    _buildRow('Date Enrolled', _student['date_enrolled']),
                  ]),

                  // ==========================================
                  // 3. PERSONAL INFORMATION
                  // ==========================================
                  _buildSection('Personal Information', Icons.person_rounded, [
                    _buildRow('First Name', _student['first_name']),
                    _buildRow('Middle Name', _student['middle_name']),
                    _buildRow('Last Name', _student['last_name']),
                    _buildRow('Date of Birth', _student['date_of_birth']),
                    _buildRow('Sex', _student['sex']),
                    _buildRow('Civil Status', _student['civil_status']),
                    _buildRow('Religion', _student['religion']),
                    _buildRow('Place of Birth', _student['place_of_birth']),
                    _buildRow('Contact No.', _student['contact_number']),
                    _buildRow('Email', _student['email']),
                    _buildRow('Spouse Name', _student['spouse_name']),
                  ]),

                  // ==========================================
                  // 4. FINANCIAL INFORMATION
                  // ==========================================
                  _buildSection(
                    'Financial Information',
                    Icons.payments_rounded,
                    [
                      _buildRow('Financier Name', _student['financier_name']),
                      _buildRow(
                        'Financier Contact',
                        _student['financier_contact'],
                      ),
                    ],
                  ),

                  // ==========================================
                  // 5. EDUCATIONAL BACKGROUND
                  // ==========================================
                  _buildSection(
                    'Educational Background',
                    Icons.history_edu_rounded,
                    [
                      _buildSubHeader('Elementary'),
                      _buildRow('School', _student['elementary_school']),
                      _buildRow('Address', _student['elementary_address']),
                      _buildRow('Year Graduated', _student['elementary_year']),

                      _buildSubHeader('Junior High School'),
                      _buildRow('School', _student['junior_high_school']),
                      _buildRow('Address', _student['junior_high_address']),
                      _buildRow('Year Graduated', _student['junior_high_year']),

                      _buildSubHeader('Senior High School'),
                      _buildRow('School', _student['senior_high_school']),
                      _buildRow('Address', _student['senior_high_address']),
                      _buildRow('Year Graduated', _student['senior_high_year']),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // Helper Widget for Sections
  // ==========================================
  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: _brandGreen, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: _brandGreenDark,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFEEEEEE)),
          ),
          ...children,
        ],
      ),
    );
  }

  // ==========================================
  // Helper Widget for Sub Headers (e.g., Elementary)
  // ==========================================
  Widget _buildSubHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: _brandGreen,
        ),
      ),
    );
  }

  // ==========================================
  // Helper Widget for a Row of Data
  // ==========================================
  Widget _buildRow(String label, dynamic value) {
    final displayValue = (value == null || value.toString().trim().isEmpty)
        ? 'Not provided'
        : value.toString();

    final isMissing = displayValue == 'Not provided';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130, // Slightly wider for labels
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontStyle: isMissing ? FontStyle.italic : FontStyle.normal,
                color: isMissing ? Colors.grey.shade400 : Colors.black87,
                fontWeight: isMissing ? FontWeight.normal : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
