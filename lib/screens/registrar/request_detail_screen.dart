import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../repositories/document_request_repository.dart';
import '../../repositories/payment_repository.dart';
import '../../models/document_request.dart';
import '../../models/payment.dart';
import '../../services/storage_service.dart';
import '../../widgets/requirements_section.dart';

class RequestDetailScreen extends StatefulWidget {
  final DocumentRequest request;
  const RequestDetailScreen({super.key, required this.request});

  @override
  State<RequestDetailScreen> createState() => _RequestDetailScreenState();
}

class _RequestDetailScreenState extends State<RequestDetailScreen> {
  final DocumentRequestRepository _repository = DocumentRequestRepository();
  final PaymentRepository _paymentRepo = PaymentRepository();
  final StorageService _storage = StorageService();

  late DocumentRequest _request;
  bool _isUpdating = false;

  final List<String> _statusOptions = [
    'Pending',
    'Processing',
    'Ready for Pickup',
    'Completed',
    'Rejected',
  ];

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);
  static const Color _bgColor = Color(0xFFF3F7F5);

  @override
  void initState() {
    super.initState();
    _request = widget.request;
    _refreshRequest();
  }

  Future<void> _refreshRequest() async {
    final updated = await _repository.getRequestById(_request.id);
    if (updated != null && mounted) {
      setState(() => _request = updated);
    }
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isUpdating = true);
    try {
      await _repository.updateRequestStatus(_request.id, newStatus);
      await _refreshRequest();
      _showSnack('Status updated to "$newStatus"', Colors.green);
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _togglePayment() async {
    setState(() => _isUpdating = true);
    try {
      final newPaid = !_request.isPaid;
      await _repository.verifyPayment(
        _request.id,
        paid: newPaid,
        reference: newPaid
            ? 'CASH-MANUAL-${DateTime.now().millisecondsSinceEpoch}'
            : null,
      );
      await _refreshRequest();
      _showSnack(
        newPaid ? '✅ Marked as fully paid (Cash)' : '⏳ Marked as unpaid',
        newPaid ? Colors.green : Colors.orange,
      );
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _uploadReleasedDocument() async {
    if (_request.status != 'Completed') {
      _showSnack('Mark the request as "Completed" first', Colors.orange);
      return;
    }

    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Upload Released Document',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );

      if (source == null) return;

      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: 2400,
      );

      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();

      setState(() => _isUpdating = true);

      final path = await _storage.uploadReleasedDocument(
        requestId: _request.id,
        fileName: picked.name,
        bytes: bytes,
      );

      await _repository.attachReleasedFile(
        requestId: _request.id,
        filePath: path,
        fileName: picked.name,
        fileSize: bytes.length,
        notes: 'Released by registrar',
      );

      await _refreshRequest();
      _showSnack('✅ Released document uploaded', Colors.green);
    } catch (e) {
      _showSnack('Upload error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _removeReleasedDocument() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Remove Released File',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to remove the released file from this request?',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: GoogleFonts.poppins(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() => _isUpdating = true);

      if (_request.releasedFilePath != null) {
        await _storage.deleteReleasedDocument(_request.releasedFilePath!);
      }

      await _repository.removeReleasedFile(_request.id);
      await _refreshRequest();
      _showSnack('File removed', Colors.orange);
    } catch (e) {
      _showSnack('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: GoogleFonts.poppins()),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(_request.status);
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: _bgColor,
      // 👇 Fixed gap by removing extendBodyBehindAppBar and matching color
      appBar: AppBar(
        title: Text(
          'Request Details',
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
          onPressed: () => context.pop(true),
        ),
      ),
      body: SafeArea(
        child: _isUpdating
            ? const Center(child: CircularProgressIndicator(color: _brandGreen))
            : RefreshIndicator(
                onRefresh: _refreshRequest,
                color: _brandGreen,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 900),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 👇 SIDE-BY-SIDE LAYOUT FOR DESKTOP
                          if (isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      _buildHeaderCard(color),
                                      const SizedBox(height: 16),
                                      _buildRequestTable(),
                                      const SizedBox(height: 16),
                                      _buildRequirementsCard(),
                                      const SizedBox(height: 16),
                                      _buildPaymentsCard(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      _buildStatusActionsCard(color),
                                      const SizedBox(height: 16),
                                      _buildReleasedDocumentCard(),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else
                            // 👇 STACKED LAYOUT FOR MOBILE
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildHeaderCard(color),
                                const SizedBox(height: 16),
                                _buildStatusActionsCard(color),
                                const SizedBox(height: 16),
                                _buildRequestTable(),
                                const SizedBox(height: 16),
                                _buildRequirementsCard(),
                                const SizedBox(height: 16),
                                _buildPaymentsCard(),
                                const SizedBox(height: 16),
                                _buildReleasedDocumentCard(),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  // ==========================================
  // 1. HEADER CARD (Student Info)
  // ==========================================
  Widget _buildHeaderCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(Icons.person_rounded, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _request.studentName,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _brandGreenDark,
                  ),
                ),
                Text(
                  _request.studentEmail ?? 'No email',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 2. REQUEST DATA TABLE
  // ==========================================
  Widget _buildRequestTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text(
              'Request Information',
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _brandGreenDark,
              ),
            ),
          ),
          _buildTableRow('Request No.', _request.requestNumber),
          _buildTableRow('Document Type', _request.documentName),
          _buildTableRow('Quantity', _request.quantity.toString()),
          _buildTableRow(
            'Unit Price',
            '₱${_request.unitPrice.toStringAsFixed(2)}',
          ),
          _buildTableRow(
            'Total Amount',
            '₱${_request.totalAmount.toStringAsFixed(2)}',
            isBold: true,
            valueColor: _brandGreen,
          ),
          if (_request.purpose != null)
            _buildTableRow('Purpose', _request.purpose!),
          _buildTableRow('Date Submitted', _formatDate(_request.createdAt)),
        ],
      ),
    );
  }

  Widget _buildTableRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                fontSize: 13.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 3. STATUS & ACTIONS CARD
  // ==========================================
  Widget _buildStatusActionsCard(Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Status',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _request.status.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _request.isPaid
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _request.paymentStatus.toUpperCase(),
                        style: GoogleFonts.poppins(
                          color: _request.isPaid ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (_request.isPaid && _request.paymentReference != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.verified_rounded,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ref: ${_request.paymentReference}',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.green.shade800,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),

          Text(
            'Update Status',
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _brandGreenDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _statusOptions.map((status) {
              final isCurrent = status == _request.status;
              return ChoiceChip(
                label: Text(
                  status,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                selected: isCurrent,
                selectedColor: _statusColor(status).withValues(alpha: 0.8),
                backgroundColor: Colors.grey.shade50,
                labelStyle: TextStyle(
                  color: isCurrent ? Colors.white : Colors.black87,
                ),
                side: BorderSide.none,
                onSelected: (selected) {
                  if (selected && !isCurrent) _updateStatus(status);
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),
          // Manual Cash Override
          InkWell(
            onTap: _togglePayment,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _request.isPaid
                    ? Colors.orange.shade50
                    : Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _request.isPaid
                      ? Colors.orange.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _request.isPaid
                        ? Icons.undo_rounded
                        : Icons.check_circle_outline_rounded,
                    color: _request.isPaid ? Colors.orange : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _request.isPaid
                          ? 'Mark as Unpaid (Override)'
                          : 'Force Mark as Paid (Cash)',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _request.isPaid
                            ? Colors.orange.shade800
                            : Colors.green.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 4. REQUIREMENTS CARD
  // ==========================================
  Widget _buildRequirementsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: RequirementsSection(requestId: _request.id, isRegistrar: true),
    );
  }

  // ==========================================
  // 5. PAYMENTS RECORD CARD
  // ==========================================
  Widget _buildPaymentsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: _buildPaymentsSection(),
    );
  }

  Widget _buildPaymentsSection() {
    return FutureBuilder<List<Payment>>(
      future: _paymentRepo.getPaymentsForRequest(_request.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: _brandGreen),
            ),
          );
        }

        if (snapshot.hasError) {
          return Text(
            'Error: ${snapshot.error}',
            style: GoogleFonts.poppins(color: Colors.red),
          );
        }

        final payments = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payments_rounded,
                  color: _brandGreen,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Payment Records',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _brandGreenDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (payments.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'No payment records found.',
                      style: GoogleFonts.poppins(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...payments.map((p) => _paymentTile(p)),
          ],
        );
      },
    );
  }

  Widget _paymentTile(Payment p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                p.isVerified
                    ? Icons.check_circle_rounded
                    : p.isRejected
                    ? Icons.cancel_rounded
                    : Icons.hourglass_top_rounded,
                color: p.isVerified
                    ? Colors.green
                    : p.isRejected
                    ? Colors.red
                    : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₱${p.amount.toStringAsFixed(2)} — ${p.paymentMethod}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (p.referenceNumber != null)
                      Text(
                        'Ref: ${p.referenceNumber}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: p.isVerified
                      ? Colors.green.withValues(alpha: 0.1)
                      : p.isRejected
                      ? Colors.red.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.status,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: p.isVerified
                        ? Colors.green
                        : p.isRejected
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          if (p.isPending) ...[
            const Divider(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () async {
                    final reason = await _askReason();
                    if (reason != null && reason.isNotEmpty) {
                      try {
                        await _paymentRepo.rejectPayment(p.id, reason);
                        await _refreshRequest();
                      } catch (e) {
                        _showSnack('Error: $e', Colors.red);
                      }
                    }
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(
                    'Reject',
                    style: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await _paymentRepo.verifyPayment(p.id);
                      await _repository.verifyPayment(
                        _request.id,
                        paid: true,
                        reference: p.referenceNumber,
                      );
                      await _refreshRequest();
                    } catch (e) {
                      _showSnack('Error: $e', Colors.red);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(80, 36),
                  ),
                  child: Text(
                    'Verify',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<String?> _askReason() {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Reject Payment',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Reason',
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. RELEASED E-COPY CARD
  // ==========================================
  Widget _buildReleasedDocumentCard() {
    final hasFile = _request.hasReleasedFile;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _brandGreen.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.file_present_rounded,
                color: _brandGreen,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Released E-Copy',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _brandGreenDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (!hasFile)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.upload_file_rounded,
                    size: 40,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No released document',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _request.status == 'Completed'
                        ? _uploadReleasedDocument
                        : null,
                    icon: const Icon(Icons.upload_rounded, size: 16),
                    label: Text(
                      'Upload Document',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brandGreen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  if (_request.status != 'Completed')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '⚠️ Mark request as "Completed" first',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 24,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _request.releasedFileName ?? 'Document Uploaded',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _removeReleasedDocument,
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: Text(
                            'Remove',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _uploadReleasedDocument,
                          icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                          label: Text(
                            'Replace',
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _brandGreen,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
