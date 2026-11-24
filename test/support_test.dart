import 'package:flutter_test/flutter_test.dart';
import 'package:grab/core/widgets/support.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('support card shows once per day', () async {
    SharedPreferences.setMockInitialValues({});
    final p = await SharedPreferences.getInstance();
    final mon = DateTime(2026, 11, 23, 9);
    expect(takeDailySupport(p, mon), isTrue);
    expect(takeDailySupport(p, mon.add(const Duration(hours: 8))), isFalse);
    expect(takeDailySupport(p, mon.add(const Duration(days: 1))), isTrue);
  });
}
