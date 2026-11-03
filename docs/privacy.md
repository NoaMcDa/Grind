# Privacy

Plain language, and the source of truth for the privacy copy in the app
(Settings, About, Privacy). If the app changes what it does, change this page
first.

## The short version

- Your tasks, plans, goals, focus sessions and settings live on your device
  (a database on iPhone, the browser's storage on the web). There is no Grind
  account and no Grind server.
- Grind has no analytics, no advertising and no crash reporting service.
- Grind only talks to Google if you connect Google Calendar. Apple Calendar
  is read on the device through the system calendar permission and never
  leaves it.

## Google Calendar (only when you connect it)

What is read: the events of the calendars you tick in Settings, from a week
back to a month ahead, so Pip can plan around them. Titles and times are kept
in a local copy so the planner works offline.

What is written: only tasks you schedule, as events in your primary calendar
("Planned with Grind"). Grind changes or removes those events when you move or
remove the task. It does not touch other events.

Where the access token lives: Grind never stores your Google password or a
long-lived token itself. On iPhone, Google's sign-in SDK keeps its
authorization in the Keychain. On the web, the access token lives in memory
for the browser session only, so after a reload you are asked to connect
again.

What Grind stores about the connection: a "connected" flag, a sync token per
calendar and the local copy of the events (Keychain on iPhone, browser
`localStorage` on the web). The scopes asked for are
`calendar.events` and `calendar.readonly`.

Disconnect any time in Settings: this signs out, revokes access where Google
allows it, and removes the sync state and the local copy of the events.

## Things worth knowing

- **Web build:** the page loads Google's sign-in script from
  `accounts.google.com`, and the browser fetches a fallback font from
  `fonts.gstatic.com` for characters the bundled fonts lack (no personal data
  is sent with either). A Content-Security-Policy in `web/index.html` limits
  the page to those hosts and `www.googleapis.com`.
- **Backups** are files you export and keep. They include the mirrored
  calendar events (for example meeting titles). Share them with care.
- **Delete all data** removes everything Grind holds on the device and also
  disconnects Google and Apple calendars and clears their sync state. It does
  not delete events in your calendars. Restoring a backup does the same
  disconnect, because the sync state belongs to the data it replaces.
- **Notifications** are scheduled on the device by the operating system.

## Questions

Open an issue on the repository.
