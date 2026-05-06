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

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final qr = capture.barcodes.firstOrNull?.rawValue;
    if (qr == null || qr.isEmpty) return;

    setState(() => _processing = true);
    await _controller.stop();

    try {
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
