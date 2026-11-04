import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/home_widget/widget_reminder_copy.dart';
import 'package:grind/features/home_widget/widget_snapshot.dart';

WidgetReminder _reminder({required String title, required String body}) =>
    WidgetReminder(
      taskId: 't',
      notificationId: 'n',
      fireAt: DateTime.utc(2026, 1, 1, 9),
      title: title,
      body: body,
    );

void main() {
  group('of', () {
    test('null reminder → empty copy', () {
      final copy = WidgetReminderCopy.of(null);
      expect(copy, WidgetReminderCopy.empty);
      expect(copy.isEmpty, isTrue);
    });

    test('short strings pass through unchanged, no ellipsis', () {
      final copy = WidgetReminderCopy.of(
        _reminder(title: 'Call Sam', body: 'If 5 min free, text now.'),
      );
      expect(copy.title, 'Call Sam');
      expect(copy.line, 'If 5 min free, text now.');
      expect(copy.isEmpty, isFalse);
    });

    test('whitespace is trimmed on both ends', () {
      final copy = WidgetReminderCopy.of(
        _reminder(title: '  Call Sam  ', body: '\tIf free, text now.\n'),
      );
      expect(copy.title, 'Call Sam');
      expect(copy.line, 'If free, text now.');
    });

    test('empty body is kept empty (no dangling separator)', () {
      final copy = WidgetReminderCopy.of(_reminder(title: 'Call Sam', body: ''));
      expect(copy.title, 'Call Sam');
      expect(copy.line, '');
      expect(copy.headline(), 'Call Sam');
    });

    test('small face trims title and line to its budget', () {
      // 28-char title budget, 48-char line budget.
      const title = 'Write the proposal introduction for the pitch meeting';
      const body =
          'If you have 15 minutes free before lunch, start the draft '
          'and stop at the outline.';
      final copy = WidgetReminderCopy.of(
        _reminder(title: title, body: body),
        size: WidgetReminderFace.small,
      );
      expect(copy.title.length, lessThanOrEqualTo(28));
      expect(copy.line.length, lessThanOrEqualTo(48));
      expect(copy.title.endsWith('…'), isTrue);
      expect(copy.line.endsWith('…'), isTrue);
      // Word-boundary or hard cut: no trailing space before the ellipsis.
      final charBeforeEllipsis = copy.title[copy.title.length - 2];
      expect(charBeforeEllipsis, isNot(' '));
    });

    test('medium face has a wider budget than small', () {
      final text = 'A' * 200;
      final small = WidgetReminderCopy.of(
        _reminder(title: text, body: text),
        size: WidgetReminderFace.small,
      );
      final medium = WidgetReminderCopy.of(
        _reminder(title: text, body: text),
        size: WidgetReminderFace.medium,
      );
      expect(medium.title.length, greaterThan(small.title.length));
      expect(medium.line.length, greaterThan(small.line.length));
      // Both still end with the ellipsis character (text was long enough).
      expect(small.title.endsWith('…'), isTrue);
      expect(medium.title.endsWith('…'), isTrue);
    });

    test('cuts at a word boundary when one sits in the last quarter', () {
      // 28-char budget. "Write proposal before noon today" has a space at
      // index 26, inside the last quarter of the 27-char window, so the
      // cut lands there instead of mid-word.
      final copy = WidgetReminderCopy.of(
        _reminder(title: 'Write proposal before noon today', body: ''),
        size: WidgetReminderFace.small,
      );
      expect(copy.title, 'Write proposal before noon…');
    });

    test('falls back to a hard cut when no nearby space exists', () {
      // A 60-char run with no spaces: falls back to the hard cut rather
      // than giving up on the word entirely.
      final text = 'A${'B' * 59}';
      final copy = WidgetReminderCopy.of(
        _reminder(title: text, body: ''),
        size: WidgetReminderFace.small,
      );
      expect(copy.title.endsWith('…'), isTrue);
      expect(copy.title.length, 28);
      // The ellipsis sits right after a letter, not a stray space.
      final beforeEllipsis = copy.title[copy.title.length - 2];
      expect(beforeEllipsis, isNot(' '));
    });

    test('strips trailing punctuation adjacent to the ellipsis', () {
      // 28-char budget. Last space in the cut window lands right after
      // "rest,"; the comma gets stripped so the ellipsis reads cleanly.
      final copy = WidgetReminderCopy.of(
        _reminder(
          title: 'Done, then plan the rest, soon enough work',
          body: '',
        ),
        size: WidgetReminderFace.small,
      );
      expect(copy.title, 'Done, then plan the rest…');
    });

    test('empty input yields empty output, not an ellipsis', () {
      final copy = WidgetReminderCopy.of(
        _reminder(title: '   ', body: '\n\t'),
      );
      expect(copy.title, '');
      expect(copy.line, '');
      expect(copy.isEmpty, isTrue);
    });
  });

  group('headline', () {
    test('combines title and line with an em-dash separator', () {
      const copy = WidgetReminderCopy(
        title: 'Call Sam',
        line: 'If 5 min free, text now',
      );
      expect(copy.headline(), 'Call Sam — If 5 min free, text now');
    });

    test('only title → no separator', () {
      const copy = WidgetReminderCopy(title: 'Call Sam', line: '');
      expect(copy.headline(), 'Call Sam');
    });

    test('only line → no separator', () {
      const copy = WidgetReminderCopy(title: '', line: 'If free, now');
      expect(copy.headline(), 'If free, now');
    });

    test('empty → empty headline', () {
      expect(WidgetReminderCopy.empty.headline(), '');
    });
  });

  group('equality', () {
    test('value equality on title and line', () {
      const a = WidgetReminderCopy(title: 't', line: 'b');
      const b = WidgetReminderCopy(title: 't', line: 'b');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const WidgetReminderCopy(title: 't', line: 'b!')));
    });
  });
}
