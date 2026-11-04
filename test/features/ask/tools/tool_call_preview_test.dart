import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/ask/tools/tool_call_preview.dart';

ToolCallPreview _preview({
  String toolName = 'addTask',
  String title = 'Add task',
  String summary = 'Gym · 09:00–09:25 · 25 min',
  String confirmLabel = 'Add task',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
}) {
  return ToolCallPreview(
    toolName: toolName,
    title: title,
    summary: summary,
    confirmLabel: confirmLabel,
    cancelLabel: cancelLabel,
    isDestructive: isDestructive,
  );
}

void main() {
  group('ToolCallPreview construction', () {
    test('defaults isDestructive to false', () {
      expect(_preview().isDestructive, isFalse);
    });

    test('holds the fields it was built with', () {
      final p = _preview(
        toolName: 'moveTask',
        title: 'Move task',
        summary: 'Gym · 09:00–09:25 → 10:00–10:25',
        confirmLabel: 'Move',
        cancelLabel: 'Keep',
        isDestructive: true,
      );
      expect(p.toolName, 'moveTask');
      expect(p.title, 'Move task');
      expect(p.summary, 'Gym · 09:00–09:25 → 10:00–10:25');
      expect(p.confirmLabel, 'Move');
      expect(p.cancelLabel, 'Keep');
      expect(p.isDestructive, isTrue);
    });

    test('rejects an empty toolName', () {
      expect(() => _preview(toolName: ''), throwsArgumentError);
    });

    test('rejects an empty title, summary, confirmLabel or cancelLabel', () {
      expect(() => _preview(title: ''), throwsArgumentError);
      expect(() => _preview(summary: ''), throwsArgumentError);
      expect(() => _preview(confirmLabel: ''), throwsArgumentError);
      expect(() => _preview(cancelLabel: ''), throwsArgumentError);
    });
  });

  group('ToolCallPreview value semantics', () {
    test('equal previews compare equal and share a hashCode', () {
      final a = _preview();
      final b = _preview();
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a different field breaks equality', () {
      final base = _preview();
      expect(base == _preview(toolName: 'moveTask'), isFalse);
      expect(base == _preview(title: 'Other'), isFalse);
      expect(base == _preview(summary: 'Other'), isFalse);
      expect(base == _preview(confirmLabel: 'Other'), isFalse);
      expect(base == _preview(cancelLabel: 'Other'), isFalse);
      expect(base == _preview(isDestructive: true), isFalse);
    });

    test('toString mentions the tool and marks destructive previews', () {
      expect(_preview().toString(), contains('addTask'));
      expect(_preview().toString(), isNot(contains('destructive')));
      expect(_preview(isDestructive: true).toString(), contains('destructive'));
    });
  });

  group('ToolCallPreview copyWith', () {
    test('overrides only the fields passed', () {
      final a = _preview();
      final b = a.copyWith(title: 'Reschedule', isDestructive: true);
      expect(b.title, 'Reschedule');
      expect(b.isDestructive, isTrue);
      expect(b.toolName, a.toolName);
      expect(b.summary, a.summary);
      expect(b.confirmLabel, a.confirmLabel);
      expect(b.cancelLabel, a.cancelLabel);
    });

    test('returns an equal preview when no fields are passed', () {
      final a = _preview();
      expect(a.copyWith(), a);
    });

    test('rejects an empty override just like the constructor', () {
      final a = _preview();
      expect(() => a.copyWith(title: ''), throwsArgumentError);
      expect(() => a.copyWith(confirmLabel: ''), throwsArgumentError);
    });
  });
}
