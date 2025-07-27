import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../widgets/qr_code_with_copy.dart';
import '../widgets/navigation_button.dart';
import '../bridge_generated.dart/lib.dart';
import '../utils/fp_utils.dart';
import 'amount_screen.dart';
import 'display_invoice_screen.dart';

class ReceiveScreen extends StatelessWidget {
  final String offer;
  final PunctureConnectionWrapper punctureConnection;

  const ReceiveScreen({
    super.key,
    required this.offer,
    required this.punctureConnection,
  });

  void _navigateToCreateInvoice(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => AmountScreen(
              onAmountSubmitted: _handleInvoiceGeneration,
              punctureConnection: punctureConnection,
            ),
      ),
    );
  }

  TaskEither<String, void> _handleInvoiceGeneration(
    int amountSats,
    BuildContext navigationContext,
    PunctureConnectionWrapper connection,
  ) {
    final amountMsat = amountSats * 1000;

    return safeTask(
      () => connection.bolt11Receive(
        amountMsat: amountMsat,
        description: '', // Empty description for now
      ),
    ).map((invoice) {
      if (!navigationContext.mounted) return;

      // Navigate to display screen using the provided context
      Navigator.of(navigationContext).pushReplacement(
        MaterialPageRoute(
          builder:
              (_) => DisplayInvoiceScreen(
                invoice: invoice,
                amount: amountSats,
                description: '',
              ),
        ),
      );
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
                child: Center(
                  child: QrCodeWithCopy(
                    data: offer,
                    copyMessage: 'Offer copied to clipboard',
                  ),
                ),
              ),
              NavigationButton(
                text: 'Create Invoice',
                onPressed: () => _navigateToCreateInvoice(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
