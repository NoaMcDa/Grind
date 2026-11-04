# Web push limits (issue #47)

Context on what the browser lets Grind do with reminders when the tab is
closed, so the Settings copy and `WebNotificationService` degrade in a way the
user can understand. Kept in step with
[ADR 0003](../adr/0003-notifications.md) and the open items in
[docs/release/web.md](../release/web.md).

## What "web push" means here

The local browser Notification API (`new Notification(...)`) fires only while
the tab is open: it is what `WebNotificationService` uses today
(ADR 0003, section 6). For a reminder to fire with the tab closed or the
device asleep, the page needs:

1. A service worker that calls `registration.showNotification(...)` in its
   `push` event.
2. A push subscription from `PushManager.subscribe({ userVisibleOnly: true,
   applicationServerKey: <VAPID public key> })`, stored by a server that
   signs each send with the matching VAPID private key and posts to the
   endpoint the subscription carries (one of `fcm.googleapis.com`,
   `web.push.apple.com`, Mozilla's autopush, etc.).

Neither piece ships yet. This page is the reference for when they do.

## Browser support

Numbers are as of late 2026; re-check against
[caniuse.com/push-api](https://caniuse.com/push-api) and
[caniuse.com/notifications](https://caniuse.com/notifications) before
promising anything to users.

| Browser                          | Push + background notifications | Notes |
| -------------------------------- | ------------------------------- | ----- |
| Chrome / Edge (desktop + Android)| Yes                             | Full `PushManager` + action buttons. |
| Firefox (desktop + Android)      | Yes                             | Full `PushManager` + action buttons. |
| Safari macOS 13+                 | Yes                             | Standard Web Push (VAPID); works for ordinary tabs since 16.1. |
| **Safari iOS / iPadOS**          | **Only in a PWA added to the Home Screen, iOS 16.4+** | A regular Safari tab cannot subscribe. See below. |
| Safari iOS < 16.4                | No                              | No `PushManager` at all. |
| In-app browsers (Gmail, Slack, Meta WebView, etc.) | No | Usually no `serviceWorker` or no `PushManager`. |
| Private / Incognito              | Permission is auto-denied in most browsers | Plan for `Notification.permission === 'denied'`. |

### iOS Safari specifics

- Push on iOS and iPadOS requires the user to **Share > Add to Home Screen**
  first, then open the icon from the Home Screen. In the standalone PWA,
  `'PushManager' in window` becomes true and the permission prompt can be
  requested from a user gesture.
- The install needs the manifest's `display` to be `standalone` or
  `fullscreen` (ours is `standalone`, `web/manifest.json`) and the page to
  be served over HTTPS. GitHub Pages satisfies this.
- There is no `beforeinstallprompt` on iOS: the only install path is the
  user tapping Share > Add to Home Screen. The Settings install prompt has
  to show those instructions, not a button.
- Action buttons on notifications are **not** supported in Safari (iOS or
  macOS) at the time of writing. Any `actions` passed to
  `showNotification` are ignored. The notification click must open the app
  to a deep link that lets the user finish the action.
- Silent / data-only pushes are not allowed: every `push` event must call
  `showNotification`. If the server sends a silent push the system may
  revoke the subscription after a few misses.
- The permission can only be requested from a user gesture (tap on a
  button, not on page load).

### Chrome / Firefox specifics

- Action buttons are supported; use at most two, with short labels
  (`Done`, `Snooze 15`) that mirror the iOS set from ADR 0003.
- Chrome on Android requires Google Play Services (always present on
  Google-certified devices, not on AOSP builds like FireOS).
- Firefox uses Mozilla's autopush endpoint, not FCM: the server side must
  accept any endpoint the subscription returns, not hardcode FCM.

## Capability detection

`PushManager` and `serviceWorker` can both be undefined, and even when they
exist `pushManager.subscribe()` can throw. Check in this order from Dart
(via `package:web` or `dart:js_interop`) and cache the result per session:

1. `window.navigator.serviceWorker` exists.
2. `'PushManager' in window`.
3. On iOS user agents, additionally `window.matchMedia('(display-mode:
   standalone)').matches` or `navigator.standalone === true`. If false, the
   page is a regular tab: push cannot be subscribed, even on 16.4+.
4. `Notification.permission` is not `'denied'`.

If 1 to 3 pass, offer the enable button. If 4 is `'denied'`, link to the
browser's site-permission page instead of re-prompting.

## User-visible copy

Settings > Reminders shows one of these based on the capability check. The
tone follows `docs/tone-guide.md` (plain, kind, no scolding). English and
Hebrew strings go in the `.arb` files when the Dart code lands.

### Push works here

> Keep reminders on when the tab is closed.
>
> _[Turn on reminders]_

After the permission is granted:

> Reminders will reach you even when Grind isn't open. Tap a reminder to
> jump back into the day.

### Push would work after installing

Shown on iOS Safari 16.4+ in a regular tab:

> To get reminders when Grind is closed, add it to your Home Screen first.
>
> Tap the Share button, then **Add to Home Screen**. Open Grind from the
> new icon and come back here to turn reminders on.

### Push is not supported by this browser

Shown when `PushManager` is missing, or on iOS < 16.4, or in a private
window:

> This browser can only show reminders while Grind is open in a tab. Your
> reminders still work on time inside the app, and on iPhone or Android if
> you install Grind.
>
> _[What this means]_ links to this page.

### Permission was denied

> Reminders are off for this site. Turn them on in your browser's site
> settings, then reload Grind.
>
> _[How to change it]_ links to the browser's help page (Chrome: Site
> Settings; Firefox: Permissions; Safari: Settings > Websites >
> Notifications).

## What to show on the Today card

`ReminderNowCard` and the local `WebNotificationService` already work for
the open-tab case. When the capability check fails, the Today card is the
fallback: it is the only reliable way to surface a reminder at the right
time in a browser that will not deliver it in the background. The card copy
already reads naturally for this (ADR 0003, section 4), so no extra string
is needed; only the Settings toggle changes.

## Not supported yet

These need the server side to ship before they can move off this page:

- The VAPID keypair and the subscription endpoint. The public half goes in
  as a `--dart-define` so the web build can carry it; the private half
  stays in the server's secret store and never reaches the client.
- The cron that mirrors `NotificationScheduler.plan`'s 7-day window on the
  server and sends pushes at `fireAt` for each stored subscription.
- Service-worker `notificationclick` handling that deep-links back into
  Grind (`/task/<id>`, `/focus?taskId=`), and action buttons on the
  browsers that support them.
- The Settings toggle, the capability-check gated install hint and the
  permission flow described above.

Issues #4, #5 and #11 cover the local pieces this depends on and have
already landed.
