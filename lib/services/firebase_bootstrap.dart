import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Attempts Firebase init using FlutterFire-generated options.
///
/// Returns `true` when a Firebase app is available. On failure the app falls
/// back to mock email/Google auth while still supporting local guest sessions.
Future<bool> bootstrapFirebase() async {
  try {
    if (Firebase.apps.isNotEmpty) return true;
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    return true;
  } catch (e, st) {
    debugPrint('Firebase bootstrap skipped (using mock auth): $e\n$st');
    return false;
  }
}
