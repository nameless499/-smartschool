import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/document_request_repository.dart';
import '../../models/document_request.dart';
import '../../widgets/notification_bell.dart';
import '../../widgets/requirements_section.dart';
import '../../widgets/student_bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class RequestStatusScreen extends StatefulWidget {
  const RequestStatusScreen({super.key});

  @override
  State<RequestStatusScreen> createState() => _RequestStatusScreenState();
}

class _RequestStatusScreenState extends State<RequestStatusScreen> {
  final DocumentRequestRepository _repository = DocumentRequestRepository();
  final TextEditingController _searchController = TextEditingController();

  List<DocumentRequest> _allRequests = [];
  List<DocumentRequest> _filteredRequests = [];
  bool _isLoading = true;

  // Filter State
  String _searchQuery = '';
  String _selectedDocument = 'All Documents';
  List<String> _availableDocuments = ['All Documents'];

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);
  static const Color _bgColor = Color(0xFFF3F7F5);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilterAndSearch);
    _loadRequests();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRequests() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final email = context.read<AuthProvider>().profile?.email;
      if (email != null) {
        final reqs = await _repository.getStudentRequests(email);
        if (mounted) {
          setState(() {
            _allRequests = reqs;

            // Extract unique document names for the filter
            final uniqueDocs = reqs.map((r) => r.documentName).toSet().toList();
            uniqueDocs.sort();
            _availableDocuments = ['All Documents', ...uniqueDocs];

            // If the previously selected document no longer exists, reset to All
            if (!_availableDocuments.contains(_selectedDocument)) {
              _selectedDocument = 'All Documents';
            }

            _isLoading = false;
          });
          _applyFilterAndSearch();
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilterAndSearch() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase().trim();

      _filteredRequests = _allRequests.where((req) {
        // 1. Check Document Filter
        final matchesDocument =
            _selectedDocument == 'All Documents' ||
            req.documentName == _selectedDocument;

        // 2. Check Search Query (name or ref number)
        final matchesSearch =
            req.documentName.toLowerCase().contains(_searchQuery) ||
            req.requestNumber.toLowerCase().contains(_searchQuery);

        return matchesDocument && matchesSearch;
      }).toList();

      // Automatically sort by Date (Newest)
      _filteredRequests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Icons.pending_actions_rounded;
      case 'processing':
        return Icons.autorenew_rounded;
      case 'completed':
        return Icons.check_circle_rounded;
      case 'rejected':
        return Icons.cancel_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'My Requests',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _brandGreenDark,
            fontSize: 20,
          ),
        ),
        backgroundColor: _bgColor,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false, // 👈 Removes auto back button
        iconTheme: const IconThemeData(color: _brandGreenDark),
        actions: [
          // FILTER BUTTON
          PopupMenuButton<String>(
            tooltip: 'Filter by Document',
            icon: const Icon(Icons.filter_list_rounded, color: _brandGreenDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              setState(() => _selectedDocument = value);
              _applyFilterAndSearch();
            },
            itemBuilder: (context) => _availableDocuments.map((doc) {
              final isSelected = _selectedDocument == doc;
              return PopupMenuItem<String>(
                value: doc,
                child: Row(
                  children: [
                    if (isSelected)
                      const Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: _brandGreen,
                      )
                    else
                      const SizedBox(width: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        doc,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: const StudentBottomNavBar(currentIndex: 1),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _brandGreen))
          : Column(
              children: [
                // SEARCH BAR
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

                // TABLE / LIST
                Expanded(
                  child: _filteredRequests.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _loadRequests,
                          color: _brandGreen,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            itemCount: _filteredRequests.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildTableHeader();
                              return _buildTableRow(
                                _filteredRequests[index - 1],
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
    final isFiltering =
        _searchQuery.isNotEmpty || _selectedDocument != 'All Documents';

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
              isFiltering
                  ? Icons.filter_list_off_rounded
                  : Icons.receipt_long_rounded,
              size: 64,
              color: _brandGreen,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isFiltering ? 'No matching requests found' : 'No requests yet',
            style: GoogleFonts.poppins(
              color: _brandGreenDark,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isFiltering
                ? 'Try adjusting your search or filter.'
                : 'Any document requests you make will appear here.',
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

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
          _buildHeaderText('Document', flex: 3),
          _buildHeaderText('Date', flex: 2),
          _buildHeaderText('Amount', flex: 2),
          _buildHeaderText('Status', flex: 2),
          const SizedBox(width: 20),
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
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTableRow(DocumentRequest req) {
    final color = _statusColor(req.status);

    return InkWell(
      onTap: () => _showRequestDetails(req),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.documentName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    req.requestNumber,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM d, yyyy').format(req.createdAt.toLocal()),
                style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                '₱${req.totalAmount.toStringAsFixed(2)}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: _brandGreenDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      req.status.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 20,
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

  void _showRequestDetails(DocumentRequest req) {
    final color = _statusColor(req.status);
    final icon = _statusIcon(req.status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icon, color: color, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.documentName,
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ref: ${req.requestNumber}',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildDetailRow(
                      Icons.flag_rounded,
                      'Status',
                      req.status.toUpperCase(),
                      color: color,
                    ),
                    _buildDetailRow(
                      Icons.payments_rounded,
                      'Amount',
                      '₱${req.totalAmount.toStringAsFixed(2)}',
                    ),
                    _buildDetailRow(
                      req.isPaid
                          ? Icons.check_circle_rounded
                          : Icons.hourglass_top_rounded,
                      'Payment',
                      req.isPaid ? 'Paid' : 'Unpaid',
                      color: req.isPaid ? Colors.green : Colors.orange,
                    ),
                    _buildDetailRow(
                      Icons.calendar_today_rounded,
                      'Date Requested',
                      DateFormat(
                        'MMM d, yyyy • h:mm a',
                      ).format(req.createdAt.toLocal()),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: RequirementsSection(
                        requestId: req.id,
                        isRegistrar: false,
                      ),
                    ),
                    const SizedBox(height: 16),

                    if (!req.isPaid)
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            context.push(AppRoutes.payments);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.payment_rounded),
                          label: Text(
                            'Pay Now',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? _brandGreen),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
