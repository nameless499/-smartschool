import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../repositories/document_request_repository.dart';
import '../../models/document_request.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/notification_bell.dart';
import '../../routes/app_routes.dart';

class DocumentProcessingScreen extends StatefulWidget {
  const DocumentProcessingScreen({super.key});

  @override
  State<DocumentProcessingScreen> createState() =>
      _DocumentProcessingScreenState();
}

class _DocumentProcessingScreenState extends State<DocumentProcessingScreen> {
  final DocumentRequestRepository _repo = DocumentRequestRepository();
  final TextEditingController _searchController = TextEditingController();

  List<DocumentRequest> _allRequests = [];
  List<DocumentRequest> _filteredRequests = [];
  bool _isLoading = true;

  // Filters & Sorting
  String _selectedFilter = 'Pending';
  String _sortOption = 'Date (Newest)';

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);
  static const Color _bgColor = Color(0xFFF3F7F5);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterAndSort);
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final reqs = await _repo.getAllRequests();
      if (mounted) {
        _allRequests = reqs;
        _filterAndSort();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterAndSort() {
    final query = _searchController.text.toLowerCase().trim();

    // 1. Filter
    List<DocumentRequest> result = _allRequests.where((req) {
      final matchesStatus =
          _selectedFilter == 'All' ||
          req.status.toLowerCase() == _selectedFilter.toLowerCase();

      final matchesSearch =
          req.studentName.toLowerCase().contains(query) ||
          req.documentName.toLowerCase().contains(query) ||
          req.requestNumber.toLowerCase().contains(query);

      return matchesStatus && matchesSearch;
    }).toList();

    // 2. Sort
    switch (_sortOption) {
      case 'Date (Newest)':
        result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Date (Oldest)':
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'Document (A-Z)':
        result.sort(
          (a, b) => a.documentName.toLowerCase().compareTo(
            b.documentName.toLowerCase(),
          ),
        );
        break;
      case 'Student (A-Z)':
        result.sort(
          (a, b) => a.studentName.toLowerCase().compareTo(
            b.studentName.toLowerCase(),
          ),
        );
        break;
      case 'Status':
        result.sort((a, b) => a.status.compareTo(b.status));
        break;
    }

    if (mounted) {
      setState(() {
        _filteredRequests = result;
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'processing':
        return Colors.blue;
      case 'ready for pickup':
        return Colors.purple;
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
      case 'ready for pickup':
        return Icons.shopping_bag_rounded;
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
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: Text(
          'Process Requests',
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
          onPressed: () => context.go(AppRoutes.registrarDashboard),
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort',
            icon: const Icon(Icons.sort_rounded, color: _brandGreenDark),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (value) {
              setState(() => _sortOption = value);
              _filterAndSort();
            },
            itemBuilder: (context) => [
              _buildSortItem('Date (Newest)'),
              _buildSortItem('Date (Oldest)'),
              _buildSortItem('Document (A-Z)'),
              _buildSortItem('Student (A-Z)'),
              _buildSortItem('Status'),
            ],
          ),
          const NotificationBell(),
          const SizedBox(width: 8),
        ],
      ),
      drawer: const AppDrawer(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _brandGreen))
            : Center(
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
                          // 👇 THE CRITICAL FIX: Prevent this column from taking all height
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchController,
                              style: GoogleFonts.poppins(fontSize: 14),
                              decoration: InputDecoration(
                                hintText: 'Search by name, document, or ref...',
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
                                        onPressed: () =>
                                            _searchController.clear(),
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
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade200,
                                  ),
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

                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    [
                                      'Pending',
                                      'Processing',
                                      'Completed',
                                      'All',
                                    ].map((filter) {
                                      final isSelected =
                                          _selectedFilter == filter;
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8.0,
                                        ),
                                        child: ChoiceChip(
                                          label: Text(
                                            filter,
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
                                          onSelected: (val) {
                                            if (val) {
                                              setState(
                                                () => _selectedFilter = filter,
                                              );
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
                      // 2. REQUESTS TABLE
                      // ==========================================
                      Expanded(
                        child: _filteredRequests.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off_rounded,
                                      size: 64,
                                      color: Colors.grey.shade300,
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No requests found.',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _loadData,
                                color: _brandGreen,
                                child: ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    8,
                                    24,
                                    32,
                                  ),
                                  itemCount: _filteredRequests.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) return _buildTableHeader();
                                    return _buildRequestRow(
                                      _filteredRequests[index - 1],
                                      isDesktop,
                                    );
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

  // ==========================================
  // TABLE HEADER (Aligned with Data)
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
          const SizedBox(width: 40), // Space for the 40x40 icon
          const SizedBox(width: 12), // Gap after icon
          _buildHeaderText('Student / Document', flex: 3),
          _buildHeaderText('Amount', flex: 2),
          _buildHeaderText('Date', flex: 2),
          _buildHeaderText('Status', flex: 2),
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
  Widget _buildRequestRow(DocumentRequest req, bool isDesktop) {
    final color = _statusColor(req.status);

    return InkWell(
      onTap: () => context.push(AppRoutes.requestDetail, extra: req),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(
          children: [
            // 1. Status Icon (Fixed width of 40 to match header)
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_statusIcon(req.status), color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // 2. Student Name & Document
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min, // 👈 Added safety
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    req.studentName,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: _brandGreenDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    req.documentName,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // 3. Amount
            if (isDesktop || MediaQuery.of(context).size.width > 500)
              Expanded(
                flex: 2,
                child: Text(
                  '₱${req.totalAmount.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: _brandGreenDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

            // 4. Date
            Expanded(
              flex: 2,
              child: Text(
                DateFormat('MMM d, yyyy').format(req.createdAt.toLocal()),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // 5. Status Badge
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
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 6. Arrow
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
}
