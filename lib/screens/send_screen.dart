import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/fp_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/async_action_button.dart';
import '../utils/notification_utils.dart';
import 'confirmation_screen.dart';
import 'amount_screen.dart';
import '../widgets/navigation_button.dart';
import 'address_screen.dart';

// Result type using Either pattern
typedef SendResult = Either<String, void>;

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

  void _processInput(String input) {
    final paymentWithAmount = parseWithAmount(request: input);

    if (paymentWithAmount != null) {
      _showWithAmountDrawer(paymentWithAmount);

      return;
    }

    final paymentWithoutAmount = parseWithoutAmount(request: input);

    if (paymentWithoutAmount != null) {
      _showWithoutAmountDrawer(paymentWithoutAmount);

      return;
    }

    _showError('Unknown format');
  }

  void _showWithAmountDrawer(PaymentRequestWithAmountWrapper paymentRequest) {
    _showPaymentDrawer(
      displayText: paymentRequest.display(),
      onPressed: () => _handleWithAmountConfirm(paymentRequest),
    );
  }

  void _showWithoutAmountDrawer(
    PaymentRequestWithoutAmountWrapper paymentRequest,
  ) {
    _showPaymentDrawer(
      displayText: paymentRequest.display(),
      onPressed: () => _handleWithoutAmountConfirm(paymentRequest),
    );
  }

  void _showPaymentDrawer({
    required String displayText,
    required TaskEither<String, void> Function() onPressed,
  }) {
    setState(() {
      _isScanning = false;
    });

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
                top: Radius.circular(20),
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
                        child: Icon(
                          Icons.arrow_upward,
                          color: Colors.deepPurple,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          displayText,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AsyncActionButton(text: 'Continue', onPressed: onPressed),
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

  TaskEither<String, void> _handleWithAmountConfirm(
    PaymentRequestWithAmountWrapper paymentRequest,
  ) {
    if (!mounted) return TaskEither.right(());

    Navigator.pop(context, false); // Close drawer, don't resume scanning

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => ConfirmationScreen(
              paymentRequest: paymentRequest,
              punctureConnection: widget.punctureConnection,
            ),
      ),
    );

    return TaskEither.right(());
  }

  TaskEither<String, void> _handleWithoutAmountConfirm(
    PaymentRequestWithoutAmountWrapper paymentRequest,
  ) {
    if (!mounted) return TaskEither.right(());

    Navigator.pop(context, false); // Close drawer, don't resume scanning

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => AmountScreen(
              onAmountSubmitted:
                  (amountSats, ctx, conn) => _handlePaymentAmount(
                    paymentRequest,
                    amountSats,
                    ctx,
                    conn,
                  ),
              punctureConnection: widget.punctureConnection,
            ),
      ),
    );

    return TaskEither.right(());
  }

  TaskEither<String, void> _handlePaymentAmount(
    PaymentRequestWithoutAmountWrapper paymentRequest,
    int amountSats,
    BuildContext navigationContext,
    PunctureConnectionWrapper connection,
  ) {
    final amountMsat = BigInt.from(amountSats * 1000);

    // Use the unified resolve function from Rust
    return safeTask(
      () => resolvePaymentRequest(request: paymentRequest, amount: amountMsat),
    ).map((paymentWithAmount) {
      if (!navigationContext.mounted) return;

      // Navigate to payment screen using the provided context
      Navigator.of(navigationContext).push(
        MaterialPageRoute(
          builder:
              (context) => ConfirmationScreen(
                paymentRequest: paymentWithAmount,
                punctureConnection: connection,
              ),
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
    appBar: AppBar(),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildQrScanner(_controller, _onDetect),
            _buildPasteButton(_handleClipboardPaste),
            const Spacer(),
            NavigationButton(
              text: 'Enter Lightning Address',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => AddressScreen(
                          punctureConnection: widget.punctureConnection,
                          availableAddresses: widget.lightningAddresses,
                        ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ),
  );
}
