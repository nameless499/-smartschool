import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
