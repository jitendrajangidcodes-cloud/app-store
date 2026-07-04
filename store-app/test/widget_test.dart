import 'package:flutter_test/flutter_test.dart';
import 'package:pnsjy_store/data/version_compare.dart';

void main() {
  test('semver: newer name is an update', () {
    expect(isNewer(installedName: '1.0.0', latestName: '1.0.1'), isTrue);
    expect(isNewer(installedName: '2.0.0', latestName: '1.9.9'), isFalse);
    expect(isNewer(installedName: '1.2.3', latestName: '1.2.3'), isFalse);
  });

  test('versionCode wins when both present', () {
    expect(
      isNewer(installedName: '1.0.0', installedCode: 5, latestName: '1.0.0', latestCode: 6),
      isTrue,
    );
    expect(
      isNewer(installedName: '9.9.9', installedCode: 9, latestName: '1.0.0', latestCode: 6),
      isFalse,
    );
  });

  test('unparseable version never nags', () {
    expect(isNewer(installedName: 'weird', latestName: 'also-weird'), isFalse);
  });
}
