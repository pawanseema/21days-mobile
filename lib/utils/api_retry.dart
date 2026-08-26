import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Number of retries after the first attempt (total attempts = [kApiRetries] + 1).
const int kApiRetries = 2;

const Duration kApiRetryDelay = Duration(milliseconds: 450);

typedef ApiOnRetry = void Function();

/// Runs [action] up to 1 + [retries] times for transient failures.
Future<T> runWithRetries<T>(
  Future<T> Function() action, {
  int retries = kApiRetries,
  Duration delay = kApiRetryDelay,
  bool Function(Object error)? isRetryable,
  ApiOnRetry? onRetry,
}) async {
  final maxAttempts = retries + 1;
  Object? lastError;
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    try {
      return await action();
    } catch (e, st) {
      lastError = e;
      final retryable = isRetryable?.call(e) ?? isTransientApiError(e);
      final hasRetriesLeft = attempt < retries;
      if (!retryable || !hasRetriesLeft) {
        debugPrint(
          'API request failed (attempt ${attempt + 1}/$maxAttempts): $e\n$st',
        );
        rethrow;
      }
      debugPrint(
        'API request retrying (attempt ${attempt + 1}/$maxAttempts): $e',
      );
      onRetry?.call();
      await Future<void>.delayed(delay);
    }
  }
  throw lastError!;
}

/// Network, timeout, and similar transient failures worth retrying.
bool isTransientApiError(Object error) {
  if (error is TimeoutException) return true;
  if (error is http.ClientException) return true;
  if (error is ApiHttpException) return error.retryable;
  // dart:io errors (mobile/desktop); avoid importing dart:io for web builds.
  final type = error.runtimeType.toString();
  return type == 'SocketException' || type == 'HandshakeException';
}

/// HTTP-layer failure with optional retry (5xx) vs permanent (4xx / bad payload).
class ApiHttpException implements Exception {
  ApiHttpException(
    this.debugDetail, {
    this.retryable = false,
    this.statusCode,
  });

  final String debugDetail;
  final bool retryable;
  final int? statusCode;

  @override
  String toString() => debugDetail;
}

bool isRetryableStatusCode(int statusCode) => statusCode >= 500;
