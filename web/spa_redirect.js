// SPA deep-link fallback for GitHub Pages — decoder half.
//
// WHY: GitHub Pages is a static host. It only serves files that exist on
// disk, so a deep link like `/Grind/today` returns 404 (there is no
// `/Grind/today/index.html`) and Flutter never loads. The paired encoder in
// `web/404.html` catches that 404 and rewrites the URL to
// `/Grind/?/today` — a path that DOES exist, which boots Flutter.
//
// This snippet is the decoder: it runs before `flutter_bootstrap.js` and
// restores the original path with `history.replaceState` so go_router sees
// `/today` instead of `/?/today`.
//
// Lifted from https://github.com/rafgraph/spa-github-pages (MIT). Keep in
// sync with the encoder in `web/404.html`. Loaded from an external file,
// not inlined, so it stays under `script-src 'self'` in the CSP in
// `web/index.html`.
(function (l) {
  if (l.search[1] === '/') {
    var decoded = l.search
      .slice(1)
      .split('&')
      .map(function (s) { return s.replace(/~and~/g, '&'); })
      .join('?');
    window.history.replaceState(
      null,
      null,
      l.pathname.slice(0, -1) + decoded + l.hash,
    );
  }
})(window.location);
