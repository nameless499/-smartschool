import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/document_request_repository.dart';
import '../../models/document_request.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/student_bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class ReleasedDocumentsScreen extends StatefulWidget {
  const ReleasedDocumentsScreen({super.key});

  @override
  State<ReleasedDocumentsScreen> createState() =>
      _ReleasedDocumentsScreenState();
}

class _ReleasedDocumentsScreenState extends State<ReleasedDocumentsScreen> {
  final DocumentRequestRepository _repository = DocumentRequestRepository();
  final TextEditingController _searchController = TextEditingController();

  List<DocumentRequest> _allDocuments = [];
  List<DocumentRequest> _filteredDocuments = [];
  bool _isLoading = true;

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);
  static const Color _bgColor = Color(0xFFF3F7F5);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applySearch);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final email = context.read<AuthProvider>().profile?.email;
      if (email != null) {
        final docs = await _repository.getStudentReleasedDocuments(email);
        if (mounted) {
          setState(() {
            _allDocuments = docs;
            _filteredDocuments = docs;
          });
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filteredDocuments = _allDocuments.where((doc) {
        return doc.documentName.toLowerCase().contains(query) ||
            doc.requestNumber.toLowerCase().contains(query);
      }).toList();
    });
  }

  Future<void> _downloadDocument(DocumentRequest doc) async {
    if (doc.releasedFilePath == null || doc.releasedFilePath!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File not available for download.')),
      );
      return;
    }

    final uri = Uri.parse(doc.releasedFilePath!);
    try {
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch download URL');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _bgColor,
      // 👇 Removed extendBodyBehindAppBar to fix the layout gap
      appBar: AppBar(
        title: Text(
          'Released Documents',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _brandGreenDark,
            fontSize: 20,
          ),
        ),
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // 👈 Removed back button
        iconTheme: const IconThemeData(color: _brandGreenDark),
        actions: const [NotificationBell(), SizedBox(width: 8)],
      ),
      bottomNavigationBar: const StudentBottomNavBar(currentIndex: 2),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGreen))
          : Column(
              children: [
                // 👇 SEARCH BAR
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    style: GoogleFonts.poppins(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search document or ref no...',
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
                              icon: const Icon(Icons.clear, color: Colors.grey),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                ),

                // 👇 LIST
                Expanded(
                  child: _filteredDocuments.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadData,
                          color: _brandGreen,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filteredDocuments.length,
                            itemBuilder: (context, index) {
                              return _buildDocumentCard(
                                _filteredDocuments[index],
                                isDesktop,
                              );
                            },
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    final isSearching = _searchController.text.isNotEmpty;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _brandGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.folder_shared_rounded,
              size: 64,
              color: _brandGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No matching documents' : 'No released documents',
            style: GoogleFonts.poppins(
              color: _brandGreenDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSearching
                ? 'Try adjusting your search keywords.'
                : 'Any documents released by the registrar will appear here.',
            style: GoogleFonts.poppins(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(DocumentRequest doc, bool isDesktop) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: _brandGreen.withValues(alpha: 0.05),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.red,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),

          // Text Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.documentName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: _brandGreenDark,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ref: ${doc.requestNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      size: 12,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Released: ${doc.releasedAt != null ? DateFormat('MMM d, yyyy').format(doc.releasedAt!.toLocal()) : 'N/A'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Download Button
          InkWell(
            onTap: () => _downloadDocument(doc),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _brandGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.download_rounded,
                color: _brandGreen,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
