import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';
import 'package:grind/features/companion/effort_score.dart';
import 'package:grind/features/companion/mood.dart';
import 'package:grind/features/companion/pip_providers.dart';

final _now = DateTime(2026, 11, 3, 12);

Task _done(String id, DateTime at) => Task(
  id: id,
  title: id,
  status: TaskStatus.done,
  completedAt: at,
  createdAt: at,
  updatedAt: at,
);

ProviderContainer _container(
  List<Task> tasks, {
  List<Override> extra = const [],
}) {
  final c = ProviderContainer(
    overrides: [
      clockProvider.overrideWithValue(FixedClock(_now)),
      taskRepositoryProvider.overrideWithValue(InMemoryTaskRepository(tasks)),
      ...extra,
    ],
  );
  addTearDown(c.dispose);
  return c;
}

Future<void> _load(ProviderContainer c) async {
  c.listen(tasksProvider, (_, _) {});
  await c.read(taskRepositoryProvider).getAll();
  await Future<void>.delayed(Duration.zero);
}

void main() {
  test('empty repo gives a quiet Pip and an empty meter', () async {
    final c = _container(const []);
    await _load(c);
    expect(c.read(pipMoodProvider), PipMood.quiet);
    expect(c.read(momentumProvider).total, 0);
  });

  test(
    'completed tasks make Pip glow; sessions plug in via override',
    () async {
      final tasks = [for (var i = 0; i < 6; i++) _done('t$i', _now)];
      final c = _container(tasks);
      await _load(c);
      expect(c.read(effortScoreProvider).value, closeTo(75, 0.1));
      expect(c.read(pipMoodProvider), PipMood.glowing);
      final m = c.read(momentumProvider);
      expect(m.level, MomentumLevel.strong);
      expect(m.recent + m.carry, closeTo(0.75, 0.01));
      expect(m.showedUpDays, 1);

      final withSession = _container(
        const [],
        extra: [
          focusSessionsProvider.overrideWithValue([
            FocusSession(
              id: 's',
              plannedMinutes: 25,
              startedAt: _now.subtract(const Duration(minutes: 25)),
              endedAt: _now,
              completed: true,
              createdAt: _now,
              updatedAt: _now,
            ),
          ]),
        ],
      );
      await _load(withSession);
      expect(withSession.read(effortScoreProvider).value, greaterThan(0));
    },
  );

  test('companion prefs wear an accessory and store it', () async {
    final prefs = InMemoryPreferencesRepository();
    final c = _container(
      const [],
      extra: [preferencesRepositoryProvider.overrideWithValue(prefs)],
    );
    expect(c.read(companionPrefsProvider).accessory, 'scarf');
    c.read(companionPrefsProvider.notifier).wear('sunglasses');
    expect(c.read(companionPrefsProvider).accessory, 'sunglasses');
    await pumpEventQueue();
    expect(c.read(companionPrefsProvider).accessory, 'sunglasses');
    expect((await prefs.get()).pipAccessory, 'sunglasses');
  });

  test('companion prefs start from the stored accessory', () async {
    final prefs = InMemoryPreferencesRepository(
      const Preferences(pipAccessory: 'beanie'),
    );
    final c = _container(
      const [],
      extra: [preferencesRepositoryProvider.overrideWithValue(prefs)],
    );
    c.read(companionPrefsProvider);
    await pumpEventQueue();
    expect(c.read(companionPrefsProvider).accessory, 'beanie');

    // A change made elsewhere (an import, another screen) flows in.
    await prefs.save((await prefs.get()).copyWith(pipAccessory: 'scarf'));
    await pumpEventQueue();
    expect(c.read(companionPrefsProvider).accessory, 'scarf');
  });
}
