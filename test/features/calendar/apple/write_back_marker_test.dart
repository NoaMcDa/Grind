import 'package:flutter_test/flutter_test.dart';
import 'package:grind/features/calendar/apple/write_back_marker.dart';

void main() {
  test('notes keep the task notes and end with the marker', () {
    expect(WriteBackMarker.notesFor(taskId: 'a'), 'grindTaskId:a');
    expect(
      WriteBackMarker.notesFor(taskId: 'a', taskNotes: '  '),
      'grindTaskId:a',
    );
    expect(
      WriteBackMarker.notesFor(taskId: 'a', taskNotes: 'Bring laptop'),
      'Bring laptop\n\ngrindTaskId:a',
    );
  });

  test('parses the URL first, then the notes', () {
    expect(WriteBackMarker.urlFor('t-1'), 'grind://task/t-1');
    expect(WriteBackMarker.parse(url: 'grind://task/t-1'), 't-1');
    expect(
      WriteBackMarker.parse(
        url: 'grind://task/t-1',
        notes: 'grindTaskId:other',
      ),
      't-1',
    );
    expect(
      WriteBackMarker.parse(
        url: 'https://zoom.us/j/1',
        notes: 'Agenda\n\ngrindTaskId:t-2',
      ),
      't-2',
    );
  });

  test('ordinary events have no task', () {
    expect(WriteBackMarker.parse(), isNull);
    expect(WriteBackMarker.parse(url: 'grind://task/'), isNull);
    expect(WriteBackMarker.parse(url: 'grind://other/x'), isNull);
    expect(WriteBackMarker.parse(notes: 'Lunch with Dana'), isNull);
  });
}
