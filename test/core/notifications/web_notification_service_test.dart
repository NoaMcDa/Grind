import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/core/notifications/notifications.dart';

class FakeBrowser implements BrowserNotificationApi {
  @override
  bool supported = true;
  @override
  String permission = 'default';
  final shown = <({String title, String tag, void Function() onClick})>[];

  @override
  Future<String> requestPermission() async => permission = 'granted';

  @override
  void show({
    required String title,
    required String body,
    required String tag,
    required void Function() onClick,
  }) => shown.add((title: title, tag: tag, onClick: onClick));
}

void main() {
  final now = DateTime.utc(2026, 11, 3, 6);
  late FakeBrowser browser;
  late WebNotificationService service;

  setUp(() {
    browser = FakeBrowser();
    service = WebNotificationService(browser, clock: FixedClock(now));
  });

  tearDown(() => service.dispose());

  ScheduledNotification n(String id, String taskId, Duration after) =>
      ScheduledNotification(
        id: id,
        taskId: taskId,
        fireAt: now.add(after),
        title: id,
        body: 'b',
      );

  test('permission flow', () async {
    expect(await service.hasPermission(), isFalse);
    expect(await service.requestPermission(), isTrue);
    expect(await service.hasPermission(), isTrue);
    browser.supported = false;
    expect(await service.requestPermission(), isFalse);
  });

  test('fires in-tab timers, click becomes a response', () async {
    await service.requestPermission();
    final responses = <NotificationResponse>[];
    service.responses.listen(responses.add);
    await service.replaceAll([
      n('soon', 'a', const Duration(milliseconds: 20)),
      n('later', 'b', const Duration(days: 2)),
      n('past', 'c', const Duration(minutes: -1)),
    ]);
    expect(service.armedIds, ['soon', 'later']);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    expect(browser.shown.map((s) => s.tag), ['soon']);
    browser.shown.single.onClick();
    await pumpEventQueue();
    expect(responses.single.taskId, 'a');
    expect(responses.single.action, isNull);
  });

  test('replaceAll re-arms and cancelForTask disarms', () async {
    await service.requestPermission();
    await service.replaceAll([
      n('x', 'a', const Duration(milliseconds: 20)),
      n('y', 'b', const Duration(milliseconds: 20)),
    ]);
    await service.replaceAll([n('z', 'b', const Duration(milliseconds: 20))]);
    await service.cancelForTask('b');
    expect(service.armedIds, isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 60));
    expect(browser.shown, isEmpty);
  });
}
