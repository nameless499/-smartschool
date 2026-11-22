import 'dart:ui';
import 'package:flutter/material.dart';

class BlurredBackground extends StatelessWidget {
  final Widget child;
  const BlurredBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. The Background Image
        Positioned.fill(
          child: Image.asset(
            'assets/image/medina.jpg', // Ensure this matches your image path
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.red.shade900,
                child: Center(
                  child: Text(
                    'Image Not Found!\n$error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // 2. The Reduced Blur Effect
        Positioned.fill(
          child: ClipRect(
            child: BackdropFilter(
              // ✅ Reduced blur from 5.0 to 2.0 for a clearer image
              filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
              child: Container(
                // ✅ Lightened the dark overlay from 0.4 to 0.25
                color: Colors.black.withOpacity(0.25),
              ),
            ),
          ),
        ),

        // 3. The App UI
        Positioned.fill(child: child),
      ],
    );
  }
}
