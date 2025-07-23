import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/fp_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/async_action_button.dart';
import '../widgets/address_field.dart';
import 'amount_screen.dart';

class AddressScreen extends StatefulWidget {
  final PunctureConnectionWrapper punctureConnection;
  final List<String> availableAddresses;

  const AddressScreen({
    super.key,
    required this.punctureConnection,
    required this.availableAddresses,
  });

  @override
  State<AddressScreen> createState() => _AddressScreenState();
}

class _AddressScreenState extends State<AddressScreen> {
  final TextEditingController _addressController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<String> _filteredAddresses = [];

  @override
  void initState() {
    super.initState();
    _filteredAddresses = widget.availableAddresses;
    _addressController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      final query = _addressController.text.toLowerCase();

      _filteredAddresses =
          widget.availableAddresses
              .where((address) => address.toLowerCase().contains(query))
              .toList();
    });
  }

  void _selectAddress(String address) {
    _handleAddress(address);
  }

  TaskEither<String, void> _handleContinue() {
    if (_addressController.text.trim().isEmpty) {
      return TaskEither.left('Please enter an address');
    }

    return _handleAddress(_addressController.text.trim());
  }

  TaskEither<String, void> _handleAddress(String address) {
    return safe(() {
      final paymentRequest = parseWithoutAmount(request: address);

      if (paymentRequest == null) throw 'Invalid address format';

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (_) => AmountScreen(
                paymentRequest: paymentRequest,
                punctureConnection: widget.punctureConnection,
              ),
        ),
      );
    });
  }

  Widget _buildAddressCard(String address) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(8.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
          child: const Icon(
            Icons.alternate_email,
            color: Colors.deepPurple,
            size: 20,
          ),
        ),
        title: Text(
          address,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        onTap: () => _selectAddress(address),
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LightningAddressField(
                  controller: _addressController,
                  autofocus: true,
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: ListView.builder(
                    itemCount: _filteredAddresses.length,
                    itemBuilder: (context, index) {
                      return _buildAddressCard(_filteredAddresses[index]);
                    },
                  ),
                ),

                const SizedBox(height: 16),

                AsyncActionButton(text: 'Continue', onPressed: _handleContinue),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
