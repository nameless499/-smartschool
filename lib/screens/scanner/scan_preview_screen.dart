import 'dart:io';
import 'package:flutter/foundation.dart'; // 👈 Required for kIsWeb
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart'; // 👈 Required for XFile
import '../../services/ocr_service.dart';
import '../../routes/app_routes.dart';

class ScanPreviewScreen extends StatefulWidget {
  // 👇 THIS IS THE CRITICAL FIX: Change File? to XFile?
  final XFile? imageFile;
  const ScanPreviewScreen({super.key, this.imageFile});

  @override
  State<ScanPreviewScreen> createState() => _ScanPreviewScreenState();
}

class _ScanPreviewScreenState extends State<ScanPreviewScreen> {
  bool _isProcessing = false;
  String? _errorMessage;

  Future<void> _extractText() async {
    if (widget.imageFile == null) return;

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final ocrService = OCRService();

      // ⚠️ IMPORTANT: If your OCRService requires a File (like ML Kit),
      // we must convert the XFile back to a File for the OCR process.
      final File fileForOcr = File(widget.imageFile!.path);

      final extractedText = await ocrService.extractText(fileForOcr);
      ocrService.dispose();

      if (mounted) {
        context.push(
          AppRoutes.scannerExtract,
          extra: {
            'imageFile': widget.imageFile, // Pass the XFile forward
            'extractedText': extractedText,
          },
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (widget.imageFile == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: const Text(
            'Preview',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.image_not_supported_outlined,
                  size: 64,
                  color: colors.outline,
                ),
                const SizedBox(height: 16),
                Text(
                  'No image provided',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please capture or pick an image first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.outline),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.scanner),
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text('Go to Scanner'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(200, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Scan Preview',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton.filledTonal(
            onPressed: _isProcessing
                ? null
                : () => context.go(AppRoutes.scanner),
            icon: const Icon(Icons.arrow_back_rounded, size: 20),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Expanded(child: _buildPreview(colors)),
              const SizedBox(height: 20),
              _buildErrorBanner(colors),
              _buildActions(colors),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: colors.outline,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Tap "Extract Text" to run OCR on this image.',
                      style: TextStyle(color: colors.outline, fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- Preview
  Widget _buildPreview(ColorScheme colors) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withAlpha(20),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: colors.surfaceContainerHighest,
              // 👇 THE CRITICAL FIX: Use kIsWeb to display the image safely
              child: kIsWeb
                  ? Image.network(widget.imageFile!.path, fit: BoxFit.contain)
                  : Image.file(
                      File(widget.imageFile!.path),
                      fit: BoxFit.contain,
                    ),
            ),

            // Scan-frame corners
            IgnorePointer(
              child: CustomPaint(
                painter: _ScanCornersPainter(
                  color: colors.primary.withAlpha(170),
                ),
              ),
            ),

            // Processing overlay
            if (_isProcessing)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(140),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          height: 44,
                          width: 44,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Extracting text…',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------ Error banner
  Widget _buildErrorBanner(ColorScheme colors) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: _errorMessage == null
          ? const SizedBox.shrink()
          : Container(
              key: const ValueKey('error-banner'),
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    color: colors.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: colors.onErrorContainer,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ---------------------------------------------------------------- Actions
  Widget _buildActions(ColorScheme colors) {
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => context.go(AppRoutes.scanner),
            icon: const Icon(Icons.camera_alt_rounded, size: 20),
            label: const Text('Retake'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: buttonShape,
              side: BorderSide(color: colors.outlineVariant),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: _isProcessing ? null : _extractText,
            icon: _isProcessing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.text_snippet_rounded, size: 20),
            label: const Text('Extract Text'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(56),
              shape: buttonShape,
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------- Scan-frame painter
class _ScanCornersPainter extends CustomPainter {
  final Color color;
  _ScanCornersPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const len = 26.0;
    const inset = 14.0;
    final w = size.width;
    final h = size.height;

    // top-left
    canvas.drawPath(
      Path()
        ..moveTo(inset, inset + len)
        ..lineTo(inset, inset)
        ..lineTo(inset + len, inset),
      paint,
    );
    // top-right
    canvas.drawPath(
      Path()
        ..moveTo(w - inset - len, inset)
        ..lineTo(w - inset, inset)
        ..lineTo(w - inset, inset + len),
      paint,
    );
    // bottom-left
    canvas.drawPath(
      Path()
        ..moveTo(inset, h - inset - len)
        ..lineTo(inset, h - inset)
        ..lineTo(inset + len, h - inset),
      paint,
    );
    // bottom-right
    canvas.drawPath(
      Path()
        ..moveTo(w - inset - len, h - inset)
        ..lineTo(w - inset, h - inset)
        ..lineTo(w - inset, h - inset - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanCornersPainter oldDelegate) =>
      oldDelegate.color != color;
}
