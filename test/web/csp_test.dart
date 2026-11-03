import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The Content-Security-Policy in `web/index.html` is the only thing between
/// a compromised third-party script and the user's local data (see
/// `docs/privacy.md`). These tests pin what it may talk to, so widening it
/// has to be a deliberate edit of this file too.
void main() {
  final html = File('web/index.html').readAsStringSync();
  final meta = RegExp(
    r'<meta http-equiv="Content-Security-Policy" content="([^"]*)"',
  ).firstMatch(html);

  Map<String, List<String>> directives() {
    final out = <String, List<String>>{};
    for (final d in meta!.group(1)!.split(';')) {
      final parts = d.trim().split(RegExp(r'\s+'));
      if (parts.first.isEmpty) continue;
      out[parts.first] = parts.skip(1).toList();
    }
    return out;
  }

  test('the page carries a CSP meta tag', () {
    expect(meta, isNotNull);
  });

  test('locked-down defaults', () {
    final d = directives();
    expect(d['default-src'], ["'self'"]);
    expect(d['object-src'], ["'none'"]);
    expect(d['base-uri'], ["'self'"]);
    expect(d['form-action'], ["'self'"]);
  });

  test('scripts: self, wasm compile and Google sign-in only', () {
    final scripts = directives()['script-src']!;
    expect(scripts, [
      "'self'",
      "'wasm-unsafe-eval'",
      'https://accounts.google.com',
    ]);
  });

  test('no remote origin beyond Google and the font fallback', () {
    final origins = RegExp(
      r'https?://[^\s;]+',
    ).allMatches(meta!.group(1)!).map((m) => m.group(0)!).toSet();
    expect(origins, {
      'https://accounts.google.com',
      'https://www.googleapis.com',
      // Wave 5 review: only CanvasKit's Roboto fallback needs this one.
      // Remove it (and this line) once Roboto is bundled.
      'https://fonts.gstatic.com',
    });
  });

  test('font hosts are reachable by fetch only, not as scripts or frames', () {
    final d = directives();
    expect(d['connect-src'], contains('https://fonts.gstatic.com'));
    for (final key in ['script-src', 'frame-src', 'style-src', 'img-src']) {
      expect(
        d[key] ?? const <String>[],
        isNot(contains('https://fonts.gstatic.com')),
      );
    }
  });

  test('no inline script in the page shell', () {
    final inline = RegExp(r'<script(?![^>]*\bsrc=)[^>]*>').allMatches(html);
    expect(inline, isEmpty);
  });
}
