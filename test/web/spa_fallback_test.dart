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
/// The JS redirect fixes the in-browser experience, but the HTTP response
/// stays 404 — which the cloud QA sweep rightly flags (#162) and which also
/// breaks crawlers, link previews and caches. So `.github/workflows/
/// deploy-web.yml` also stamps a copy of `build/web/index.html` into
/// `build/web/<route>/` for every static top-level route, so Pages serves
/// HTTP 200 for them. The 404 fallback stays for dynamic routes
/// (`/task/:id`, `/goals/:id`).
///
/// These tests pin the wiring — the base path both sides use, the load
/// order of the decoder, that it stays external so the CSP in
/// `index.html` keeps working without `'unsafe-inline'`, and that the
/// per-route stamp list matches the top-level static GoRoute paths in
/// `lib/app/router.dart`.
void main() {
  final indexHtml = File('web/index.html').readAsStringSync();
  final notFoundHtml = File('web/404.html').readAsStringSync();
  final decoderJs = File('web/spa_redirect.js').readAsStringSync();
  final deployYml = File('.github/workflows/deploy-web.yml').readAsStringSync();
  final routerDart = File('lib/app/router.dart').readAsStringSync();

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
    //
    // Scan only `run:` lines (not `#`-prefixed comments) so prose like
    // "# TODO: custom domain would change --base-href to /" cannot steal
    // the match and let a real base-href change slip past (#164).
    final runLines = deployYml
        .split('\n')
        .map((l) => l.trimLeft())
        .where((l) => l.startsWith('- run:') || l.startsWith('run:'));
    final baseHref = runLines
        .map((l) => RegExp(r'--base-href\s+(\S+)').firstMatch(l))
        .firstWhere((m) => m != null, orElse: () => null);
    expect(
      baseHref,
      isNotNull,
      reason:
          'No `--base-href <value>` found in any run: line of deploy-web.yml',
    );
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

  test('per-route stamp list in deploy-web.yml matches the static top-level '
      'go_router paths in router.dart', () {
    // Reads the `for route in …; do` list out of deploy-web.yml's SPA-stamp
    // step. Keep the loop a single-line `for route in a b c; do` form so
    // this regex finds it.
    final stampMatch = RegExp(
      r'for\s+route\s+in\s+([^;]+?);\s*do',
    ).firstMatch(deployYml);
    expect(
      stampMatch,
      isNotNull,
      reason:
          'Could not find the per-route stamp loop in deploy-web.yml — '
          'did the step name or shell syntax change?',
    );
    final stampRoutes = stampMatch!
        .group(1)!
        .trim()
        .split(RegExp(r'\s+'))
        .toSet();

    // Pull every `GoRoute(path: '/<name>', …)` from router.dart whose path is
    // a single flat segment (so `/today`, `/settings`), skipping nested
    // routes (which appear as `path: ':id'` inside a parent's `routes: [
    // … ]`) and dynamic top-level routes (`/task/:id`), which can't be
    // enumerated at build time and keep relying on the 404.html fallback.
    final routerRoutes = RegExp(r"GoRoute\(\s*path:\s*'/([a-z]+)'")
        .allMatches(routerDart)
        .map((m) => m.group(1)!)
        .where((r) => r != 'onboarding') // first-run flow, not a QA route
        .toSet();

    expect(
      stampRoutes,
      equals(routerRoutes),
      reason:
          'The per-route stamp list in deploy-web.yml must match the static '
          'top-level routes in lib/app/router.dart so every route the cloud '
          'QA sweep hits (#162) gets a build/web/<route>/index.html on Pages.',
    );
  });
}
