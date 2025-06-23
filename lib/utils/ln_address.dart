import 'package:fpdart/fpdart.dart';

/// Lightning Address value object with built-in validation
class LightningAddress {
  final String username;
  final String domain;

  const LightningAddress({required this.username, required this.domain});

  /// Get the full address string (username@domain)
  String get fullAddress => '$username@$domain';

  /// Check if the domain is a raw IP address with a port
  bool isRawIpAddress() {
    return RegExp(r'^(\d{1,3}\.){3}\d{1,3}:\d+$').hasMatch(domain);
  }

  /// Get the protocol for the domain, either http or https
  String get protocol => isRawIpAddress() ? 'http' : 'https';

  /// Get the base URL for API calls to this domain
  String get baseUrl => '$protocol://$domain';

  /// Get the LNURL pay endpoint for this Lightning Address
  String get lnurlEndpoint =>
      '$protocol://$domain/.well-known/lnurlp/$username';

  /// Parse and validate lightning address string with functional error handling
  /// Returns `Either<String, LightningAddress>` where:
  static Either<String, LightningAddress> create(String input) {
    // Simple regex: non-empty username @ non-empty domain
    final lightningAddressRegex = RegExp(r'^.+@.+$');

    if (!lightningAddressRegex.hasMatch(input)) {
      return Either.left('Invalid Lightning address format');
    }

    return Either.right(
      LightningAddress(
        username: input.split('@')[0],
        domain: input.split('@')[1],
      ),
    );
  }

  @override
  String toString() => fullAddress;
}
