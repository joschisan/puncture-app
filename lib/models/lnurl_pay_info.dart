import 'package:fpdart/fpdart.dart';

class LnurlPayInfo {
  final int minSendable; // in millisats
  final int maxSendable; // in millisats
  final String callbackUrl;

  const LnurlPayInfo({
    required this.minSendable,
    required this.maxSendable,
    required this.callbackUrl,
  });

  // Helper getters
  int get minSendableSats => (minSendable / 1000).round();
  int get maxSendableSats => (maxSendable / 1000).round();

  // Validation helpers
  bool isAmountValid(int amountSats) {
    return amountSats * 1000 >= minSendable && amountSats * 1000 <= maxSendable;
  }

  /// Parse JSON into LnurlPayInfo with functional error handling
  /// Returns `Either<String, LnurlPayInfo>` where:
  /// - Left contains error message
  /// - Right contains parsed LnurlPayInfo
  static Either<String, LnurlPayInfo> fromJson(Map<String, dynamic> json) {
    return Either.fromNullable(
          json['minSendable'],
          () => 'Missing required field: minSendable',
        )
        .flatMap(
          (value) =>
              value is int
                  ? Either.right(value)
                  : Either.left('Invalid minSendable: must be an integer'),
        )
        .flatMap(
          (minSendable) => Either.fromNullable(
                json['maxSendable'],
                () => 'Missing required field: maxSendable',
              )
              .flatMap(
                (value) =>
                    value is int
                        ? Either.right(value)
                        : Either.left(
                          'Invalid maxSendable: must be an integer',
                        ),
              )
              .flatMap(
                (maxSendable) => Either.fromNullable(
                      json['callback'],
                      () => 'Missing required field: callback',
                    )
                    .flatMap(
                      (value) =>
                          value is String
                              ? Either.right(value)
                              : Either.left(
                                'Invalid callback: must be a string',
                              ),
                    )
                    .flatMap(
                      (callbackUrl) =>
                          minSendable <= maxSendable
                              ? Either.right(
                                LnurlPayInfo(
                                  minSendable: minSendable,
                                  maxSendable: maxSendable,
                                  callbackUrl: callbackUrl,
                                ),
                              )
                              : Either.left(
                                'Invalid range: minSendable must be <= maxSendable',
                              ),
                    ),
              ),
        );
  }

  Map<String, dynamic> toJson() {
    return {
      'minSendable': minSendable,
      'maxSendable': maxSendable,
      'callback': callbackUrl,
    };
  }
}
