import 'package:flutter/foundation.dart';

/// The display contract for one assistant-proposed tool call, rendered
/// as a confirmation card in the Ask Pip stream (#42).
///
/// A [ToolCallPreview] is the view-model between the typed [ToolCall]
/// schema (#109) and the card widget: the executor builds one of these
/// per proposed action, the card reads it to lay out its title, summary
/// line and two action buttons, and nothing is written to repositories
/// until the user taps the confirm button. The object itself is pure
/// data — it holds no callbacks and knows nothing about Flutter — so
/// the composer, tests and (later) golden widget tests can all share it.
///
/// Localization happens one layer up: the caller passes already-translated
/// strings for [title], [summary], [confirmLabel] and [cancelLabel]. The
/// preview only enforces that each is non-empty, and carries [toolName]
/// (matching [ToolCall.name]) so the card can dispatch on it for icons
/// or analytics without reaching back into the typed call.
@immutable
class ToolCallPreview {
  /// Builds a preview. Every text field must be non-empty — an empty
  /// label would render as a tap target with no text, and the executor
  /// should decline to surface such a call to the user in the first
  /// place.
  ToolCallPreview({
    required this.toolName,
    required this.title,
    required this.summary,
    required this.confirmLabel,
    required this.cancelLabel,
    this.isDestructive = false,
  }) {
    if (toolName.isEmpty) {
      throw ArgumentError.value(toolName, 'toolName', 'must be non-empty');
    }
    if (title.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must be non-empty');
    }
    if (summary.isEmpty) {
      throw ArgumentError.value(summary, 'summary', 'must be non-empty');
    }
    if (confirmLabel.isEmpty) {
      throw ArgumentError.value(
        confirmLabel,
        'confirmLabel',
        'must be non-empty',
      );
    }
    if (cancelLabel.isEmpty) {
      throw ArgumentError.value(
        cancelLabel,
        'cancelLabel',
        'must be non-empty',
      );
    }
  }

  /// Name of the proposed tool, as its [ToolCall.name] (e.g. `addTask`).
  /// Kept as a plain [String] so this file does not depend on the typed
  /// schema module — the executor fills it from the real tool call.
  final String toolName;

  /// Short, already-localized card headline (e.g. "Add task" / "הוסף
  /// משימה"). One line.
  final String title;

  /// One-line human summary of what will happen if confirmed (e.g.
  /// "Gym · 09:00–09:25 · 25 min"). The card may truncate past the
  /// available width, but the value itself is not bounded here.
  final String summary;

  /// Label for the primary action button that applies the tool call
  /// (e.g. "Add task", "Start focus").
  final String confirmLabel;

  /// Label for the secondary button that dismisses the card without
  /// writing anything (e.g. "Cancel").
  final String cancelLabel;

  /// True when confirming the action will remove or overwrite existing
  /// user data (e.g. a `moveTask` that drops the previous slot, or a
  /// `replan` that rewrites a day). The card renders the confirm button
  /// with a destructive accent — read it as "paint in red", not "needs
  /// an extra prompt": the tap itself is still the only commit step.
  final bool isDestructive;

  /// Returns a copy with the fields passed overridden. Unset or `null`
  /// fields keep their current values.
  ToolCallPreview copyWith({
    String? toolName,
    String? title,
    String? summary,
    String? confirmLabel,
    String? cancelLabel,
    bool? isDestructive,
  }) {
    return ToolCallPreview(
      toolName: toolName ?? this.toolName,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      confirmLabel: confirmLabel ?? this.confirmLabel,
      cancelLabel: cancelLabel ?? this.cancelLabel,
      isDestructive: isDestructive ?? this.isDestructive,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ToolCallPreview &&
      other.toolName == toolName &&
      other.title == title &&
      other.summary == summary &&
      other.confirmLabel == confirmLabel &&
      other.cancelLabel == cancelLabel &&
      other.isDestructive == isDestructive;

  @override
  int get hashCode => Object.hash(
    toolName,
    title,
    summary,
    confirmLabel,
    cancelLabel,
    isDestructive,
  );

  @override
  String toString() =>
      'ToolCallPreview(tool: $toolName, title: $title'
      '${isDestructive ? ', destructive' : ''})';
}
