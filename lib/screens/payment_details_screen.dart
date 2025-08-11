import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/payment.dart';
import '../widgets/amount_display.dart';

// Pure UI building functions
Widget _buildPaymentIcon(Payment payment) => Container(
  width: 60,
  height: 60,
  decoration: BoxDecoration(
    color: Colors.deepPurple.withValues(alpha: 0.1),
    borderRadius: BorderRadius.circular(30),
  ),
  child: Icon(
    payment.isIncoming ? Icons.arrow_downward : Icons.arrow_upward,
    size: 40,
    color: Colors.deepPurple,
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

Widget _buildPaymentDetails(Payment payment) {
  final details = <Widget>[];

  // Fee in satoshis
  details.add(_buildDetailRow('Fee:', '${payment.feeSats} sats'));

  // Description
  if (payment.displayDescription.isNotEmpty) {
    if (payment.lightningAddress.isNone()) {
      details.add(_buildDetailRow('Description:', payment.displayDescription));
    }
  }

  // Status
  details.add(_buildDetailRow('Status:', payment.displayStatus));

  // Lightning address (if available)
  payment.lightningAddress.fold(
    () => null,
    (address) => details.add(_buildDetailRow('Address:', address)),
  );

  // Created timestamp
  details.add(_buildDetailRow('Created:', _formatDateTime(payment.createdAt)));

  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children:
            details
                .expand((widget) => [widget, const SizedBox(height: 16)])
                .take(details.length * 2 - 1) // Remove last SizedBox
                .toList(),
      ),
    ),
  );
}

String _formatDateTime(DateTime dateTime) {
  return DateFormat('MMM d, y \'at\' h:mm a').format(dateTime);
}

class PaymentDetailsScreen extends StatelessWidget {
  final Payment payment;

  const PaymentDetailsScreen({super.key, required this.payment});

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
                    _buildPaymentIcon(payment),
                    const SizedBox(height: 24),
                    AmountDisplay(payment.amountSats),
                    const SizedBox(height: 24),
                    _buildPaymentDetails(payment),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
