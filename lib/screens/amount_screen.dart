import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import 'package:intl/intl.dart';
import '../utils/fp_utils.dart';
import '../bridge_generated.dart/lib.dart';
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
  String _currentAmount = '';

  void _onKeyboardTap(String value) {
    if (_currentAmount.length >= 8) return;

    setState(() {
      _currentAmount += value;
    });
  }

  void _onBackspace() {
    if (_currentAmount.isNotEmpty) {
      setState(() {
        _currentAmount = _currentAmount.substring(0, _currentAmount.length - 1);
      });
    }
  }

  void _onClear() {
    setState(() {
      _currentAmount = '';
    });
  }

  String get _formattedAmount {
    if (_currentAmount.isEmpty) return '0';
    final amount = int.tryParse(_currentAmount) ?? 0;
    return NumberFormat('#,###').format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('')),
      body: SafeArea(
        child: Column(
          children: [
            // Amount display - fills remaining space above continue button
            Expanded(
              child: Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: _formattedAmount,
                        style: const TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const TextSpan(
                        text: ' sats',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Continue button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: AsyncActionButton(
                text: 'Continue',
                onPressed: _sendPayment,
              ),
            ),

            // Custom number pad - explicit buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio:
                    2.0, // Makes buttons less tall (wider than tall)
                children: [
                  _buildNumberButton('1'),
                  _buildNumberButton('2'),
                  _buildNumberButton('3'),
                  _buildNumberButton('4'),
                  _buildNumberButton('5'),
                  _buildNumberButton('6'),
                  _buildNumberButton('7'),
                  _buildNumberButton('8'),
                  _buildNumberButton('9'),
                  _buildActionButton(Icons.clear, _onClear),
                  _buildNumberButton('0'),
                  _buildActionButton(Icons.backspace_outlined, _onBackspace),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _onKeyboardTap(number),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Center(child: Icon(icon, size: 28, color: Colors.white)),
      ),
    );
  }

  TaskEither<String, void> _sendPayment() {
    if (_currentAmount.isEmpty) {
      return TaskEither.left('Please enter an amount');
    }

    final amountMsat = BigInt.from(int.parse(_currentAmount) * 1000);

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
