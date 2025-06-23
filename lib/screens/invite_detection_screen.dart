import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../utils/fp_utils.dart';
import '../utils/notification_utils.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/async_action_button.dart';
import 'home_screen.dart';

class InviteDetectionScreen extends StatefulWidget {
  final String invite;
  final PunctureClientWrapper punctureClient;
  final VoidCallback onInviteAdded;

  const InviteDetectionScreen({
    super.key,
    required this.invite,
    required this.punctureClient,
    required this.onInviteAdded,
  });

  @override
  State<InviteDetectionScreen> createState() => _InviteDetectionScreenState();
}

class _InviteDetectionScreenState extends State<InviteDetectionScreen> {
  Widget _buildDetectionIcon() => Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      color: Colors.deepPurple.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(40),
    ),
    child: const Icon(Icons.link, size: 40, color: Colors.deepPurple),
  );

  TaskEither<String, void> _handleContinue() {
    return safeTask(
      () => widget.punctureClient.addInstance(invite: widget.invite),
    ).map((connection) {
      // Notify BaseScreen to refresh its instances list
      widget.onInviteAdded();

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            settings: const RouteSettings(name: 'HomeScreen'),
            builder:
                (_) => HomeScreen(
                  punctureConnection: connection,
                  inviteString: widget.invite,
                ),
          ),
        );
      }
    });
  }

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
                    _buildDetectionIcon(),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.invite,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              AsyncActionButton(text: 'Continue', onPressed: _handleContinue),
            ],
          ),
        ),
      ),
    );
  }
}
