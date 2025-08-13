import 'package:flutter/material.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:fpdart/fpdart.dart' hide State;

import '../models/payment.dart';
import '../screens/send_screen.dart';
import '../screens/receive_screen.dart';
import '../screens/recovery_screen.dart';
import '../screens/payment_details_screen.dart';
import '../utils/notification_utils.dart';
import '../utils/fp_utils.dart';
import '../widgets/async_action_button.dart';
import '../widgets/navigation_button.dart';
import '../widgets/amount_display.dart';
import '../bridge_generated.dart/lib.dart';

IconData getStatusIcon(Payment payment) => switch (payment) {
  _ when payment.isIncoming => Icons.arrow_downward,
  _ when payment.isSuccess => Icons.arrow_upward,
  _ when payment.isFailed => Icons.close,
  _ => Icons.help,
};

String formatTime(DateTime dateTime) {
  final difference = DateTime.now().difference(dateTime);

  return switch (difference) {
    _ when difference.inMinutes < 1 => 'Now',
    _ when difference.inMinutes < 60 => '${difference.inMinutes}m ago',
    _ when difference.inHours < 24 => '${difference.inHours}h ago',
    _ => '${difference.inDays}d ago',
  };
}

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
  (balance) => AmountDisplay(balance),
);

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

Widget buildPaymentTile(Payment payment, {VoidCallback? onTap}) => Card(
  margin: const EdgeInsets.symmetric(vertical: 4.0),
  child: ListTile(
    contentPadding: const EdgeInsets.all(8.0),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    onTap: onTap,
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

TaskEither<String, void> navigateToReceive(
  BuildContext context,
  PunctureConnectionWrapper punctureConnection,
) {
  return safeTask(() => punctureConnection.bolt12Receive()).map((
    offer,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) => ReceiveScreen(
              offer: offer,
              punctureConnection: punctureConnection,
            ),
      ),
    );
  });
}

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
    Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6.0),
        child: AsyncActionButton(
          text: 'Receive',
          onPressed: () => navigateToReceive(context, punctureConnection),
        ),
      ),
    ),
    Expanded(
      child: Padding(
        padding: const EdgeInsets.only(left: 6.0),
        child: NavigationButton(
          text: 'Send',
          onPressed:
              () => navigateToSend(context, punctureConnection, payments),
        ),
      ),
    ),
  ],
);

void handleError(String error) {
  NotificationUtils.showError(error);
}

class HomeScreen extends StatefulWidget {
  final PunctureConnectionWrapper punctureConnection;

  const HomeScreen({super.key, required this.punctureConnection});

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

      if (!mounted) return;

      _handleEvent(event);
    }
  }

  // Handle events from the Rust client
  void _handleEvent(Event event) {
    switch (event) {
      case Event_Payment(:final field0):
        _handlePaymentEvent(field0);
        break;
      case Event_Balance(:final field0):
        _handleBalanceEvent(field0);
        break;
      case Event_Update(:final field0):
        _handleUpdateEvent(field0);
        break;
    }
  }

  // Handle balance updates from Rust client
  void _handleBalanceEvent(BalanceEvent balanceEvent) {
    setState(() {
      _balanceSats = fp.Some((balanceEvent.amountMsat.toInt() / 1000).round());
    });
  }

  // Handle payment updates from Rust client
  void _handlePaymentEvent(PaymentEvent paymentEvent) {
    final existingIndex = _payments.indexWhere((p) => p.id == paymentEvent.id);

    if (existingIndex == -1) {
      if (paymentEvent.paymentType == 'receive' && paymentEvent.isLive) {
        NotificationUtils.showReceive(
          (paymentEvent.amountMsat.toInt() / 1000).round(),
        );
      }

      final payment = Payment(
        id: paymentEvent.id,
        paymentType: paymentEvent.paymentType,
        amountMsat: paymentEvent.amountMsat.toInt(),
        feeMsat: paymentEvent.feeMsat.toInt(),
        description: paymentEvent.description,
        status: paymentEvent.status,
        lightningAddress: fp.Option.fromNullable(paymentEvent.lnAddress),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          paymentEvent.createdAt.toInt(),
        ),
      );

      setState(() {
        _payments.insert(0, payment);
        _listKey.currentState?.insertItem(0); // Trigger the animation
      });
    }
  }

  // Handle update events from Rust client
  void _handleUpdateEvent(UpdateEvent updateEvent) {
    if (updateEvent.status == 'failed') {
      NotificationUtils.showError('Payment failed');
    }

    final existingIndex = _payments.indexWhere((p) => p.id == updateEvent.id);

    if (existingIndex != -1) {
      setState(() {
        _payments[existingIndex].status = updateEvent.status;
        _payments[existingIndex].feeMsat = updateEvent.feeMsat.toInt();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder:
                      (context) => RecoveryScreen(
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
                      child: buildPaymentTile(
                        _payments[index],
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder:
                                  (context) => PaymentDetailsScreen(
                                    payment: _payments[index],
                                  ),
                            ),
                          );
                        },
                      ),
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
