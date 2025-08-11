import 'package:fpdart/fpdart.dart';

class Payment {
  final String id;
  final String paymentType;
  final int amountMsat;
  final int feeMsat;
  final String description;
  String status;
  final Option<String> lightningAddress;
  final DateTime createdAt;

  Payment({
    required this.id,
    required this.paymentType,
    required this.amountMsat,
    required this.feeMsat,
    required this.description,
    required this.status,
    required this.lightningAddress,
    required this.createdAt,
  });

  int get amountSats => (amountMsat / 1000).round();
  int get feeSats => (feeMsat / 1000).round();
  bool get isIncoming => paymentType == "receive";
  bool get isPending => status == "pending";
  bool get isSuccess => status == "successful";
  bool get isFailed => status == "failed";
  String get displayAmount => '${isIncoming ? '+' : '-'}$amountSats';
  String get displayStatus => status;
  String get displayDescription => description;
}
