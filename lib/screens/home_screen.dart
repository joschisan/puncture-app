import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:intl/intl.dart';

import '../models/payment.dart';
import '../screens/create_invoice_screen.dart';
import '../screens/send_screen.dart';
import '../screens/display_invite_screen.dart';
import '../utils/notification_utils.dart';
import '../bridge_generated.dart/lib.dart';

// Pure helper functions with functional programming patterns
IconData getStatusIcon(Payment payment) => switch (payment) {
  _ when payment.isIncoming => Icons.arrow_downward,
  _ when payment.isSuccess => Icons.arrow_upward,
  _ when payment.isFailed => Icons.close,
  _ => Icons.help,
};

// Functional time formatting with pattern matching on duration
String formatTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  return switch (difference) {
    _ when difference.inMinutes < 1 => 'Now',
    _ when difference.inMinutes < 60 => '${difference.inMinutes}m ago',
    _ when difference.inHours < 24 => '${difference.inHours}h ago',
    _ => '${difference.inDays}d ago',
  };
}

// Functional composition for balance display with Option pattern matching
Widget buildBalance(fp.Option<int> balanceSats) => balanceSats.fold(
  () => const SizedBox(
    height: 48,
    child: Center(
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
      ),
    ),
  ),
  (balance) => RichText(
    text: TextSpan(
      children: [
        TextSpan(
          text: NumberFormat('#,###').format(balance),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const TextSpan(
          text: 'sats',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
      ],
    ),
  ),
);

// Higher-order function for creating table rows
TableRow buildTableRow(String label, String value) => TableRow(
  children: [
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
    ),
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Text(value, style: const TextStyle()),
    ),
  ],
);

// Pure function for payment tile with functional composition
Widget buildPaymentTile(Payment payment) => Card(
  margin: const EdgeInsets.symmetric(vertical: 4.0),
  child: ListTile(
    contentPadding: const EdgeInsets.all(8.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    leading: CircleAvatar(
      backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
      child:
          payment.isPending
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
              : Icon(
                getStatusIcon(payment),
                color: Colors.deepPurple,
                size: 26,
              ),
    ),
    title:
        payment.isIncoming
            ? Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${payment.displayAmount} sats',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
            : Text(
              '${payment.displayAmount} sats',
              style: TextStyle(
                color: payment.isFailed ? Colors.grey : Colors.white,
                fontSize: 16,
              ),
            ),
    trailing: Text(
      formatTime(payment.createdAt),
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    ),
  ),
);

// Higher-order function for creating action buttons
Widget buildActionButton({
  required String label,
  required IconData icon,
  required VoidCallback onPressed,
  EdgeInsets? padding,
}) => Expanded(
  child: Padding(
    padding: padding ?? EdgeInsets.zero,
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ),
  ),
);

// Navigation functions as pure actions
void navigateToReceive(
  BuildContext context,
  PunctureConnectionWrapper punctureConnection,
) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => CreateInvoiceScreen(punctureConnection: punctureConnection),
  ),
);

void navigateToSend(
  BuildContext context,
  PunctureConnectionWrapper punctureConnection,
  List<Payment> payments,
) {
  // Extract unique lightning addresses from payments
  final lightningAddresses =
      payments
          .expand(
            (payment) => payment.lightningAddress.fold(
              () => <String>[], // None case - empty list
              (address) => [address], // Some case - single item list
            ),
          )
          .toSet()
          .toList();

  Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => SendScreen(
            punctureConnection: punctureConnection,
            lightningAddresses: lightningAddresses,
          ),
    ),
  );
}

// Functional composition for action buttons
Widget buildActionButtons(
  BuildContext context,
  PunctureConnectionWrapper punctureConnection,
  List<Payment> payments,
) => Row(
  children: [
    buildActionButton(
      label: 'Receive',
      icon: Icons.arrow_downward,
      padding: const EdgeInsets.only(right: 6.0),
      onPressed: () => navigateToReceive(context, punctureConnection),
    ),
    buildActionButton(
      label: 'Send',
      icon: Icons.arrow_upward,
      padding: const EdgeInsets.only(left: 6.0),
      onPressed: () => navigateToSend(context, punctureConnection, payments),
    ),
  ],
);

// Pure side effect handler with functional composition
void handleNotification(String message) {
  NotificationUtils.showInfo(message);
}

void handleError(String error) {
  NotificationUtils.showError(error);
}

class HomeScreen extends StatefulWidget {
  final PunctureConnectionWrapper punctureConnection;
  final String inviteString;

  const HomeScreen({
    super.key,
    required this.punctureConnection,
    required this.inviteString,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  final List<Payment> _payments = [];
  fp.Option<int> _balanceSats = fp.None();

  @override
  void initState() {
    super.initState();
    _startEventListener();
  }

  // Start listening to events from the Rust client
  void _startEventListener() async {
    while (mounted) {
      final event = await widget.punctureConnection.nextEvent();

      if (mounted) {
        _handleEvent(event);
      }
    }
  }

  // Handle events from the Rust client
  void _handleEvent(Event event) {
    switch (event) {
      case Event_Payment(:final field0):
        _handlePaymentUpdate(field0);
        break;
      case Event_Balance(:final field0):
        _handleBalanceUpdate(field0);
        break;
      case Event_Update(:final field0):
        _handleUpdateEvent(field0);
        break;
    }
  }

  // Handle balance updates from Rust client
  void _handleBalanceUpdate(BalanceEvent balanceEvent) {
    setState(() {
      _balanceSats = fp.Some((balanceEvent.msat.toInt() / 1000).round());
    });
  }

  // Handle payment updates from Rust client
  void _handlePaymentUpdate(PaymentEvent paymentEvent) {
    final existingIndex = _payments.indexWhere((p) => p.id == paymentEvent.id);

    if (existingIndex == -1) {
      final payment = Payment(
        id: paymentEvent.id,
        amountMsat: paymentEvent.amountMsat.toInt(),
        status: paymentEvent.status,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          paymentEvent.createdAt.toInt() * 1000,
        ),
        paymentType: paymentEvent.paymentType,
        lightningAddress: fp.Option.fromNullable(paymentEvent.lnAddress),
      );

      setState(() {
        _payments.insert(0, payment);
        _listKey.currentState?.insertItem(0); // Trigger the animation
      });
    }
  }

  // Handle update events from Rust client
  void _handleUpdateEvent(UpdateEvent updateEvent) {
    final existingIndex = _payments.indexWhere((p) => p.id == updateEvent.id);

    if (existingIndex != -1) {
      setState(() {
        _payments[existingIndex].status = updateEvent.status;
      });
    }
  }

  @override
  void dispose() {
    // The event listener will stop automatically when mounted becomes false
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.link),
            onPressed:
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder:
                        (_) => DisplayInviteScreen(invite: widget.inviteString),
                  ),
                ),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              buildBalance(_balanceSats),
              const SizedBox(height: 24),
              buildActionButtons(context, widget.punctureConnection, _payments),
              const SizedBox(height: 12),
              Expanded(
                child: AnimatedList(
                  key: _listKey,
                  initialItemCount: _payments.length,
                  itemBuilder: (context, index, animation) {
                    return SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: const Offset(1.0, 0.0),
                          end: Offset.zero,
                        ).chain(CurveTween(curve: Curves.easeOut)),
                      ),
                      child: buildPaymentTile(_payments[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
