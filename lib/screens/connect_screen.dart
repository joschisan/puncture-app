import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/fp_utils.dart';
import '../utils/notification_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/async_action_button.dart';
import 'home_screen.dart';

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

class ConnectScreen extends StatefulWidget {
  final PunctureClientWrapper punctureClient;
  final VoidCallback onDaemonAdded;

  const ConnectScreen({
    super.key,
    required this.punctureClient,
    required this.onDaemonAdded,
  });

  @override
  State<ConnectScreen> createState() => _ConnectScreenState();
}

class _ConnectScreenState extends State<ConnectScreen> {
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

  void _processInput(String invite) {
    setState(() {
      _isScanning = false;
    });

    _showInviteDrawer(invite);
  }

  void _showInviteDrawer(String invite) {
    showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => SafeArea(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
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
                          Icons.link,
                          color: Colors.deepPurple,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Invite Detected',
                        style: TextStyle(fontSize: 18),
                      ),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AsyncActionButton(
                    text: 'Continue',
                    onPressed: () => _handleInviteConfirm(invite),
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

  TaskEither<String, void> _handleInviteConfirm(String invite) {
    return safeTask(() => widget.punctureClient.register(invite: invite)).map((
      connection,
    ) {
      // Notify BaseScreen to refresh its daemons list
      widget.onDaemonAdded();

      if (!mounted) return;

      Navigator.pop(context, false); // Close drawer, don't resume scanning

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          settings: const RouteSettings(name: 'HomeScreen'),
          builder: (_) => HomeScreen(punctureConnection: connection),
        ),
      );
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
