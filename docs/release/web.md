# Web deployment (issues #49 and #47 PWA part)

Workflow: `.github/workflows/deploy-web.yml` builds `main` and deploys it to GitHub Pages.

## GitHub Pages setup (one time)

1. Repo **Settings > Pages > Build and deployment > Source = "GitHub Actions"**.
2. Optional, for Google Calendar on the web: **Settings > Secrets and variables > Actions > Variables**, add a repository **variable** (not a secret) `GOOGLE_CLIENT_ID_WEB` with the OAuth web client id. The workflow passes it as `--dart-define`. Without it Google Calendar shows a setup hint and everything else works. In Google Cloud Console add the Pages origin (`https://<owner>.github.io`) as an authorised JavaScript origin.
3. Push to `main` (or run the workflow manually). The site is at `https://<owner>.github.io/Grind/`.

## Custom domain

Add the domain under Settings > Pages and the DNS records GitHub lists. A custom domain serves from the root, so change the build flag in `deploy-web.yml` from `--base-href /Grind/` to `--base-href /`. Also update the authorised origin for the Google client id. Do not leave the old base href: assets and the service worker would 404.

## Hosting notes

- **`.wasm` MIME type**: `sqlite3.wasm` (drift on web) must be served as `application/wasm`; otherwise streaming compilation fails. GitHub Pages does this correctly. On other hosts (nginx, S3, Apache) add the mapping explicitly.
- `drift_worker.js` and `sqlite3.wasm` live in `web/` and are copied verbatim into the build. Keep their versions in step with the drift and sqlite3 packages.
- No special headers (COOP/COEP) are required by the current build.
- **Caching**: `flutter_service_worker.js` is what makes updates work. The browser re-fetches it on each visit (Pages sends short cache lifetimes, around 10 minutes), the new worker installs in the background, and the new version appears on the **next reload or launch** after that. Installed PWAs may need to be closed and reopened. If you move to another host, serve `flutter_service_worker.js` and `index.html` with `Cache-Control: no-cache`; hashed assets may be cached long.
- Per-PR previews are not possible on Pages without extra hosting (see the TODO in the workflow).

## PWA install (issue #47, install experience only)

Icons referenced by `web/manifest.json` all exist at the declared sizes: `icons/Icon-192.png`, `Icon-512.png`, `Icon-maskable-192.png`, `Icon-maskable-512.png` (Pip sits inside the maskable safe zone, about 52 percent of the canvas). `web/favicon.png` is 48 px.

An iOS home-screen icon is added at `web/icons/apple-touch-icon.png` (180x180). Safari ignores the manifest icons, so `web/index.html` needs this line in `<head>` (not added by this change; `index.html` is owned by another branch):

```html
<link rel="apple-touch-icon" href="icons/apple-touch-icon.png">
```

(Check whether `index.html` already has a `<link rel="apple-touch-icon" ...>` pointing at `icons/Icon-192.png`, as the Flutter template does; if so, change its `href`.)

The manifest also lists two shortcuts, `Plan my day` and `Focus now`. Chrome and Edge surface them on long-press of the installed PWA (`./today`, `./focus`); iOS ignores them.

Still open for #47: web push needs a push service and server, and is out of scope here. [docs/web/push-limits.md](../web/push-limits.md) is the reference for which browsers can deliver it, the iOS 16.4+ installed-PWA requirement and the Settings copy to show when push is not available.
