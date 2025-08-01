import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/fp_utils.dart';
import '../utils/notification_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/async_action_button.dart';
import '../screens/scan_recovery_screen.dart';

class RecoveryScreen extends StatefulWidget {
  final PunctureConnectionWrapper punctureConnection;

  const RecoveryScreen({super.key, required this.punctureConnection});

  @override
  State<RecoveryScreen> createState() => _RecoveryScreenState();
}

class _RecoveryScreenState extends State<RecoveryScreen> {
  final TextEditingController _recoveryNameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _recoveryNameController.dispose();
    super.dispose();
  }

  TaskEither<String, void> _handleSetRecoveryName() {
    return safeTask(
      () => widget.punctureConnection.setRecoveryName(
        name: _recoveryNameController.text.trim(),
      ),
    ).map((_) {
      NotificationUtils.showSuccess('Set Recovery Name');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => ScanRecoveryScreen(
                        punctureConnection: widget.punctureConnection,
                      ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _recoveryNameController,
                  decoration: const InputDecoration(
                    labelText: 'Recovery Name',
                    prefixIcon: Icon(Icons.account_circle),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.text,
                  autofocus: true,
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text(
                    'Enter a name to be displayed to the operator such that he can identify your account and facilitate the recovery of your funds in case you loose this device.',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.withValues(alpha: 0.8),
                      height: 1.4,
                    ),
                  ),
                ),

                const Spacer(),

                AsyncActionButton(
                  text: 'Confirm',
                  onPressed: _handleSetRecoveryName,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
