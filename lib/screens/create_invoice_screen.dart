import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/fp_utils.dart';
import '../widgets/amount_field.dart';
import '../widgets/async_action_button.dart';
import '../bridge_generated.dart/lib.dart';
import 'display_invoice_screen.dart';

class CreateInvoiceScreen extends StatefulWidget {
  final PunctureConnectionWrapper punctureConnection;

  const CreateInvoiceScreen({super.key, required this.punctureConnection});

  @override
  State<CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<CreateInvoiceScreen> {
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _navigateToDisplay(String invoice, int amount, String description) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder:
            (_) => DisplayInvoiceScreen(
              invoice: invoice,
              amount: amount,
              description: description,
            ),
      ),
    );
  }

  TaskEither<String, void> _handleGenerateInvoice() {
    final amount = int.parse(_amountController.text);
    final description = _descriptionController.text;

    return safeTask(
      () => widget.punctureConnection.bolt11Receive(
        amountMsat: amount * 1000,
        description: description,
      ),
    ).map((invoice) => _navigateToDisplay(invoice, amount, description));
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AmountField(controller: _amountController, autofocus: true),
        const SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: const InputDecoration(
            labelText: 'Description (optional)',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
            counterText: '',
            helperText: 'Max 50 characters',
          ),
          minLines: 1,
          maxLines: 3,
          maxLength: 50,
        ),
        const Spacer(),
        _buildGenerateButton(),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return AsyncActionButton(
      text: 'Generate Invoice',
      onPressed: _handleGenerateInvoice,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildForm(),
        ),
      ),
    );
  }
}
