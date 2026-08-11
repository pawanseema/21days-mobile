import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Attempts Firebase init when native config / options are present.
///
/// Returns `true` when a Firebase app is available. On failure (common until
/// `GoogleService-Info.plist` / `google-services.json` and
/// `firebase_options.dart` exist), the app falls back to mock email/Google
/// auth while still supporting local guest sessions.
Future<bool> bootstrapFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) return true;
    await Firebase.initializeApp();
    return true;
  } catch (e, st) {
    debugPrint('Firebase bootstrap skipped (using mock auth): $e\n$st');
    return false;
  }
}
