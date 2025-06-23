import 'package:flutter/material.dart';
import '../widgets/qr_code_with_copy.dart';

// Pure UI composition for invite display
Widget _buildInviteContent(BuildContext context, String invite) => Column(
  mainAxisAlignment: MainAxisAlignment.center,
  crossAxisAlignment: CrossAxisAlignment.center,
  children: [
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.deepPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.link, color: Colors.deepPurple, size: 32),
        ),
        const SizedBox(width: 8),
        const Text(
          'Invite Code',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ],
    ),
    QrCodeWithCopy(
      data: invite,
      copyMessage: 'Invite code copied to clipboard',
    ),
    const Spacer(),
  ],
);

class DisplayInviteScreen extends StatelessWidget {
  final String invite;

  const DisplayInviteScreen({super.key, required this.invite});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox.expand(child: _buildInviteContent(context, invite)),
      ),
    ),
  );
}
