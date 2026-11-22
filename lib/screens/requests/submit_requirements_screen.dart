import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/document_request.dart';

class SubmitRequirementsScreen extends StatefulWidget {
  final DocumentRequest request;
  const SubmitRequirementsScreen({super.key, required this.request});

  @override
  State<SubmitRequirementsScreen> createState() =>
      _SubmitRequirementsScreenState();
}

class _SubmitRequirementsScreenState extends State<SubmitRequirementsScreen> {
  final _supabase = Supabase.instance.client;
  final _picker = ImagePicker();
  final List<File> _selectedFiles = [];
  List<String> _requiredDocuments = [];
  bool _isLoadingRequirements = true;
  bool _isUploading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadRequiredDocuments();
  }

  Future<void> _loadRequiredDocuments() async {
    setState(() => _isLoadingRequirements = true);
    try {
      final response = await _supabase
          .from('document_types')
          .select('required_documents')
          .eq('id', widget.request.documentTypeId ?? '')
          .maybeSingle();

      if (response != null && response['required_documents'] != null) {
        setState(() {
          _requiredDocuments = List<String>.from(
            response['required_documents'] as List,
          );
        });
      } else {
        setState(() {
          _requiredDocuments = [
            'Valid Student ID',
            'Certificate of Enrollment',
          ];
        });
      }
    } catch (e) {
      debugPrint('Load requirements error: $e');
      setState(() {
        _requiredDocuments = ['Valid Student ID', 'Certificate of Enrollment'];
      });
    } finally {
      if (mounted) setState(() => _isLoadingRequirements = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(source: source, imageQuality: 80);
      if (picked != null) {
        setState(() => _selectedFiles.add(File(picked.path)));
      }
    } catch (e) {
      setState(() => _error = 'Failed to pick image: $e');
    }
  }

  Future<void> _upload() async {
    if (_selectedFiles.isEmpty) {
      setState(() => _error = 'Please add at least one file');
      return;
    }

    if (_selectedFiles.length != _requiredDocuments.length) {
      setState(
        () => _error =
            'Please upload exactly ${_requiredDocuments.length} file(s) — one for each requirement.',
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _error = null;
    });

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not logged in');

      final uploadedUrls = <String>[];

      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final ext = file.path.split('.').last;
        final fileName =
            '${user.id}/${widget.request.id}/${DateTime.now().millisecondsSinceEpoch}_$i.$ext';

        await _supabase.storage
            .from('requirements')
            .upload(
              fileName,
              file,
              fileOptions: const FileOptions(upsert: true),
            );

        final url = _supabase.storage
            .from('requirements')
            .getPublicUrl(fileName);
        uploadedUrls.add(url);
      }

      await _supabase
          .from('document_requests')
          .update({
            'requirement_files': uploadedUrls,
            'requirements_passed': true,
            'requirements_submitted_at': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.request.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Requirements submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _error = 'Upload failed: $e');
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Submit Requirements',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: _isLoadingRequirements
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
              )
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF1B5E20,
                            ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.description_rounded,
                            color: Color(0xFF1B5E20),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.request.documentName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Ref: ${widget.request.requestNumber}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Required Documents (${_requiredDocuments.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Upload exactly one file for each requirement below.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._requiredDocuments.asMap().entries.map((entry) {
                    final hasFile = entry.key < _selectedFiles.length;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            hasFile
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 18,
                            color: hasFile
                                ? Colors.green
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.value,
                              style: GoogleFonts.poppins(fontSize: 13),
                            ),
                          ),
                          if (hasFile)
                            Text(
                              'File ${entry.key + 1}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                color: Colors.green,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  Text(
                    'Uploaded Files (${_selectedFiles.length}/${_requiredDocuments.length})',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_selectedFiles.isNotEmpty) ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _selectedFiles.asMap().entries.map((entry) {
                        return Stack(
                          children: [
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                                image: DecorationImage(
                                  image: FileImage(entry.value),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 2,
                              right: 2,
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _selectedFiles.removeAt(entry.key),
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isUploading ||
                                  _selectedFiles.length >=
                                      _requiredDocuments.length
                              ? null
                              : () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_alt_rounded),
                          label: const Text('Camera'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed:
                              _isUploading ||
                                  _selectedFiles.length >=
                                      _requiredDocuments.length
                              ? null
                              : () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _upload,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B5E20),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              'Submit Requirements (${_selectedFiles.length}/${_requiredDocuments.length})',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
