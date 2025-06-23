import 'package:flutter/material.dart';
import '../widgets/qr_code_with_copy.dart';

// Pure UI composition
Widget _buildInvoiceContent(BuildContext context, String invoice, int amount) =>
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.deepPurple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.arrow_downward,
                color: Colors.deepPurple,
                size: 32,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$amount sats',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        QrCodeWithCopy(
          data: invoice,
          copyMessage: 'Invoice copied to clipboard',
        ),
        const Spacer(),
      ],
    );

class DisplayInvoiceScreen extends StatelessWidget {
  final String invoice;
  final int amount;

  const DisplayInvoiceScreen._({
    super.key,
    required this.invoice,
    required this.amount,
  });

  // Factory constructor for backward compatibility
  factory DisplayInvoiceScreen({
    Key? key,
    required String invoice,
    required int amount,
    required String description,
  }) => DisplayInvoiceScreen._(key: key, invoice: invoice, amount: amount);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox.expand(
          child: _buildInvoiceContent(context, invoice, amount),
        ),
      ),
    ),
  );
}
