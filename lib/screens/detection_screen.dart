import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/lnurl_utils.dart';
import '../utils/ln_address.dart';
import '../utils/fp_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/async_action_button.dart';
import 'pay_invoice_screen.dart';
import 'ln_amount_screen.dart';

class DetectionScreen extends StatefulWidget {
  final Either<LightningAddress, String>
  detectedData; // Left = lightning address, Right = invoice

  const DetectionScreen({
    super.key,
    required this.detectedData,
    required this.punctureConnection,
  });

  final PunctureConnectionWrapper punctureConnection;

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  Widget _buildDetectionIcon() => Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: Colors.deepPurple.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(40),
    ),
    child: widget.detectedData.fold(
      (lightningAddress) =>
          const Icon(Icons.alternate_email, size: 40, color: Colors.deepPurple),
      (invoice) => const Icon(Icons.bolt, size: 40, color: Colors.deepPurple),
    ),
  );

  TaskEither<String, void> _handleContinue() {
    return widget.detectedData.fold(
      (lightningAddress) => _processLightningAddress(lightningAddress),
      (invoice) => _processLightningInvoice(invoice),
    );
  }

  TaskEither<String, void> _processLightningAddress(
    LightningAddress lightningAddress,
  ) {
    return getLnurlPayInfo(lightningAddress).map((payInfo) {
      if (mounted) {
        Navigator.of(context).push(
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
        Navigator.of(context).push(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(''),
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
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDetectionIcon(),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.detectedData.fold(
                          (lightningAddress) => lightningAddress.fullAddress,
                          (invoice) => invoice,
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              AsyncActionButton(text: 'Continue', onPressed: _handleContinue),
            ],
          ),
        ),
      ),
    );
  }
}
