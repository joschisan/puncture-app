import 'package:fpdart/fpdart.dart';

class Payment {
  final String id;
  final int amountMsat;
  final DateTime createdAt;
  final String paymentType;
  final Option<String> lightningAddress;
  String status;

  Payment({
    required this.id,
    required this.amountMsat,
    required this.createdAt,
    required this.paymentType,
    required this.lightningAddress,
    required this.status,
  });

  // Helper getters
  int get amountSats => (amountMsat / 1000).round();
  bool get isIncoming => paymentType == "receive";
  bool get isOutgoing => paymentType == "send";
  bool get isPending => status.toLowerCase() == "pending";
  bool get isSuccess => status.toLowerCase() == "successful";
  bool get isFailed => status.toLowerCase() == "failed";

  String get displayAmount => '${isIncoming ? '+' : '-'}$amountSats';
}
