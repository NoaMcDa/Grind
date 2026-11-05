/// A pure-Dart classifier for the web origin the app is being served
/// from, for epic #49 ("web deployment: hosting, CI deploy, domain").
///
/// The epic's scope commits to two shipping shapes:
///   * production on a fixed host (today `noamcda.github.io/Grind/`, later
///     a custom domain), and
///   * per-PR preview URLs on a preview host (Cloudflare Pages, Vercel,
///     Netlify or Firebase Hosting, pending #49's hosting decision).
///
/// A handful of call sites will need to know which one they are on:
///   * the OAuth redirect URI check for Google Calendar (#13) — only
///     register a redirect for production and preview, never for a host
///     we do not recognise;
///   * the analytics sink (`analytics_sink.dart`) — tag events with a
///     channel so prod traffic is not polluted by local or preview runs;
///   * error reporting — drop (or demote) reports from local and
///     `unknown` origins.
///
/// This file gives them one place to ask, with one answer, and ships
/// with no dependencies on `dart:html` or `dart:io` so it unit-tests
/// cleanly in a VM test on CI (no Flutter web build required, matching
/// the slice convention in this epic — see
/// `lib/core/services/analytics_sink.dart`).
///
/// Nothing here runs on its own; a caller feeds in the URI (on web, that
/// is `Uri.base`) and reads back a [DeploymentOrigin].
library;

/// Which deploy channel the current web origin is served from.
///
/// The names are the three shapes the epic #49 scope commits to, plus
/// [DeploymentChannel.unknown] for a host we have not opted in to on
/// purpose — the classifier is conservative so a leaked preview URL on a
/// typoed subdomain does not pose as production.
enum DeploymentChannel {
  /// A canonical production host (today `noamcda.github.io`; a future
  /// custom domain is added by passing [DeploymentOrigin.fromUri] a
  /// larger `productionHosts` set).
  production,

  /// A per-PR preview on a known preview platform
  /// (`*.pages.dev`, `*.vercel.app`, `*.netlify.app`, Firebase Hosting).
  preview,

  /// `flutter run -d chrome` or a devtools run on the developer's
  /// machine: `localhost`, `127.0.0.1`, `::1`, `0.0.0.0`, or `file://`.
  local,

  /// Anything the classifier does not recognise — a hand-opened artifact
  /// link, a mirrored copy on an unexpected host, or a non-HTTP scheme.
  unknown,
}

/// A value object describing the web origin the app is being served from
/// and the deploy channel it belongs to.
///
/// Immutable and equality-comparable so tests can `expect(origin,
/// DeploymentOrigin.local)` without hand-rolling a matcher.
class DeploymentOrigin {
  const DeploymentOrigin._({
    required this.channel,
    required this.host,
    required this.scheme,
  });

  /// Classify an arbitrary [uri] — the web embedding passes `Uri.base`,
  /// tests pass whatever is convenient.
  ///
  /// [productionHosts] names the hosts (case-insensitive) that count as
  /// [DeploymentChannel.production]. Defaults to [defaultProductionHosts],
  /// the Grind host set that is live today. Add a custom domain here
  /// when that work lands (#49) rather than editing this file.
  ///
  /// The rules, in the order they fire (first match wins):
  ///
  ///   1. Scheme `file` or empty host → [DeploymentChannel.local].
  ///   2. Host is `localhost`, `127.0.0.1`, `::1` or `0.0.0.0` →
  ///      [DeploymentChannel.local]. The port is ignored on purpose:
  ///      `localhost:5000` and `localhost:5555` are both local.
  ///   3. Host is in [productionHosts] (case-insensitive) →
  ///      [DeploymentChannel.production].
  ///   4. Host matches a known preview-platform pattern →
  ///      [DeploymentChannel.preview]. See [_looksLikePreviewHost] for
  ///      the exact list.
  ///   5. Everything else → [DeploymentChannel.unknown]. Conservative
  ///      on purpose: an unexpected host is never promoted to production.
  factory DeploymentOrigin.fromUri(
    Uri uri, {
    Set<String> productionHosts = defaultProductionHosts,
  }) {
    final rawScheme = uri.scheme.toLowerCase();
    final rawHost = uri.host.toLowerCase();

    // (1) file:// or no host at all → always local.
    if (rawScheme == 'file' || rawHost.isEmpty) {
      return DeploymentOrigin._(
        channel: DeploymentChannel.local,
        host: rawHost,
        scheme: rawScheme,
      );
    }

    // (2) Loopback / localhost.
    if (_looksLikeLocalHost(rawHost)) {
      return DeploymentOrigin._(
        channel: DeploymentChannel.local,
        host: rawHost,
        scheme: rawScheme,
      );
    }

    // Any remaining match must speak HTTP; a scheme like `ftp` or `ssh`
    // against a production-shaped host is not a real deploy and the
    // classifier refuses to promote it. On web `Uri.base` is always
    // http(s), so this only guards hand-constructed URIs.
    if (rawScheme != 'http' && rawScheme != 'https') {
      return DeploymentOrigin._(
        channel: DeploymentChannel.unknown,
        host: rawHost,
        scheme: rawScheme,
      );
    }

    // (3) Production: exact match against the configured host set.
    final productionLower = productionHosts.map((h) => h.toLowerCase()).toSet();
    if (productionLower.contains(rawHost)) {
      return DeploymentOrigin._(
        channel: DeploymentChannel.production,
        host: rawHost,
        scheme: rawScheme,
      );
    }

    // (4) Known preview platforms.
    if (_looksLikePreviewHost(rawHost)) {
      return DeploymentOrigin._(
        channel: DeploymentChannel.preview,
        host: rawHost,
        scheme: rawScheme,
      );
    }

    // (5) Nothing matched; stay conservative.
    return DeploymentOrigin._(
      channel: DeploymentChannel.unknown,
      host: rawHost,
      scheme: rawScheme,
    );
  }

  /// The channel [uri] was classified into.
  final DeploymentChannel channel;

  /// The lower-cased host component, or `''` for a `file://` URI.
  /// Carried on the value object so logs and analytics tags do not have
  /// to re-parse the URI.
  final String host;

  /// The lower-cased scheme component (`http`, `https`, `file`, …).
  final String scheme;

  /// Shorthand: true iff [channel] is [DeploymentChannel.production].
  bool get isProduction => channel == DeploymentChannel.production;

  /// Shorthand: true iff [channel] is [DeploymentChannel.preview].
  bool get isPreview => channel == DeploymentChannel.preview;

  /// Shorthand: true iff [channel] is [DeploymentChannel.local].
  bool get isLocal => channel == DeploymentChannel.local;

  /// The hosts Grind serves production from today. Expanded by passing a
  /// larger set to [DeploymentOrigin.fromUri]; a custom domain lands in
  /// here once the epic #49 hosting decision is made.
  static const Set<String> defaultProductionHosts = {'noamcda.github.io'};

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeploymentOrigin &&
          channel == other.channel &&
          host == other.host &&
          scheme == other.scheme;

  @override
  int get hashCode => Object.hash(channel, host, scheme);

  @override
  String toString() =>
      'DeploymentOrigin(${channel.name}, scheme: $scheme, host: $host)';
}

/// A host counts as the developer's machine when it is one of the common
/// loopback spellings. Port is intentionally ignored — Flutter picks a
/// different one per `flutter run` and the classification should not
/// drift with it.
bool _looksLikeLocalHost(String host) {
  return host == 'localhost' ||
      host == '127.0.0.1' ||
      host == '::1' ||
      host == '[::1]' ||
      host == '0.0.0.0';
}

/// Suffixes and prefixes that uniquely identify a preview platform.
///
/// Explicit list rather than a regex because each entry must be
/// deliberately opted into; a typo on a production custom domain should
/// never accidentally match a preview pattern and demote the user's
/// traffic.
///
/// Kept in sync with the hosting options the epic #49 scope names:
///   * `.pages.dev`          — Cloudflare Pages per-branch URLs.
///   * `.vercel.app`         — Vercel preview deployments.
///   * `.netlify.app`        — Netlify preview deployments.
///   * `.web.app`
///   * `.firebaseapp.com`    — Firebase Hosting preview channels.
bool _looksLikePreviewHost(String host) {
  const suffixes = <String>[
    '.pages.dev',
    '.vercel.app',
    '.netlify.app',
    '.web.app',
    '.firebaseapp.com',
  ];
  for (final suffix in suffixes) {
    // Require the suffix to follow at least one label so the bare apex
    // (e.g. `pages.dev`) is not itself called a preview.
    if (host.length > suffix.length && host.endsWith(suffix)) {
      return true;
    }
  }
  return false;
}
