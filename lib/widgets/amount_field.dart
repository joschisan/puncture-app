import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AmountField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool autofocus;
  final String? labelText;
  final String? hintText;

  const AmountField({
    super.key,
    required this.controller,
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
        labelText: widget.labelText ?? 'Amount',
        hintText: widget.hintText,
        prefixIcon: const Icon(Icons.bolt),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.number,
      autofocus: widget.autofocus,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: widget.validator ?? _defaultValidator,
    );
  }

  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }

    final amount = int.tryParse(value);

    if (amount == null || amount <= 0) {
      return 'Amount must be greater than 0';
    }

    return null;
  }
}
