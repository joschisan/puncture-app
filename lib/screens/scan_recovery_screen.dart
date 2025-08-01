import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/fp_utils.dart';
import '../utils/notification_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/async_action_button.dart';

Widget _buildQrScanner(
  MobileScannerController controller,
  void Function(BarcodeCapture) onDetect,
) => Padding(
  padding: const EdgeInsets.all(16.0),
  child: LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.maxWidth;
      return SizedBox(
        width: size,
        height: size,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: MobileScanner(controller: controller, onDetect: onDetect),
        ),
      );
    },
  ),
);

TaskEither<String, String> _getClipboardText() {
  return TaskEither.tryCatch(
    () => Clipboard.getData(Clipboard.kTextPlain),
    (error, stackTrace) => 'Clipboard access error: $error',
  ).flatMap(
    (clipboardData) => TaskEither.fromOption(
      Option.fromNullable(
        clipboardData?.text,
      ).filter((text) => text.isNotEmpty),
      () => 'Clipboard is empty',
    ),
  );
}

Widget _buildPasteButton(VoidCallback? onPaste) => ElevatedButton.icon(
  onPressed: onPaste,
  icon: const Icon(Icons.paste, size: 24),
  label: const Text('Paste from Clipboard'),
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

class ScanRecoveryScreen extends StatefulWidget {
  final PunctureConnectionWrapper punctureConnection;

  const ScanRecoveryScreen({super.key, required this.punctureConnection});

  @override
  State<ScanRecoveryScreen> createState() => _ScanRecoveryScreenState();
}

class _ScanRecoveryScreenState extends State<ScanRecoveryScreen> {
  final _controller = MobileScannerController();
  bool _isScanning = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    if (!mounted) return;

    if (capture.barcodes.isEmpty) return;

    if (capture.barcodes.first.rawValue == null) return;

    _processInput(capture.barcodes.first.rawValue!);
  }

  void _processInput(String recovery) {
    try {
      final recoveryCode = decodeRecovery(recovery: recovery);

      setState(() {
        _isScanning = false;
      });

      _showRecoveryDrawer(recoveryCode);

      return;
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showRecoveryDrawer(RecoveryCodeWrapper recoveryCode) {
    showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.deepPurple.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.lock_open,
                          color: Colors.deepPurple,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Recovery Code',
                        style: TextStyle(fontSize: 18),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AsyncActionButton(
                    text: 'Recover',
                    onPressed: () => _handleRecoveryConfirm(recoveryCode),
                  ),
                ],
              ),
            ),
          ),
    ).then((shouldResume) {
      // Treat null (user dismissed) as true (resume scanning)
      if (shouldResume != false) {
        _resumeScanning();
      }
    });
  }

  TaskEither<String, void> _handleRecoveryConfirm(
    RecoveryCodeWrapper recoveryCode,
  ) {
    return safeTask(
      () => widget.punctureConnection.recover(recoveryCode: recoveryCode),
    ).map((recoveredAmount) {
      if (!mounted) return;

      Navigator.pop(context, false); // Close drawer, don't resume scanning

      Navigator.pop(context); // Go back to recovery screen

      Navigator.pop(context); // Go back to home screen
    });
  }

  void _resumeScanning() {
    setState(() {
      _isScanning = true;
    });
  }

  void _showError(String message) {
    NotificationUtils.showError(message);
  }

  Future<void> _handleClipboardPaste() async {
    (await _getClipboardText().run()).fold(_showError, _processInput);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildQrScanner(_controller, _onDetect),

            _buildPasteButton(_handleClipboardPaste),
          ],
        ),
      ),
    ),
  );
}
