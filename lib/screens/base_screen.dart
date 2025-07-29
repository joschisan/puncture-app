import 'package:flutter/material.dart';
import '../bridge_generated.dart/lib.dart';
import '../widgets/navigation_button.dart';
import 'connect_screen.dart';
import 'home_screen.dart';

// Pure function for invite tile with same styling as payment tiles
Widget buildInviteTile(
  String invite,
  VoidCallback onTap, {
  VoidCallback? onLongPress,
}) => Card(
  margin: const EdgeInsets.symmetric(vertical: 4.0),
  child: ListTile(
    contentPadding: const EdgeInsets.all(8.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: CircleAvatar(
      backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
      child: const Icon(Icons.link, color: Colors.deepPurple, size: 26),
    ),
    title: Text(
      invite,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      overflow: TextOverflow.ellipsis,
    ),
    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
    onTap: onTap,
    onLongPress: onLongPress,
  ),
);

class BaseScreen extends StatefulWidget {
  final PunctureClientWrapper punctureClient;

  const BaseScreen({super.key, required this.punctureClient});

  @override
  State<BaseScreen> createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  List<DaemonWrapper> _daemons = [];

  @override
  void initState() {
    super.initState();
    _loadDaemons();
  }

  void _loadDaemons() async {
    final daemons = await widget.punctureClient.listDaemons();

    setState(() {
      _daemons = daemons;
    });
  }

  void _onDaemonTap(DaemonWrapper daemon) async {
    final connection = await daemon.connect();

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        settings: const RouteSettings(name: 'HomeScreen'),
        builder: (_) => HomeScreen(punctureConnection: connection),
      ),
    );
  }

  void _navigateToConnect() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ConnectScreen(
              punctureClient: widget.punctureClient,
              onDaemonAdded: _loadDaemons,
            ),
      ),
    );
  }

  void _showDeleteDaemonDrawer(DaemonWrapper daemon) {
    showModalBottomSheet<bool>(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.deepPurple.withValues(
                          alpha: 0.1,
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.deepPurple,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Disconnect from ${daemon.name()}?',
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  NavigationButton(
                    text: 'Confirm',
                    onPressed: () => _handleDeleteDaemon(daemon),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _handleDeleteDaemon(DaemonWrapper daemon) async {
    await widget.punctureClient.deleteDaemon(daemon: daemon);

    // Refresh the daemons list
    _loadDaemons();

    // Close the drawer
    Navigator.pop(context);
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
              if (_daemons.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'Welcome to Puncture!',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _daemons.length,
                    itemBuilder: (context, index) {
                      final daemon = _daemons[index];
                      return buildInviteTile(
                        daemon.name(),
                        () => _onDaemonTap(daemon),
                        onLongPress: () => _showDeleteDaemonDrawer(daemon),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              NavigationButton(text: 'Connect', onPressed: _navigateToConnect),
            ],
          ),
        ),
      ),
    );
  }
}
