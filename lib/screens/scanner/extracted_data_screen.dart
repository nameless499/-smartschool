import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/enrollment_parser_service.dart';
import '../../models/parsed_student_data.dart';
import '../../widgets/app_drawer.dart';
import '../../routes/app_routes.dart';
import '../../providers/auth_provider.dart';

class ExtractedDataScreen extends StatefulWidget {
  final Map<String, dynamic>? data;
  const ExtractedDataScreen({super.key, this.data});

  @override
  State<ExtractedDataScreen> createState() => _ExtractedDataScreenState();
}

class _ExtractedDataScreenState extends State<ExtractedDataScreen> {
  late ParsedStudentData _parsedData;
  late File _imageFile;
  bool _isLoading = true;
  String? _saveError;
  bool _isSaving = false;

  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _courseController = TextEditingController();
  final TextEditingController _yearLevelController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _schoolYearController = TextEditingController();

  static const _brandGreen = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final imageFile = widget.data?['imageFile'] as File?;
    final rawText = widget.data?['extractedText'] as String? ?? '';

    _imageFile = imageFile ?? File('');

    if (rawText.isEmpty) {
      _parsedData = const ParsedStudentData(
        studentId: '',
        fullName: '',
        course: '',
        yearLevel: '',
        semester: '',
        schoolYear: '',
      );
    } else {
      _parsedData = EnrollmentParserService.parse(rawText);
    }

    _studentIdController.text = _parsedData.studentId;
    _fullNameController.text = _parsedData.fullName;
    _courseController.text = _parsedData.course;
    _yearLevelController.text = _parsedData.yearLevel;
    _semesterController.text = _parsedData.semester;
    _schoolYearController.text = _parsedData.schoolYear;

    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _studentIdController.dispose();
    _fullNameController.dispose();
    _courseController.dispose();
    _yearLevelController.dispose();
    _semesterController.dispose();
    _schoolYearController.dispose();
    super.dispose();
  }

  void _updateData() {
    // Kept in case you need to re-read the controllers later
    setState(() {
      _parsedData = _parsedData.copyWith(
        studentId: _studentIdController.text.trim(),
        fullName: _fullNameController.text.trim(),
        course: _courseController.text.trim(),
        yearLevel: _yearLevelController.text.trim(),
        semester: _semesterController.text.trim(),
        schoolYear: _schoolYearController.text.trim(),
      );
    });
  }

  Future<void> _confirmAndSave() async {
    _updateData();

    if (_parsedData.studentId.isEmpty ||
        _parsedData.fullName.isEmpty ||
        _parsedData.course.isEmpty ||
        _parsedData.yearLevel.isEmpty ||
        _parsedData.semester.isEmpty ||
        _parsedData.schoolYear.isEmpty) {
      setState(() => _saveError = 'All fields must be filled before saving.');
      return;
    }

    setState(() {
      _saveError = null;
      _isSaving = true;
    });

    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Row(
            children: const [
              Icon(Icons.assignment_turned_in_rounded, color: _brandGreen),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Confirm Student Data',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This information will be saved to the student database.',
                style: TextStyle(fontSize: 12.5),
              ),
              const SizedBox(height: 12),
              _confirmRow('Student ID', _parsedData.studentId),
              _confirmRow('Name', _parsedData.fullName),
              _confirmRow('Course', _parsedData.course),
              _confirmRow('Year', _parsedData.yearLevel),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: _brandGreen),
              child: const Text('Confirm'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final supabase = Supabase.instance.client;

        final existing = await supabase
            .from('students')
            .select()
            .eq('student_id', _parsedData.studentId)
            .maybeSingle();

        final studentData = {
          'student_id': _parsedData.studentId,
          'full_name': _parsedData.fullName,
          'course': _parsedData.course,
          'year_level': _parsedData.yearLevel,
          'semester': _parsedData.semester,
          'school_year': _parsedData.schoolYear,
          'status': 'Enrolled',
          'updated_at': DateTime.now().toIso8601String(),
        };

        if (existing != null) {
          await supabase
              .from('students')
              .update(studentData)
              .eq('student_id', _parsedData.studentId);
        } else {
          studentData['created_at'] = DateTime.now().toIso8601String();
          await supabase.from('students').insert(studentData);
        }

        final authProvider = context.read<AuthProvider>();
        if (authProvider.isAuthenticated && authProvider.profile != null) {
          await supabase
              .from('profiles')
              .update({'student_id': _parsedData.studentId})
              .eq('id', authProvider.profile!.id);
          await authProvider.refreshProfile();
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Student data saved successfully!')),
          );
          context.go(AppRoutes.registrarDashboard);
        }
      }
    } catch (e) {
      setState(() => _saveError = 'Error saving: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _scanAnother() {
    context.go(AppRoutes.scanner);
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Extracted Data'),
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), _brandGreen],
              ),
            ),
          ),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Review & Edit',
          style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.2),
        ),
        foregroundColor: Colors.white,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B5E20), _brandGreen],
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.scannerPreview),
        ),
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderCard(colors),
              const SizedBox(height: 14),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Column(
                    children: [
                      _buildEditableField(
                        label: 'Student ID',
                        icon: Icons.badge_outlined,
                        controller: _studentIdController,
                        confident: _parsedData.studentIdConfident,
                        onChanged: (_) => _updateData(),
                      ),
                      _buildEditableField(
                        label: 'Full Name',
                        icon: Icons.person_outline_rounded,
                        controller: _fullNameController,
                        confident: _parsedData.fullNameConfident,
                        onChanged: (_) => _updateData(),
                      ),
                      _buildEditableField(
                        label: 'Course',
                        icon: Icons.school_outlined,
                        controller: _courseController,
                        confident: _parsedData.courseConfident,
                        onChanged: (_) => _updateData(),
                      ),
                      _buildEditableField(
                        label: 'Year Level',
                        icon: Icons.layers_outlined,
                        controller: _yearLevelController,
                        confident: _parsedData.yearLevelConfident,
                        onChanged: (_) => _updateData(),
                      ),
                      _buildEditableField(
                        label: 'Semester',
                        icon: Icons.calendar_month_outlined,
                        controller: _semesterController,
                        confident: _parsedData.semesterConfident,
                        onChanged: (_) => _updateData(),
                      ),
                      _buildEditableField(
                        label: 'School Year',
                        icon: Icons.event_outlined,
                        controller: _schoolYearController,
                        confident: _parsedData.schoolYearConfident,
                        onChanged: (_) => _updateData(),
                      ),
                    ],
                  ),
                ),
              ),
              _buildErrorBanner(colors),
              const SizedBox(height: 4),
              _buildActions(colors),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------- Header card
  Widget _buildHeaderCard(ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: _imageFile.path.isNotEmpty
                ? Image.file(
                    _imageFile,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 72,
                    height: 72,
                    color: colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: colors.outline,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Review the extracted data.',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                ),
                const SizedBox(height: 4),
                Text(
                  'Fields marked ⚠️ were not confidently extracted. Please re-scan if data is incorrect.',
                  style: TextStyle(color: colors.outline, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------- Error banner
  Widget _buildErrorBanner(ColorScheme colors) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _saveError == null
          ? const SizedBox.shrink()
          : Container(
              key: const ValueKey('save-error'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 18,
                    color: colors.onErrorContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _saveError!,
                      style: TextStyle(
                        color: colors.onErrorContainer,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ------------------------------------------------------------- Actions
  Widget _buildActions(ColorScheme colors) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isSaving ? null : _scanAnother,
            icon: const Icon(Icons.camera_alt_rounded, size: 18),
            label: const Text('Scan Another'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: shape,
              side: BorderSide(color: colors.outlineVariant),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isSaving ? null : _confirmAndSave,
            icon: _isSaving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.save_rounded, size: 18),
            label: const Text('Confirm & Save'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: _brandGreen,
              shape: shape,
            ),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------- Field widget
  Widget _buildEditableField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required bool confident,
    required ValueChanged<String> onChanged,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isEmpty = controller.text.trim().isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isEmpty ? colors.error.withAlpha(90) : colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: colors.onPrimaryContainer),
              ),
              const SizedBox(width: 10),
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              const Spacer(),
              _confidenceChip(confident),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: controller,
            // 👇 THIS MAKES IT READ-ONLY
            readOnly: true,
            showCursor: false,
            enableInteractiveSelection: false,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'No data extracted',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
              filled: true,
              fillColor: confident
                  ? Colors.grey.shade50
                  : Colors.orange.shade50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: isEmpty
                      ? colors.error.withAlpha(120)
                      : colors.outlineVariant,
                ),
              ),
              // 👇 Keep the focus border so it looks nice if tapped
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: colors.outlineVariant),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _confidenceChip(bool confident) {
    final bg = confident ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0);
    final fg = confident ? const Color(0xFF2E7D32) : const Color(0xFFE65100);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            confident ? Icons.verified_rounded : Icons.warning_amber_rounded,
            size: 11,
            color: fg,
          ),
          const SizedBox(width: 4),
          Text(
            confident ? 'Verified' : 'Check',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
