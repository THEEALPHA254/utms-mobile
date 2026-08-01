// ─────────────────────────────────────────────────────────────────────────────//
// The other side of the booking flow: students carry a QR code in the app;
// drivers scan it here to mark them boarded.
//
// KEY CONCEPTS:
//   • `mobile_scanner` is a pub.dev package that wraps the platform camera
//     APIs and reports decoded barcodes via `onDetect`.
//   • `DetectionSpeed.noDuplicates` — the scanner ignores the same barcode
//     if it hasn't changed frame-to-frame (prevents accidental multi-scans).
//   • `_processing` flag debounces the scan: once we start verifying a QR
//     we ignore further detections until we've shown the result + reset.
//   • `Stack` overlays the camera view, the scan frame outline, and the
//     result banner on top of each other.
//   • `_controller.dispose()` is critical — leaving the camera hot burns
//     battery and can block other apps from using it.
// ─────────────────────────────────────────────────────────────────────────────
// DRIVER QR SCANNER


import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';

/// Driver scans student's QR code to verify boarding.
class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  bool _processing = false;
  String? _resultMessage;
  bool _success = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Fired by the camera every time a barcode is detected. We debounce with
  // `_processing` so a single scan isn't submitted multiple times.
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    // Grab the raw string payload from the first detected barcode.
    final qr = capture.barcodes.firstOrNull?.rawValue;
    if (qr == null || qr.isEmpty) return;

    setState(() => _processing = true);
    // Stop the camera stream while we verify — avoids overlapping detections.
    await _controller.stop();

    try {
      // Send the QR payload to the backend. On success, the backend flips
      // the booking's `boarded` field and returns the student's name.
      final res = await apiService.verifyBoarding(qr);
      final studentName = res['student'] as String? ?? 'Student';
      setState(() {
        _success = true;
        _resultMessage = '✓ Boarded: $studentName';
      });
    } catch (e) {
      final msg = e.toString().contains('Invalid')
          ? 'Invalid or already used QR code.'
          : 'Verification failed. Try again.';
      setState(() {
        _success = false;
        _resultMessage = msg;
      });
    }

    // Show result for 2.5 seconds, then reset scanner
    await Future.delayed(const Duration(milliseconds: 2500));
    if (mounted) {
      setState(() {
        _processing = false;
        _resultMessage = null;
      });
      await _controller.start();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Scan Student QR', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => _controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Scan overlay frame
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _resultMessage == null
                      ? Colors.white
                      : (_success ? Colors.green : Colors.red),
                  width: 3,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: _processing && _resultMessage != null
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _success
                              ? Colors.green.withOpacity(0.9)
                              : Colors.red.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _success ? Icons.check_circle : Icons.cancel,
                              color: Colors.white,
                              size: 48,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _resultMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
          ),

          // Instruction label
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _processing
                      ? 'Processing...'
                      : 'Point camera at student\'s QR code',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
