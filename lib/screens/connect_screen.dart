import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/fp_utils.dart';
import '../utils/notification_utils.dart';
import '../bridge_generated.dart/lib.dart';
import 'home_screen.dart';
import 'invite_detection_screen.dart';

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

Widget _buildPasteButton(VoidCallback? onPaste) => ElevatedButton.icon(
  onPressed: onPaste,
  icon: const Icon(Icons.paste, size: 24),
  label: const Text('Paste from Clipboard'),
  style: ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  ),
);

class ConnectScreen extends StatefulWidget {
  final PunctureClientWrapper punctureClient;
  final VoidCallback onInviteAdded;

  const ConnectScreen({
    super.key,
    required this.punctureClient,
    required this.onInviteAdded,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
  final MobileScannerController _controller = MobileScannerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (capture.barcodes.isEmpty) return;

    if (capture.barcodes.first.rawValue == null) return;

    _processInput(capture.barcodes.first.rawValue!);
  }

  void _processInput(String invite) {
    _controller.stop();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => InviteDetectionScreen(
              invite: invite,
              punctureClient: widget.punctureClient,
              onInviteAdded: widget.onInviteAdded,
            ),
      ),
    );
  }

  void _showError(String message) {
    NotificationUtils.showError(message);
  }

  Future<void> _handleClipboardPaste() async {
    final result =
        await TaskEither.tryCatch(
              () => Clipboard.getData(Clipboard.kTextPlain),
              (error, stackTrace) => 'Clipboard access error: $error',
            )
            .flatMap(
              (clipboardData) => TaskEither.fromOption(
                Option.fromNullable(
                  clipboardData?.text,
                ).filter((text) => text.isNotEmpty),
                () => 'Clipboard is empty',
              ),
            )
            .run();

    result.fold(_showError, _processInput);
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
