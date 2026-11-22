import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/document_request_repository.dart';
import '../../models/document_request.dart';
import '../../models/document_type.dart';
import '../../routes/app_routes.dart';
import '../../widgets/demo_google_play_checkout.dart';

class DocumentRequestScreen extends StatefulWidget {
  const DocumentRequestScreen({super.key});

  @override
  State<DocumentRequestScreen> createState() => _DocumentRequestScreenState();
}

class _DocumentRequestScreenState extends State<DocumentRequestScreen> {
  final DocumentRequestRepository _repository = DocumentRequestRepository();
  List<DocumentType> _documentTypes = [];
  bool _isLoading = true;
  String? _error;

  DocumentType? _selectedType;
  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );
  final TextEditingController _purposeController = TextEditingController();

  static const Color _brandGreen = Color(0xFF006633);
  static const Color _brandGreenDark = Color(0xFF004D26);

  @override
  void initState() {
    super.initState();
    _loadDocumentTypes();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _purposeController.dispose();
    super.dispose();
  }

  Future<void> _loadDocumentTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final types = await _repository.getDocumentTypes();
      setState(() {
        _documentTypes = types;
        _isLoading = false;
        if (types.isNotEmpty && _selectedType == null) {
          _selectedType = types.first;
        }
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load document types: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    final profile = context.read<AuthProvider>().profile;
    if (profile == null) return;

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a document type')),
      );
      return;
    }

    final quantity = int.tryParse(_quantityController.text) ?? 1;
    final totalAmount = _selectedType!.basePrice * quantity;
    final newRequestNumber = DocumentRequestRepository.generateRequestNumber();

    // 👇 1. OPEN PAYMENT SCREEN
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DemoGooglePlayCheckout(
        amount: totalAmount,
        itemName: _selectedType!.name,
        requestNumber: newRequestNumber,
      ),
    );

    // If the user cancelled the payment, don't create the request
    if (result != true) return;

    // 👇 2. IF PAID, CREATE THE REQUEST
    final demoRef =
        'GP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final request = DocumentRequest(
      id: '',
      requestNumber: newRequestNumber,
      studentId: profile.studentId,
      studentName: profile.fullName,
      studentEmail: profile.email,
      documentTypeId: _selectedType!.id,
      documentName: _selectedType!.name,
      quantity: quantity,
      unitPrice: _selectedType!.basePrice,
      totalAmount: totalAmount,
      purpose: _purposeController.text.trim().isNotEmpty
          ? _purposeController.text.trim()
          : null,
      status: 'Processing', // Automatically Processing since it's paid
      paymentStatus: 'Paid', // Marked as Paid
      paymentReference: demoRef, // Save the reference
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      setState(() => _isLoading = true);
      await _repository.createRequest(request);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Request submitted and paid successfully!',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.go(AppRoutes.requestStatus);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving request: $e',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F7F5), // Clean background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Request Document',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: _brandGreenDark,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: _brandGreenDark),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.studentDashboard),
        ),
      ),
      body: SafeArea(
        // 👇 Removed the outer Center and reduced top padding to 20
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Center(
            // Centers the content horizontally
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.only(top: 40),
                      child: Center(
                        child: CircularProgressIndicator(color: _brandGreen),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: GoogleFonts.poppins(color: Colors.red),
                      ),
                    )
                  : Container(
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
                            : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _brandGreen.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.post_add_rounded,
                                size: 40,
                                color: _brandGreen,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              'New Request',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: _brandGreenDark,
                              ),
                            ),
                          ),
                          Center(
                            child: Text(
                              'Select the document you need.',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Document Type Selector
                          Text(
                            'Document Type',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<DocumentType>(
                                isExpanded: true,
                                icon: const Icon(
                                  Icons.keyboard_arrow_down,
                                  color: _brandGreen,
                                ),
                                value: _selectedType,
                                items: _documentTypes.map((type) {
                                  return DropdownMenuItem(
                                    value: type,
                                    child: Text(
                                      '${type.name} - ₱${type.basePrice.toStringAsFixed(2)}',
                                      style: GoogleFonts.poppins(fontSize: 14),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (val) =>
                                    setState(() => _selectedType = val),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Quantity Selector
                          Text(
                            'Quantity',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildQtyButton(Icons.remove, () {
                                final current =
                                    int.tryParse(_quantityController.text) ?? 1;
                                if (current > 1) {
                                  setState(
                                    () => _quantityController.text =
                                        (current - 1).toString(),
                                  );
                                }
                              }),
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 70,
                                child: TextField(
                                  controller: _quantityController,
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                  decoration: InputDecoration(
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade200,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 12),
                              _buildQtyButton(Icons.add, () {
                                final current =
                                    int.tryParse(_quantityController.text) ?? 1;
                                setState(
                                  () => _quantityController.text = (current + 1)
                                      .toString(),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Total Price Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: _brandGreen,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _brandGreen.withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total Amount',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₱${((int.tryParse(_quantityController.text) ?? 1) * (_selectedType?.basePrice ?? 0)).toStringAsFixed(2)}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Purpose Field
                          Text(
                            'Purpose (Optional)',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _purposeController,
                            style: GoogleFonts.poppins(),
                            decoration: InputDecoration(
                              hintText: 'e.g., For PRC, For Employment',
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey.shade500,
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: Colors.grey.shade200,
                                ),
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
                            maxLines: 2,
                          ),
                          const SizedBox(height: 32),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _submitRequest,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _brandGreen,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Proceed to Payment',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
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

  Widget _buildQtyButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _brandGreen.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: _brandGreen),
      ),
    );
  }
}
