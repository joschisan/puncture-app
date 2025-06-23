import 'package:fpdart/fpdart.dart' hide State;
import 'ln_address.dart';

/// Account credentials combining Lightning Address and password
class AccountCredentials {
  final LightningAddress lightningAddress;
  final String password;

  const AccountCredentials({
    required this.lightningAddress,
    required this.password,
  });
}

// Simplified validation functions returning strings directly
Either<String, String> validateNotEmpty(String value) =>
    value.trim().isEmpty
        ? left('Please enter your Lightning Address')
        : right(value.trim());

Either<String, LightningAddress> validateLightningAddress(String value) {
  // Use our centralized validation and convert error types
  return LightningAddress.create(
    value.trim(),
  ).mapLeft((_) => 'Please enter a valid Lightning Address (username@domain)');
}

Either<String, String> validatePassword(String value, {int minLength = 0}) =>
    value.isEmpty
        ? left('Please enter a password')
        : value.length < minLength
        ? left('Password must be at least $minLength characters')
        : right(value);

Either<String, String> validatePasswordMatch(
  String password,
  String confirmPassword,
) =>
    password == confirmPassword
        ? right(password)
        : left('Passwords do not match');
