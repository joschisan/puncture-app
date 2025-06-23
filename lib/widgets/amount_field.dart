import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountField extends StatefulWidget {
  final TextEditingController controller;
  final int minAmount;
  final int maxAmount;
  final String? Function(String?)? validator;
  final bool autofocus;
  final String? labelText;
  final String? hintText;

  const AmountField({
    super.key,
    required this.controller,
    required this.minAmount,
    required this.maxAmount,
    this.validator,
    this.autofocus = false,
    this.labelText,
    this.hintText,
  });

  @override
  State<AmountField> createState() => _AmountFieldState();
}

class _AmountFieldState extends State<AmountField> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      decoration: InputDecoration(
        labelText: widget.labelText ?? 'Amount (sats)',
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.bolt),
        border: const OutlineInputBorder(),
        helperText: _buildHelperText(),
      ),
      keyboardType: TextInputType.number,
      autofocus: widget.autofocus,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: widget.validator ?? _defaultValidator,
    );
  }

  String? _buildHelperText() {
    return 'Min: ${widget.minAmount} sats - Max: ${widget.maxAmount} sats';
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    final amount = int.tryParse(value);
    if (amount == null || amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount < widget.minAmount) {
      return 'Amount must be at least ${widget.minAmount} sats';
    }
    if (amount > widget.maxAmount) {
      return 'Amount must be at most ${widget.maxAmount} sats';
    }
    return null;
  }
}
