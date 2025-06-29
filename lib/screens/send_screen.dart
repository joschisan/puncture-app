import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/ln_address.dart';
import '../utils/lnurl_utils.dart';
import '../utils/fp_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/navigation_button.dart';
import '../widgets/async_action_button.dart';
import '../utils/notification_utils.dart';
import 'ln_address_screen.dart';
import 'pay_invoice_screen.dart';
import 'ln_amount_screen.dart';

// Send screen state types
enum InputType { lightningAddress, lightningInvoice }

// Result type using Either pattern
typedef SendResult = Either<String, void>;

// Pure input type detection
Option<Either<LightningAddress, String>> detectInputType(String input) {
  // Handle lightning: prefix
  if (input.startsWith('lightning:')) {
    return detectInputType(input.substring(10));
  }

  // Lightning Invoice
  if (input.startsWith('lnbc')) {
    return some(right(input));
  }

  // Lightning Address - use our centralized validation
  return LightningAddress.create(input).fold(
    (_) => none<Either<LightningAddress, String>>(), // Invalid format
    (lightningAddress) => some(
      left(lightningAddress),
    ), // Valid Lightning Address - put on Left side
  );
}

// Pure UI building functions
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

class SendScreen extends StatefulWidget {
  final PunctureConnectionWrapper punctureConnection;
  final List<String> lightningAddresses;

  const SendScreen({
    super.key,
    required this.punctureConnection,
    required this.lightningAddresses,
  });

  @override
  State<SendScreen> createState() => _SendScreenState();
}

class _SendScreenState extends State<SendScreen> {
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

  void _processInput(String input) {
    detectInputType(input.toLowerCase().trim()).fold(
      () => _showError('Invalid Lightning address or invoice format'),
      (detectedData) {
        _controller.pause();
        _showDetectionDrawer(detectedData);
      },
    );
  }

  void _showDetectionDrawer(Either<LightningAddress, String> detectedData) {
    showModalBottomSheet<void>(
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
                top: Radius.circular(20),
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
                      backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
                      child: Icon(
                        detectedData.fold(
                          (_) => Icons.alternate_email,
                          (_) => Icons.bolt,
                        ),
                        color: Colors.deepPurple,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      detectedData.fold(
                        (lightningAddress) => lightningAddress.fullAddress,
                        (_) => 'Invoice Detected',
                      ),
                      style: const TextStyle(fontSize: 18),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),
                AsyncActionButton(
                  text: 'Continue',
                  onPressed: () => _handleDetectionConfirm(detectedData),
                ),
              ],
            ),
          ),
    ).then((_) => _resumeScanning());
  }

  TaskEither<String, void> _handleDetectionConfirm(
    Either<LightningAddress, String> detectedData,
  ) {
    return detectedData.fold(
      (lightningAddress) => _processLightningAddress(lightningAddress),
      (invoice) => _processLightningInvoice(invoice),
    );
  }

  TaskEither<String, void> _processLightningAddress(
    LightningAddress lightningAddress,
  ) {
    return getLnurlPayInfo(lightningAddress).map((payInfo) {
      if (mounted) {
        Navigator.pop(context); // Close drawer
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => LightningAmountScreen(
                  lightningAddress: lightningAddress,
                  payInfo: payInfo,
                  punctureConnection: widget.punctureConnection,
                ),
          ),
        );
      }
    });
  }

  TaskEither<String, void> _processLightningInvoice(String invoice) {
    return safeTask(
      () => widget.punctureConnection.bolt11Quote(invoice: invoice),
    ).map((quoteResponse) {
      if (mounted) {
        Navigator.pop(context); // Close drawer
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => PayInvoiceScreen(
                  quoteResponse: quoteResponse,
                  displayDescription: true,
                  rawInvoice: invoice,
                  punctureConnection: widget.punctureConnection,
                  lightningAddress: none<String>(),
                ),
          ),
        );
      }
    });
  }

  void _resumeScanning() {
    _controller.start();
  }

  void _showError(String message) {
    NotificationUtils.showError(message);
  }

  void _showLightningAddressScreen() async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (context) => LightningAddressScreen(
              punctureConnection: widget.punctureConnection,
              availableAddresses: widget.lightningAddresses,
            ),
      ),
    );
  }

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

  Future<void> _handleClipboardPaste() async {
    (await _getClipboardText().run()).fold(_showError, _processInput);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
    ),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildQrScanner(_controller, _onDetect),

            _buildPasteButton(_handleClipboardPaste),

            const Spacer(),

            NavigationButton(
              text: 'Send to Lightning Address',
              onPressed: _showLightningAddressScreen,
            ),
          ],
        ),
      ),
    ),
  );
}
