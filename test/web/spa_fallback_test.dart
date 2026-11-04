import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GitHub Pages is a static host, so a deep link like `/Grind/today` returns
/// 404 and Flutter never boots (issue #100, console symptom #101). The SPA
/// fallback is split across three files in `web/`: `404.html` catches the
/// 404, encodes the requested path into the query string of a URL that DOES
/// exist, and redirects there; `spa_redirect.js` is the decoder that runs
/// before `flutter_bootstrap.js` and restores the original path with
/// `history.replaceState` so go_router sees the real route.
///
/// These tests pin the wiring — the base path both sides use, the load
/// order of the decoder, and that it stays external so the CSP in
/// `index.html` keeps working without `'unsafe-inline'`.
void main() {
  final indexHtml = File('web/index.html').readAsStringSync();
  final notFoundHtml = File('web/404.html').readAsStringSync();
  final decoderJs = File('web/spa_redirect.js').readAsStringSync();
  final deployYml = File('.github/workflows/deploy-web.yml').readAsStringSync();

  test('404.html exists so GitHub Pages serves it on unknown paths', () {
    expect(notFoundHtml, isNotEmpty);
  });

  test('404.html redirects by rewriting the URL in-place', () {
    // location.replace, not assign, so the broken URL does not land in
    // browser history.
    expect(notFoundHtml, contains('l.replace('));
  });

  test('pathSegmentsToKeep matches the --base-href from deploy-web.yml', () {
    // The encoder keeps N leading path segments as the app's base. One
    // segment == `/Grind/`. If the deploy workflow ever changes its
    // --base-href, this test fails so the 404 fallback is updated too.
    final baseHref = RegExp(r'--base-href\s+(\S+)').firstMatch(deployYml);
    expect(baseHref, isNotNull);
    final segments = baseHref!
        .group(1)!
        .split('/')
        .where((s) => s.isNotEmpty)
        .length;
    final keep = RegExp(
      r'pathSegmentsToKeep\s*=\s*(\d+)',
    ).firstMatch(notFoundHtml);
    expect(keep, isNotNull);
    expect(int.parse(keep!.group(1)!), segments);
  });

  test('decoder script runs before flutter_bootstrap.js', () {
    final decoderIdx = indexHtml.indexOf('src="spa_redirect.js"');
    final bootIdx = indexHtml.indexOf('src="flutter_bootstrap.js"');
    expect(decoderIdx, greaterThan(-1));
    expect(bootIdx, greaterThan(-1));
    expect(decoderIdx, lessThan(bootIdx));
  });

  test('decoder restores the path with history.replaceState', () {
    // Encoder puts the path into `?/<path>` in the query string; the
    // decoder has to pull it back out before go_router reads window.location.
    expect(decoderJs, contains('history.replaceState'));
    expect(decoderJs, contains("search[1] === '/'"));
  });

  test(
    'decoder stays external so the CSP in index.html does not need unsafe-inline',
    () {
      // CSP in index.html is `script-src 'self' 'wasm-unsafe-eval'
      // https://accounts.google.com` — an inline <script> block for the
      // decoder would require 'unsafe-inline', which csp_test.dart forbids.
      final inline = RegExp(
        r'<script(?![^>]*\bsrc=)[^>]*>[\s\S]*?</script>',
      ).allMatches(indexHtml);
      expect(inline, isEmpty);
    },
  );
}
