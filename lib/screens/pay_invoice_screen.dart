import 'package:flutter/material.dart';
import '../widgets/async_action_button.dart';
import '../utils/fp_utils.dart';
import '../bridge_generated.dart/lib.dart';
import 'package:fpdart/fpdart.dart' hide State;

// Pure UI building functions
Widget _buildPaymentIcon() => Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    color: Colors.deepPurple.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(30),
  ),
  child: const Icon(Icons.arrow_upward, size: 40, color: Colors.deepPurple),
);

Widget _buildLightningAddressDisplay(Option<String> lightningAddress) {
  return lightningAddress.fold(
    () => const SizedBox.shrink(), // None case - show nothing
    (address) => Column(
      children: [
        Text(
          address,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
      ],
    ),
  );
}

Widget _buildAmountDisplay(String amountText) => Text(
  amountText,
  style: const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
);

Widget _buildDetailRow(String label, String value) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    ),
    Flexible(
      child: Text(
        value,
        style: const TextStyle(fontSize: 16),
        textAlign: TextAlign.right,
      ),
    ),
  ],
);

Widget _buildInvoiceDetails(
  BuildContext context,
  QuoteResponse quoteResponse,
  bool displayDescription,
) {
  final feeSats = (quoteResponse.feeMsat.toInt() / 1000).round();
  final expirySecs = quoteResponse.expirySecs.toInt();

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        _buildDetailRow('Fee:', '$feeSats sats'),
        const SizedBox(height: 16),
        if (displayDescription && quoteResponse.description.isNotEmpty) ...[
          _buildDetailRow('Description:', quoteResponse.description),
          const SizedBox(height: 16),
        ],
        _buildDetailRow('Expires in:', '${expirySecs}s'),
      ],
    ),
  );
}

class PayInvoiceScreen extends StatelessWidget {
  final QuoteResponse quoteResponse;
  final bool displayDescription;
  final String rawInvoice;
  final PunctureConnectionWrapper punctureConnection;
  final Option<String> lightningAddress;

  const PayInvoiceScreen({
    super.key,
    required this.quoteResponse,
    required this.displayDescription,
    required this.rawInvoice,
    required this.punctureConnection,
    this.lightningAddress = const None(),
  });

  int get _amountSats => (quoteResponse.amountMsat.toInt() / 1000).round();

  String get _formattedAmount => '$_amountSats sats';

  TaskEither<String, void> _payInvoice(BuildContext context) {
    return safeTask(
      () => punctureConnection.bolt11Send(
        invoice: rawInvoice,
        lnAddress: lightningAddress.fold(() => null, (addr) => addr),
      ),
    ).map((_) {
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => 
          route.settings.name == 'HomeScreen' || route.isFirst
        ); // Pop back to HomeScreen or base screen if HomeScreen not found
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildLightningAddressDisplay(lightningAddress),
                    _buildPaymentIcon(),
                    const SizedBox(height: 24),
                    _buildAmountDisplay(_formattedAmount),
                    const SizedBox(height: 24),
                    _buildInvoiceDetails(
                      context,
                      quoteResponse,
                      displayDescription,
                    ),
                  ],
                ),
              ),
              AsyncActionButton(
                text: 'Pay Invoice',
                onPressed: () => _payInvoice(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
