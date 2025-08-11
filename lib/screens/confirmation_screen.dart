import 'package:flutter/material.dart';
import '../widgets/async_action_button.dart';
import '../widgets/amount_display.dart';
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

Widget _buildPaymentDetails(String description) {
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(children: [_buildDetailRow('Description:', description)]),
    ),
  );
}

class ConfirmationScreen extends StatelessWidget {
  final PaymentRequestWithAmountWrapper paymentRequest;
  final PunctureConnectionWrapper punctureConnection;

  const ConfirmationScreen({
    super.key,
    required this.paymentRequest,
    required this.punctureConnection,
  });

  int get _amountSats =>
      (paymentRequest.amountMsat().toDouble() / 1000).round();

  TaskEither<String, void> _payInvoice(BuildContext context) {
    return safeTask(() => punctureConnection.send(request: paymentRequest)).map(
      (_) {
        if (!context.mounted) return;

        Navigator.of(context).popUntil(
          (route) => route.settings.name == 'HomeScreen' || route.isFirst,
        ); // Pop back to HomeScreen or base screen if HomeScreen not found
      },
    );
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
                    _buildPaymentIcon(),
                    const SizedBox(height: 24),
                    AmountDisplay(_amountSats),
                    const SizedBox(height: 24),
                    if (paymentRequest.description().isNotEmpty)
                      _buildPaymentDetails(paymentRequest.description()),
                  ],
                ),
              ),
              AsyncActionButton(
                text: 'Confirm',
                onPressed: () => _payInvoice(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
