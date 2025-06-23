import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';

/// Transforms an HTTP response into a TaskEither with human-readable error messages
TaskEither<String, String> transformResponse(http.Response response) {
  if (response.statusCode == 200) {
    return TaskEither.right(response.body);
  }

  // Map status codes to human readable messages
  switch (response.statusCode) {
    case 400:
      return TaskEither.left(response.body);
    case 401:
      return TaskEither.left('Session expired, please sign in again');
    case 429:
      return TaskEither.left('Too many requests, please try again later');
    default:
      return TaskEither.left('Something went wrong, please try again');
  }
}
