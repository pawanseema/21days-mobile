import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/app_version.dart';
import '../utils/constants.dart';

/// A published store version newer than the one installed on this phone.
class AppUpdateOffer {
  const AppUpdateOffer({
    required this.latestVersion,
    required this.storeUri,
  });

  final String latestVersion;
  final Uri storeUri;
}

/// Compares the installed version with `GET /api/ui-config`.
///
/// Any failure returns null. Callers must not surface that to the user.
class AppUpdateCheck {
  AppUpdateCheck._();

  static const String dismissedVersionKey = 'dismissed_app_update_version';

  static Future<AppUpdateOffer?> lookup({
    http.Client? client,
    String? baseUrl,
    TargetPlatform? platform,
    String? installedVersion,
    SharedPreferences? prefs,
  }) async {
    try {
      if (kIsWeb) return null;
      final resolvedPlatform = platform ?? defaultTargetPlatform;
      final versionKey = switch (resolvedPlatform) {
        TargetPlatform.iOS => 'latestIosVersion',
        TargetPlatform.android => 'latestAndroidVersion',
        _ => null,
      };
      final storeUrl = switch (resolvedPlatform) {
        TargetPlatform.iOS => AppConstants.iosStoreUrl,
        TargetPlatform.android => AppConstants.androidStoreUrl,
        _ => null,
      };
      if (versionKey == null || storeUrl == null) return null;

      final storeUri = Uri.tryParse(storeUrl);
      if (storeUri == null || !storeUri.hasScheme) return null;

      final httpClient = client ?? http.Client();
      final ownsClient = client == null;
      try {
        final root = _normalizeBaseUrl(baseUrl ?? AppConstants.apiBaseUrl);
        final response = await httpClient
            .get(
              Uri.parse('$root${AppConstants.uiConfigPath}'),
              headers: const {'Accept': 'application/json'},
            )
            .timeout(const Duration(seconds: 8));
        if (response.statusCode != 200) return null;
        final decoded = jsonDecode(response.body);
        if (decoded is! Map) return null;
        final published = AppVersion.tryParse(
          decoded[versionKey]?.toString(),
        );
        if (published == null) return null;

        final installedRaw = installedVersion ?? await _readInstalledVersion();
        final installed = AppVersion.tryParse(installedRaw);
        if (installed == null || !installed.isBehind(published)) return null;

        final preferences = prefs ?? await SharedPreferences.getInstance();
        final dismissed = AppVersion.tryParse(
          preferences.getString(dismissedVersionKey),
        );
        if (dismissed != null && !dismissed.isBehind(published)) return null;

        final latestVersion = decoded[versionKey].toString().trim();
        return AppUpdateOffer(latestVersion: latestVersion, storeUri: storeUri);
      } finally {
        if (ownsClient) httpClient.close();
      }
    } catch (_) {
      return null;
    }
  }

  static Future<void> dismiss(String latestVersion) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(dismissedVersionKey, latestVersion.trim());
    } catch (_) {}
  }

  static Future<String?> _readInstalledVersion() async {
    final info = await PackageInfo.fromPlatform();
    final version = info.version.trim();
    if (version.isEmpty) return null;
    return version;
  }

  static String _normalizeBaseUrl(String url) {
    var value = url.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
