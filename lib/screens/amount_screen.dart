import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/fp_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/amount_field.dart';
import '../widgets/async_action_button.dart';
import 'confirmation_screen.dart';

class AmountScreen extends StatefulWidget {
  final PaymentRequestWithoutAmountWrapper paymentRequest;
  final PunctureConnectionWrapper punctureConnection;

  const AmountScreen({
    super.key,
    required this.paymentRequest,
    required this.punctureConnection,
  });

  @override
  State<AmountScreen> createState() => _AmountScreenState();
}

class _AmountScreenState extends State<AmountScreen> {
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AmountField(controller: _amountController, autofocus: true),
              const Spacer(),
              AsyncActionButton(text: 'Continue', onPressed: _sendPayment),
            ],
          ),
        ),
      ),
    );
  }

  TaskEither<String, void> _sendPayment() {
    if (_amountController.text.isEmpty) {
      return TaskEither.left('Please enter an amount');
    }

    final amountMsat = BigInt.from(int.parse(_amountController.text) * 1000);

    // Use the unified resolve function from Rust
    return safeTask(
      () => resolvePaymentRequest(
        request: widget.paymentRequest,
        amount: amountMsat,
      ),
    ).flatMap((paymentWithAmount) {
      return safeTask(
        () => widget.punctureConnection.quote(
          amountMsat: paymentWithAmount.amountMsat(),
        ),
      ).map((fee) {
        // Navigate to payment screen if mounted
        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => ConfirmationScreen(
                  paymentRequest: paymentWithAmount,
                  fee: fee.toInt(),
                  punctureConnection: widget.punctureConnection,
                ),
          ),
        );
      });
    });
  }
}
