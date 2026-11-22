import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/document_request_repository.dart';
import '../../models/document_request.dart';
import '../../widgets/app_drawer.dart';
import '../../widgets/blurred_background.dart';
import '../../routes/app_routes.dart';
import '../../services/notification_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen>
    with WidgetsBindingObserver {
  final DocumentRequestRepository _repository = DocumentRequestRepository();
  List<DocumentRequest> _requests = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final email = context.read<AuthProvider>().profile?.email;
      if (email != null) {
        final reqs = await _repository.getStudentRequests(email);
        if (mounted) {
          // 👇 Show ALL requests (Paid and Unpaid)
          setState(() => _requests = reqs);
        }
      }
    } catch (e) {
      debugPrint('Error loading requests: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openGooglePlayDemo(DocumentRequest req) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DemoGooglePlayCheckout(
        amount: req.totalAmount,
        itemName: req.documentName,
        requestNumber: req.requestNumber,
      ),
    );

    if (result == true) {
      try {
        final demoRef =
            'GP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

        // 1. Update Database
        await _repository.verifyPayment(req.id, paid: true, reference: demoRef);
        await _repository.updateRequestStatus(req.id, 'Processing');

        // 2. Refresh List immediately
        await _loadData();

        if (mounted) {
          // 3. Trigger Real Notification
          await NotificationService().showPaymentSuccessNotification(
            amount: req.totalAmount,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Payment successful! Status updated to Paid.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating database: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Payments',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.go(AppRoutes.studentDashboard),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: BlurredBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                )
              : _requests.isEmpty
              ? Center(
                  child: Text(
                    'No payment records found.',
                    style: GoogleFonts.poppins(color: Colors.white),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length,
                    itemBuilder: (context, index) {
                      final req = _requests[index];
                      final isPaid = req.isPaid;

                      return Card(
                        elevation: 8,
                        color: Colors.white.withValues(alpha: 0.90),
                        shadowColor: Colors.black.withValues(alpha: 0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isPaid
                                ? Colors.green.withValues(alpha: 0.5)
                                : Colors.white.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isPaid
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.orange.withValues(
                                              alpha: 0.15,
                                            ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isPaid
                                          ? Icons.check_circle_rounded
                                          : Icons.receipt_long_rounded,
                                      color: isPaid
                                          ? Colors.green
                                          : Colors.orange,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          req.documentName,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        Text(
                                          'Ref: ${req.requestNumber}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '₱${req.totalAmount.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isPaid
                                          ? Colors.green
                                          : const Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (isPaid)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.verified_rounded,
                                        color: Colors.green,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Paid',
                                        style: GoogleFonts.poppins(
                                          color: Colors.green,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                SizedBox(
                                  width: double.infinity,
                                  height: 48,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _openGooglePlayDemo(req),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0070BA),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'Pay with GCash',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

// ============================================================================
// GOOGLE PLAY DEMO CHECKOUT
// ============================================================================
class DemoGooglePlayCheckout extends StatefulWidget {
  final double amount;
  final String itemName;
  final String requestNumber;

  const DemoGooglePlayCheckout({
    super.key,
    required this.amount,
    required this.itemName,
    required this.requestNumber,
  });

  @override
  State<DemoGooglePlayCheckout> createState() => _DemoGooglePlayCheckoutState();
}

enum GooglePlayStep { checkout, verifying, success }

class _DemoGooglePlayCheckoutState extends State<DemoGooglePlayCheckout> {
  GooglePlayStep _step = GooglePlayStep.checkout;

  void _processPayment() {
    setState(() => _step = GooglePlayStep.verifying);
    Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _step = GooglePlayStep.success);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1E1E1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_step) {
      case GooglePlayStep.checkout:
        return _buildCheckoutStep();
      case GooglePlayStep.verifying:
        return _buildVerifyingStep();
      case GooglePlayStep.success:
        return _buildSuccessStep();
    }
  }

  Widget _buildCheckoutStep() {
    return Column(
      key: const ValueKey('checkout'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Google Play',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 18),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70),
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          color: Colors.amber.withValues(alpha: 0.1),
          child: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'You\'ve already gone over your budget, which will reset on Dec 1, 2026',
                  style: GoogleFonts.roboto(color: Colors.amber, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.blue.shade900,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school, color: Colors.white),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.itemName,
                      style: GoogleFonts.roboto(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'SmartSchool',
                      style: GoogleFonts.roboto(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '₱${widget.amount.toStringAsFixed(2)}',
                style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.g_mobiledata,
                  color: Color(0xFF0070BA),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'GCash: 63-9****17597',
                  style: GoogleFonts.roboto(color: Colors.white, fontSize: 14),
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white70),
            ],
          ),
        ),
        const Divider(color: Colors.white12, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
          child: Column(
            children: [
              Text(
                'Tap "1-tap buy" to complete your purchase',
                style: GoogleFonts.roboto(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA8C7FA),
                    foregroundColor: const Color(0xFF001D35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  child: Text(
                    '1-tap buy',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyingStep() {
    return Padding(
      key: const ValueKey('verifying'),
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Color(0xFFA8C7FA)),
          const SizedBox(height: 24),
          Text(
            'Verifying with GCash...',
            style: GoogleFonts.roboto(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      key: const ValueKey('success'),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 50,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Payment Successful',
            style: GoogleFonts.roboto(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA8C7FA),
                foregroundColor: const Color(0xFF001D35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
