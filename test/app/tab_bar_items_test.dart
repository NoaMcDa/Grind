import 'package:flutter_test/flutter_test.dart';
import 'package:grind/app/tab_bar.dart';

void main() {
  test('the tab bar still has five items', () {
    expect(AppTab.values.length, 5);
    expect(AppTab.values, const [
      AppTab.today,
      AppTab.plan,
      AppTab.focus,
      AppTab.pip,
      AppTab.ask,
    ]);
  });
}
