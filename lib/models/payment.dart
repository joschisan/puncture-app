import 'package:fpdart/fpdart.dart';

class Payment {
  final String id;
  final String paymentType;
  final int amountMsat;
  String status;
  final Option<String> lightningAddress;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.paymentType,
    required this.amountMsat,
    required this.status,
    required this.lightningAddress,
    required this.createdAt,
  });

  int get amountSats => (amountMsat / 1000).round();
  bool get isIncoming => paymentType == "receive";
  bool get isPending => status == "pending";
  bool get isSuccess => status == "successful";
  bool get isFailed => status == "failed";
  String get displayAmount => '${isIncoming ? '+' : '-'}$amountSats';
}
