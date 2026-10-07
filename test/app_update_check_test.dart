import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:twenty_one_days/services/app_update_check.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('offers an update when the installed iOS version is behind', () async {
    final offer = await AppUpdateCheck.lookup(
      platform: TargetPlatform.iOS,
      installedVersion: '1.0.4',
      prefs: await SharedPreferences.getInstance(),
      client: _configClient({
        'latestIosVersion': '1.0.5',
        'latestAndroidVersion': '',
      }),
    );

    expect(offer, isNotNull);
    expect(offer!.latestVersion, '1.0.5');
    expect(offer.storeUri.toString(), contains('id6807467774'));
  });

  test('stays quiet when the check fails or the version is not newer', () async {
    final prefs = await SharedPreferences.getInstance();

    expect(
      await AppUpdateCheck.lookup(
        platform: TargetPlatform.android,
        installedVersion: '1.0.4',
        prefs: prefs,
        client: MockClient((_) async => http.Response('nope', 500)),
      ),
      isNull,
    );
    expect(
      await AppUpdateCheck.lookup(
        platform: TargetPlatform.android,
        installedVersion: '1.0.4',
        prefs: prefs,
        client: _configClient({'latestAndroidVersion': ''}),
      ),
      isNull,
    );
    expect(
      await AppUpdateCheck.lookup(
        platform: TargetPlatform.android,
        installedVersion: '1.0.5',
        prefs: prefs,
        client: _configClient({'latestAndroidVersion': '1.0.5'}),
      ),
      isNull,
    );
    expect(
      await AppUpdateCheck.lookup(
        platform: TargetPlatform.iOS,
        installedVersion: 'not-a-version',
        prefs: prefs,
        client: _configClient({'latestIosVersion': '1.0.5'}),
      ),
      isNull,
    );
  });

  test('does not repeat a version the user dismissed', () async {
    SharedPreferences.setMockInitialValues({
      AppUpdateCheck.dismissedVersionKey: '1.0.5',
    });

    final offer = await AppUpdateCheck.lookup(
      platform: TargetPlatform.android,
      installedVersion: '1.0.4',
      prefs: await SharedPreferences.getInstance(),
      client: _configClient({'latestAndroidVersion': '1.0.5'}),
    );

    expect(offer, isNull);
  });
}

MockClient _configClient(Map<String, String> body) {
  return MockClient(
    (_) async => http.Response(jsonEncode(body), 200),
  );
}
