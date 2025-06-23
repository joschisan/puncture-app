import 'package:flutter/material.dart';

class LightningAddressField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool autofocus;

  const LightningAddressField({
    super.key,
    required this.controller,
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Lightning Address',
        hintText: 'username@domain.com',
        prefixIcon: Icon(Icons.alternate_email),
        border: OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
      autofocus: autofocus,
    );
  }
}
