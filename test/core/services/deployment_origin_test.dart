import 'package:flutter_test/flutter_test.dart';
import 'package:grind/core/core.dart';

void main() {
  group('DeploymentOrigin.fromUri — local', () {
    test('localhost with a port classifies as local', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('http://localhost:5000/'),
      );
      expect(origin.channel, DeploymentChannel.local);
      expect(origin.isLocal, isTrue);
      expect(origin.host, 'localhost');
      expect(origin.scheme, 'http');
    });

    test('127.0.0.1 classifies as local', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('http://127.0.0.1:8080/today'),
      );
      expect(origin.channel, DeploymentChannel.local);
    });

    test('::1 classifies as local', () {
      final origin = DeploymentOrigin.fromUri(Uri.parse('http://[::1]:5000/'));
      // Uri strips the brackets from host; the classifier handles both.
      expect(origin.channel, DeploymentChannel.local);
    });

    test('0.0.0.0 classifies as local', () {
      final origin = DeploymentOrigin.fromUri(Uri.parse('http://0.0.0.0:80/'));
      expect(origin.channel, DeploymentChannel.local);
    });

    test('file:// classifies as local even with no host', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('file:///Users/me/build/web/index.html'),
      );
      expect(origin.channel, DeploymentChannel.local);
      expect(origin.scheme, 'file');
    });

    test('port does not change the classification', () {
      final a = DeploymentOrigin.fromUri(Uri.parse('http://localhost:5000/'));
      final b = DeploymentOrigin.fromUri(Uri.parse('http://localhost:5555/'));
      expect(a.channel, DeploymentChannel.local);
      expect(b.channel, DeploymentChannel.local);
    });
  });

  group('DeploymentOrigin.fromUri — production', () {
    test('noamcda.github.io is production by default', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://noamcda.github.io/Grind/'),
      );
      expect(origin.channel, DeploymentChannel.production);
      expect(origin.isProduction, isTrue);
      expect(origin.host, 'noamcda.github.io');
      expect(origin.scheme, 'https');
    });

    test('mixed-case host is lower-cased before matching', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://NoamCDA.GitHub.IO/Grind/today'),
      );
      expect(origin.channel, DeploymentChannel.production);
      expect(origin.host, 'noamcda.github.io');
    });

    test('custom production host set in via productionHosts', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://grind.app/'),
        productionHosts: const {'grind.app'},
      );
      expect(origin.channel, DeploymentChannel.production);
    });

    test('production set override excludes the default', () {
      // Passing an explicit set means the default github.io host is NOT
      // treated as production, which is the behaviour an epic consumer
      // wants after moving to a custom domain.
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://noamcda.github.io/Grind/'),
        productionHosts: const {'grind.app'},
      );
      expect(origin.channel, DeploymentChannel.unknown);
    });
  });

  group('DeploymentOrigin.fromUri — preview', () {
    test('Cloudflare Pages preview subdomain classifies as preview', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://pr-42.grind.pages.dev/today'),
      );
      expect(origin.channel, DeploymentChannel.preview);
      expect(origin.isPreview, isTrue);
    });

    test('Vercel preview subdomain classifies as preview', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://grind-git-feat-foo.vercel.app/'),
      );
      expect(origin.channel, DeploymentChannel.preview);
    });

    test('Netlify preview subdomain classifies as preview', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://deploy-preview-42--grind.netlify.app/'),
      );
      expect(origin.channel, DeploymentChannel.preview);
    });

    test('Firebase Hosting web.app subdomain classifies as preview', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://grind--pr-12-abc.web.app/'),
      );
      expect(origin.channel, DeploymentChannel.preview);
    });

    test('firebaseapp.com subdomain classifies as preview', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://grind-preview.firebaseapp.com/'),
      );
      expect(origin.channel, DeploymentChannel.preview);
    });

    test('bare pages.dev apex is NOT itself a preview', () {
      // The suffix list requires at least one label before it so the
      // apex domain of a preview platform does not match on its own.
      final origin = DeploymentOrigin.fromUri(Uri.parse('https://pages.dev/'));
      expect(origin.channel, DeploymentChannel.unknown);
    });
  });

  group('DeploymentOrigin.fromUri — unknown', () {
    test('a stranger host with https is unknown, not production', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://evil.example.com/'),
      );
      expect(origin.channel, DeploymentChannel.unknown);
      expect(origin.isProduction, isFalse);
      expect(origin.isPreview, isFalse);
      expect(origin.isLocal, isFalse);
    });

    test('a non-http scheme against a production host is unknown', () {
      // Belt and braces: the classifier refuses to promote a weird
      // scheme (`ftp`, `ssh`, …) to production even when the host would
      // otherwise match the production set.
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('ftp://noamcda.github.io/Grind/'),
      );
      expect(origin.channel, DeploymentChannel.unknown);
      expect(origin.scheme, 'ftp');
    });

    test('data: URIs have no host and fall through to local', () {
      // A data: URI is not a deploy at all; the local branch catches it
      // via the empty-host rule so callers never see unknown for it.
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('data:text/html,<h1>hi</h1>'),
      );
      expect(origin.channel, DeploymentChannel.local);
      expect(origin.host, isEmpty);
    });
  });

  group('DeploymentOrigin — value semantics', () {
    test('two origins from the same URI compare equal', () {
      final a = DeploymentOrigin.fromUri(
        Uri.parse('https://noamcda.github.io/Grind/today'),
      );
      final b = DeploymentOrigin.fromUri(
        Uri.parse('https://noamcda.github.io/Grind/plan'),
      );
      // Path is ignored on purpose — channel/host/scheme is the identity.
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('different channels are not equal', () {
      final prod = DeploymentOrigin.fromUri(
        Uri.parse('https://noamcda.github.io/Grind/'),
      );
      final local = DeploymentOrigin.fromUri(
        Uri.parse('http://localhost:5000/'),
      );
      expect(prod, isNot(equals(local)));
    });

    test('toString names the channel for easy test output', () {
      final origin = DeploymentOrigin.fromUri(
        Uri.parse('https://noamcda.github.io/Grind/'),
      );
      expect(origin.toString(), contains('production'));
      expect(origin.toString(), contains('noamcda.github.io'));
    });
  });
}
