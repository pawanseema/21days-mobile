import 'package:flutter_test/flutter_test.dart';
import 'package:twenty_one_days/utils/app_version.dart';

void main() {
  test('parses a store version and ignores a build number', () {
    final version = AppVersion.tryParse('1.0.4+19');
    expect(version, isNotNull);
    expect(version!.isBehind(AppVersion.tryParse('1.0.5')!), isTrue);
    expect(version.isBehind(AppVersion.tryParse('1.0.4')!), isFalse);
  });

  test('compares numeric segments', () {
    final installed = AppVersion.tryParse('1.0.9')!;
    expect(installed.isBehind(AppVersion.tryParse('1.0.10')!), isTrue);
    expect(installed.isBehind(AppVersion.tryParse('1.0')!), isFalse);
  });

  test('rejects empty and non-numeric versions', () {
    expect(AppVersion.tryParse(null), isNull);
    expect(AppVersion.tryParse(''), isNull);
    expect(AppVersion.tryParse('1.0.beta'), isNull);
  });
}
