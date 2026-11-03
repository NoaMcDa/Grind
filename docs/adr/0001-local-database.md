# ADR 0001: Local database

- Status: accepted
- Date: 2026-11-03
- Issue: #2

## Context

Grind is a pure client: no backend, no account (decision of 3 Nov 2026). The
device's local storage is the permanent home of the user's tasks, reminders,
calendar mirror and preferences, on iOS and in the browser. The layer must:

- work offline on iOS and on web from one Dart code base;
- answer range queries cheaply ("reminders in the next 7 days", "events
  overlapping this day") for the scheduler and the notification scheduler;
- support schema migrations over the life of the app;
- export and import the whole store (the only "sync" and the only recovery).

## Decision

**Drift** (typed SQL on sqlite3) in `lib/core/data/`.

- `database.dart`: `AppDatabase`, tables `tasks`, `reminder_rules`,
  `calendar_events`, `focus_sessions`, `goals`, `preferences` (one row).
  Every row has `id` (text UUID, primary key), `created_at`, `updated_at`,
  `deleted_at` (soft delete). Times are **UTC milliseconds since the epoch**
  (integer columns); enums are stored by name; the preference maps/lists of
  `TimeRange` are JSON text. Foreign keys are on (`PRAGMA foreign_keys` in
  `beforeOpen`): `reminder_rules.task_id -> tasks` (cascade) and
  `focus_sessions.task_id -> tasks` (set null). Calendar events and
  `tasks.goal_id` deliberately have no FK (sync may mirror an event before
  its task exists; goals are a stub).
- Repositories `Drift{Task,Reminder,Calendar,Preferences}Repository`
  implement the interfaces in `lib/core/repositories` with the same
  semantics as the `InMemory*` versions (which stay for tests). `watch*`
  uses Drift's query streams. Upserts are SQL `ON CONFLICT DO UPDATE`, never
  `REPLACE`, so a parent row is not deleted-and-reinserted under FKs.
- `connection/`: conditional export. Native: `NativeDatabase.createInBackground`
  on `<documents>/grind.sqlite` (path_provider). Web: `WasmDatabase.open`.
  Tests: `connection/memory.dart` (`NativeDatabase.memory()`, not exported
  from the barrel because it imports `dart:ffi`).
- `providers.dart`: `dataProvidersOverrides(db)` swaps the in-memory defaults
  in `lib/core/di.dart` for the Drift implementations.

### Migrations

`AppDatabase.currentSchemaVersion` is 3 and a test pins it. To change the
schema: bump the version, add an `if (from < N)` step in `onUpgrade`
(`m.addColumn` / `m.createTable`; new non-null columns need a default) and
add a migration test. Never edit an existing step.

`test/core/data/migration_test.dart` keeps the v2 DDL as a string (copied
from `sqlite_master`), creates it in `NativeDatabase.memory(setup: ...)`
with `PRAGMA user_version = 2` and a row per table, opens `AppDatabase`,
and checks that the migrated `PRAGMA table_info` of every table equals a
fresh v3 database and that the old rows read back with the new defaults.
The next version copies the v3 DDL the same way (Drift's
`make-migrations` schema dumps are the heavier alternative).

### Schema history

| Version | Change |
|---|---|
| 1 | `tasks`, `reminder_rules`, `calendar_events`, `focus_sessions`, `goals`, `preferences` (W1-B, #2). |
| 2 | `tasks.not_before`, `tasks.minutes_done`; `preferences.morning_prompt_minutes`, `evening_prompt_minutes`, `selected_calendar_ids` (default `{}`), `backup_hint_shown` (contracts v2). |
| 3 | `reminder_rules.last_completed_at`; `calendar_events.html_link`; `focus_sessions.paused_ms` (default 0), `paused_at`, `win`, `kind` (`focus` / `breakTime`, default `focus`); `goals.target_date`, `status` (`active` / `paused` / `done`, default `active`), `notes`, `metric_kind`, `metric_target`, `metric_unit`, `metric_current`, `metric_source`, `metric_period`; `preferences.pip_accessory` (default `scarf`); new tables `review_entries` (PK `date`, `win`, `done_count`, `moved_count`, `created_at`) and `review_handled_days` (PK `date`) (contracts v3). Quiet hours JSON may now have `end <= start` (crosses midnight, `TimeRange.wrapping`); no column change. |

## Alternatives considered

| Option | Why not |
|---|---|
| **Isar** | Fast and pleasant API, but the original project is unmaintained (community fork only), and the web target has been unreliable. Data that lives only on device needs a storage engine we can trust for years. |
| **Hive** (/ hive_ce) | Key-value boxes, no query language: range queries and joins become hand-written scans; no real migrations; web storage is IndexedDB without transactions across boxes. |
| **sqflite** | SQLite on mobile, but no web support (needs `sqflite_common_ffi_web`, experimental) and untyped string SQL; Drift gives the same SQLite file plus typed queries, streams and migrations. |
| shared_preferences / files | Not a database: no atomic multi-row writes, no queries. |

## Web durability

On web the database is sqlite3 compiled to wasm, run in a worker, storing to
OPFS when available, otherwise IndexedDB (Drift chooses; verified in headless
Chrome: `sharedIndexedDb`, data survived a browser restart).

Browsers may evict that storage:

- Without a persistent-storage grant, origins can be cleared under storage
  pressure. `requestPersistentStorage()` (`web_persistence.dart`, a
  `dart:js_interop` binding to `navigator.storage.persist()`) asks for it;
  it is a no-op returning true on iOS. Chrome grants it heuristically
  (installed PWA, bookmarked, engagement); Firefox prompts; Safari grants it
  to home-screen web apps.
- Safari deletes all script-writable storage of a site not visited for 7
  days unless it is installed to the home screen.

Therefore: call `requestPersistentStorage()` at startup on web, and show a
one-time, friendly hint to export a backup (settings screen, #7). The
backup file is the user's real safety net on web.

### Web assets

`WasmDatabase.open` loads two files served next to `index.html`, committed in
`web/`:

| File | Source | Must match |
|---|---|---|
| `web/sqlite3.wasm` | https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-2.9.4/sqlite3.wasm | `sqlite3` version in `pubspec.lock` (2.9.4) |
| `web/drift_worker.js` | https://github.com/simolus3/drift/releases/download/drift-2.31.0/drift_worker.js | `drift` version in `pubspec.lock` (2.31.0) |

When upgrading `drift` or `sqlite3`, download the matching files again.
The service worker / hosting must serve `.wasm` as `application/wasm`. For
OPFS (faster, more durable) the host must also send
`Cross-Origin-Opener-Policy: same-origin` and
`Cross-Origin-Embedder-Policy: require-corp`; without them Drift falls back
to IndexedDB, which is fine.

## Backup format

`BackupService.exportJson()` writes one JSON object:

```json
{
  "app": "grind",
  "format": 2,
  "schemaVersion": 3,
  "exportedAt": "2026-11-03T08:00:00.000Z",
  "tasks": [ { "id": "...", "title": "...", "remindAt": "2026-11-03T09:00:00.000Z", "energy": "deep", "status": "open", "...": "..." } ],
  "reminderRules": [ ... ],
  "calendarEvents": [ ... ],
  "focusSessions": [ ... ],
  "goals": [ ... ],
  "preferences": { "workingHours": { "1": [ { "start": 540, "end": 1080 } ] }, "...": "..." },
  "reviewEntries": [ { "date": "2026-11-02", "win": "...", "doneCount": 3, "movedCount": 1, "createdAt": "..." } ],
  "reviewHandledDays": [ "2026-11-02" ]
}
```

- Field names are the domain field names (not column names), times ISO-8601
  UTC, enums by name. Soft-deleted rows are included, so a restore is an
  exact copy. `preferences` is null when the user never saved any.
- `importJson()` validates (`format` present and `<= 2`, every field of
  every row has the right type and range, no duplicate ids, rules and focus
  sessions point at tasks in the file, time ranges lie inside one day with
  only quiet hours allowed to wrap) before touching the database, then
  replaces **all** data in one transaction. Validation does not rely on
  `assert`s (off in release builds). Any failure throws
  `BackupFormatException` naming the row and field (e.g. `tasks[3]: "energy"
  should be one of deep, light`) and leaves the old data. The UI shows its
  own calm copy, not this message.
- Format history: 1 (schema v1-v2); 2 (schema v3: review lists and the v3
  fields). Format 1 files still import: missing fields take defaults.
- Missing optional fields take the domain defaults, so a newer app reads
  older files. A file with a higher `format` is refused with a "please
  update" message. Bump `format` only for incompatible changes and keep a
  reader for every old version.
- `deleteAllData()` hard-deletes every row ("Delete all data").
- Platform bits live behind `BackupFileGateway`; `PlatformBackupFileGateway`
  uses the share sheet on iOS (share_plus, so the file can go to Files,
  AirDrop, mail), a browser download on web (cross_file `XFile.saveTo`),
  and file_picker (`.json`) for import.

## Known limits

- Sub-millisecond precision of `DateTime`s is dropped; values read back are
  always UTC.
- Not verified on a device: iOS file location, share sheet, file picker.
  Test plan for iOS: create tasks, force-quit, reopen (data present);
  Settings > Export, save to Files; delete all data; import that file
  (identical data); import the same file exported on web.
