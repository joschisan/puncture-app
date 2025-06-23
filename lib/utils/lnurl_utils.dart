import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import 'dart:convert';
import '../models/lnurl_pay_info.dart';
import 'ln_address.dart';
import 'fp_utils.dart';
import 'http_utils.dart';

/// Fetch LNURL-pay information from a lightning address
/// Returns `TaskEither<String, LnurlPayInfo>` where:
/// - Left contains error message
/// - Right contains parsed LnurlPayInfo
TaskEither<String, LnurlPayInfo> getLnurlPayInfo(
  LightningAddress lightningAddress,
) {
  return safeTask(
        () => http.get(
          Uri.parse(lightningAddress.lnurlEndpoint),
          headers: {'Content-Type': 'application/json'},
        ),
      )
      .mapLeft((_) => 'Failed to connect to lightning address')
      .flatMap(transformResponse)
      .flatMap((body) => safe(() => jsonDecode(body) as Map<String, dynamic>))
      .flatMap((json) => TaskEither.fromEither(LnurlPayInfo.fromJson(json)))
      .mapLeft((_) => 'Invalid response');
}

/// Request a Lightning invoice from LNURL-pay callback
/// Returns `TaskEither<String, String>` where:
/// - Left contains error message
/// - Right contains Lightning invoice
TaskEither<String, String> getLnurlPayInvoice(
  String callbackUrl,
  int amountMsat,
) {
  final Map<String, String> queryParameters = {'amount': amountMsat.toString()};
  final headers = {'Content-Type': 'application/json'};

  return safeTask(
        () => http.get(
          Uri.parse(callbackUrl).replace(queryParameters: queryParameters),
          headers: headers,
        ),
      )
      .mapLeft((_) => 'Failed to connect to lightning address')
      .flatMap(transformResponse)
      .flatMap((body) => safe(() => jsonDecode(body) as Map<String, dynamic>))
      .flatMap((data) => safe(() => data['pr'] as String))
      .mapLeft((_) => 'Invalid response');
}
