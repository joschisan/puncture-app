import 'package:flutter/material.dart';
import '../widgets/qr_code_with_copy.dart';
import '../widgets/navigation_button.dart';
import '../bridge_generated.dart/lib.dart';
import 'create_invoice_screen.dart';

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
            (_) => CreateInvoiceScreen(punctureConnection: punctureConnection),
      ),
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
