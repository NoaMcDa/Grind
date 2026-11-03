# ADR 0004: Design system, localization and accessibility baseline

Status: accepted (issue #6)

## Decisions
- Components live in `lib/widgets` (barrel: `widgets.dart`), tokens in `lib/theme`. `lib/widgets/gallery/widget_gallery.dart` shows every component in its states for review (not routed).
- Strings come from ARB files in `lib/l10n` (`app_en.arb` template, `app_he.arb`). Generated Dart is committed because `pubspec.yaml` is integrator-owned; the integrator must add `generate: true` under `flutter:` so regeneration works. `context.l10n` is the accessor.
- Text scale is clamped to 1.3 with `TextScaleClamp` (`lib/theme/text_scale.dart`), wrapped around the app by the integrator (`MaterialApp.builder`).
- Directional geometry: widgets use `EdgeInsetsDirectional`, `AlignmentDirectional`, `BorderDirectional`. The hard "sticker" shadow stays at the bottom-right in both directions on purpose: it reads as a light source, not as reading direction, and mirroring it would change the character of the look.
- Hit targets: `PillButton` keeps its visual height but its tap area is at least 44 px. Text fields have a 44 px minimum height.
- Semantics: buttons expose button/enabled/label (`excludeSemantics` so the inner text is not read twice), `SectionLabel` is a header, `MomentumMeter` has label and percent value, `PipAvatar` is an image, `IconChip` carries meaning in both icon and text (never colour alone), toasts are live regions, `SkeletonBox` announces "Loading". Decorative drawing (the confetti painter in the Pip screen, which is owned by another agent) has no semantics because a childless `CustomPaint` adds none.
- Motion: skeletons are static (no shimmer).

## Contrast (WCAG 2.x relative luminance, AA needs 4.5:1 for text)
| Text on background | Ratio |
|---|---|
| ink on white card | 17.74 |
| ink on ground F5F2FF | 16.07 |
| ink on sun | 11.47 |
| ink on sky | 9.80 |
| ink on mint | 8.08 |
| ink on pink | 7.32 |
| ink on lilac | 14.95 |
| white on violet | 6.12 |
| muted on ground / on card | 6.40 / 7.06 |
| error (B3261E) on card | 6.54 |
| violetDark on card (toast action) | 9.40 |

Rule: only ink on sun/mint/sky/pink, only white on violet. White on mint/sky/pink/sun fails and must not be used. The hour-rule colour (1.27 on ground) is decorative, not text. `test/theme/theme_l10n_test.dart` enforces these ratios.

## Fonts and Hebrew
Bundled DM Sans and Bricolage Grotesque have no Hebrew glyphs, so Hebrew currently falls back to the platform font. Recommendation: add an OFL Hebrew family (Heebo, or Assistant) to `assets/fonts` and `pubspec.yaml`, with its OFL text, and set `fontFamilyFallback: ['Heebo']` in `AppText` and `buildAppTheme`. Layouts use no fixed-width text boxes, so they hold with any fallback; the gallery test runs Hebrew at the 1.3 scale cap with no overflow.

## Hebrew copy
Written natively in Pip's tone: encouraging, no guilt, gender-neutral plural imperatives. Have a native speaker review it before release.
