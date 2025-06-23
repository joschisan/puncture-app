import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../models/lnurl_pay_info.dart';
import '../utils/lnurl_utils.dart' show getLnurlPayInvoice;
import '../utils/ln_address.dart';
import '../utils/fp_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/amount_field.dart';
import '../widgets/async_action_button.dart';
import 'pay_invoice_screen.dart';

class LightningAmountScreen extends StatefulWidget {
  final LightningAddress lightningAddress;
  final LnurlPayInfo payInfo;
  final PunctureConnectionWrapper punctureConnection;

  const LightningAmountScreen({
    super.key,
    required this.lightningAddress,
    required this.payInfo,
    required this.punctureConnection,
  });

  @override
  State<LightningAmountScreen> createState() => _LightningAmountScreenState();
}

class _LightningAmountScreenState extends State<LightningAmountScreen> {
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send, color: Colors.deepPurple),
                  const SizedBox(width: 8),
                  Text(
                    widget.lightningAddress.fullAddress,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              AmountField(
                controller: _amountController,
                minAmount: widget.payInfo.minSendableSats,
                maxAmount: widget.payInfo.maxSendableSats,
                autofocus: true,
              ),

              const Spacer(),

              AsyncActionButton(
                text: 'Generate Invoice',
                onPressed: _sendPayment,
              ),
            ],
          ),
        ),
      ),
    );
  }

  TaskEither<String, void> _sendPayment() {
    final amountMsat = _calculateAmountMsat();

    // Chain the operations using flatMap for clean composition
    return getLnurlPayInvoice(widget.payInfo.callbackUrl, amountMsat).flatMap(
      (invoice) => safeTask(
        () => widget.punctureConnection.bolt11Quote(invoice: invoice),
      ).map((quoteResponse) {
        // Navigate to payment screen if mounted
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder:
                  (context) => PayInvoiceScreen(
                    quoteResponse: quoteResponse,
                    displayDescription: false,
                    rawInvoice: invoice,
                    punctureConnection: widget.punctureConnection,
                    lightningAddress: some(widget.lightningAddress.fullAddress),
                  ),
            ),
          );
        }
      }),
    );
  }

  int _calculateAmountMsat() {
    final amount = int.parse(_amountController.text);
    return amount * 1000;
  }
}
