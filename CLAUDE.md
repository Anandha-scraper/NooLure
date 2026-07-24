# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

NooLure is a Flutter personal productivity app: Tasks, Notes, Birthdays, a Trip Planner, a PIN-locked Passwords vault, a Home dashboard, and a Profile/settings screen. Android is the only configured platform — there is no `ios/` directory, and `linux/` is gitignored.

`README.md` predates most of this and is stale — it describes a mocked auth backend and a Calendar/Goals feature set, none of which exist in `lib/` anymore (auth is real `firebase_auth`, there's no `calendar`/`goal` model or screen). Don't treat it as current; this file supersedes it.

## Commands

```bash
flutter pub get                    # after pulling or editing pubspec.yaml
flutter analyze                     # must be clean; this is the gate
flutter test                        # all tests
flutter test test/repository_test.dart   # a single test file
flutter run                         # run on a device/emulator
flutter build apk --debug           # verifies Gradle + launcher icons
dart run flutter_launcher_icons     # regenerate launcher icons after changing the source art
```

## Architecture

**Local-first, with a Firebase mirror that's dormant unless a config is present.** This is the single most important thing to understand, because it looks like a Firebase app and, in a fresh checkout, isn't one yet. This applies to Tasks/Notes/Birthdays/Passwords — Trips is the one exception (see below).

- `lib/core/data/local_store.dart` opens five Hive boxes (`tasks`, `notes`, `birthdays`, `passwords`, `passwordVault`). Records are stored as JSON strings keyed by id — no Hive adapters, no `build_runner`.
- `lib/core/data/repository.dart` is a generic `Repository<T>` over one box. **Hive is the source of truth.** `watch()` is fed by `box.watch()`, so any write anywhere pushes to every listening screen; `save()` writes locally first and only then hands off to sync. This is what makes the app fully usable offline.
- `lib/core/data/sync_service.dart` calls `Firebase.initializeApp()` inside a **try/catch**. `android/app/google-services.json` is gitignored (per-developer / CI-injected, see CI/CD below), so on a fresh clone that throws, `isEnabled` stays false, and the app runs purely on-device. Drop a Firebase config in and it lights up with no code changes: it mirrors each box to `/users/<uid>/<collection>/<id>` in Firebase **Realtime Database** (not Firestore), reconciles local against remote with last-write-wins on `updatedAt`, and subscribes for live updates. Firebase's own disk persistence queues offline writes. It also exposes the shared root `DatabaseReference` (`SyncService.instance.root`) so other services can piggyback on the same `initializeApp()`/persistence setup.
- `lib/core/data/repositories.dart` wires the concrete repositories (tasks, notes, birthdays, passwords, passwordVault) and touches each one at startup so it registers with `SyncService` before sign-in. Providers hold these; **nothing else touches Hive or Firebase directly.**
- Auth (`lib/core/services/auth_service.dart`) is **not** part of this dormant-until-configured story — it's real `firebase_auth` + `google_sign_in` (v7, Credential Manager-based `GoogleSignIn.instance.authenticate()`), called unconditionally. It needs both `google-services.json` *and* a hardcoded `_serverClientId` (the "Web client" id from that file — the v7 API doesn't auto-detect it on Android), so sign-in only works when both are right; there is no mock/offline auth path.

**Trips are the exception to local-first — shared, realtime-only, Hive-free.** `lib/core/data/trip_sync_service.dart` (`TripSyncService`) is a separate singleton from `SyncService`, because trip data is group-owned (several uids read/write the same record) and doesn't fit the per-user `/users/<uid>/<collection>` layout — `SyncService`'s `pruneMissing` would otherwise delete a trip locally the instant it's absent from one member's own subtree. It reuses `SyncService.instance.root` but writes to a parallel tree: `/trips/{tripId}` (the document), `/tripInviteCodes/{code} -> tripId` (join-by-code + a Firebase transaction to guarantee code uniqueness), and `/userTrips/{uid}/{tripId}` (per-user index driving which trips a client subscribes to). There is no on-device cache — offline means an empty trip list, not stale-but-usable data. Admin-only actions (delete trip, remove a member, add/delete an item) are gated in `TripProvider` by `trip.isAdmin(uid)`; the real enforcement boundary is `database.rules.json` (repo root), not the client — e.g. only a trip's creator can write its top-level fields, and invite codes are immutable once claimed.

**Passwords are a PIN-locked, client-side-encrypted vault.** `lib/core/security/vault_crypto.dart` (`VaultCrypto`) derives an AES-256 key from a 4-digit PIN via PBKDF2-HMAC-SHA256 (200k iterations) and a random salt; the derived key **never touches disk** and lives only in `PasswordProvider`'s memory for the life of that instance, cleared by `lock()` (called from the Passwords screen's `dispose()`, so leaving the section always re-locks it). `PasswordVaultModel` (Hive record id `'vault'`) stores only the salt and an encrypted "canary" blob used to verify a PIN on unlock without storing the PIN or key. Each `PasswordModel` stores only an AES-GCM `encryptedBlob` (JSON-encoded `PasswordEntryData`: username/password/url) plus a plaintext `tag` for filter chips — `toJson` must never emit plaintext credentials, since that JSON is exactly what Hive persists and `SyncService` mirrors to Firebase. Both boxes flow through the normal `Repository`/`SyncService` path otherwise, so the encrypted blobs sync like any other collection; only the key stays device-local. "Forgot PIN" (`resetVault()`) wipes every entry and the vault record — the only recovery path, since nothing but the PIN reconstructs the key.

**Models carry real `DateTime`s, never display strings.** Every model has `toJson`/`fromJson`/`copyWith` plus `createdAt`/`updatedAt` (`updatedAt` drives sync conflict resolution), and ids are UUIDs (Trips thread their id in from the RTDB snapshot key instead of duplicating it in the JSON). Labels like "Today", "just now" and "in 12 days" are **computed at render time** by `lib/core/utils/date_labels.dart` and exposed as model getters (`task.dateLabel`, `note.editedLabel`, `password.editedLabel`, `birthday.daysLabel`). Never store a formatted label — that was the old design and it froze dates at whatever text was written. Birthdays store `month`/`day`/`birthYear?` rather than a single DateTime, because the year is often unknown.

**Recurring tasks ("Routines") apply the same never-store-derived-state principle to status, not just labels.** A `TaskModel.routine` (`RoutineConfig`, in `lib/models/routine_config.dart`) only persists the schedule (daily or custom dates) plus a sparse list of `RoutineDayEntry` — one entry per day the user actually marked done. Whether a given calendar day is upcoming, due now, completed-late, or missed is a pure function of `(RoutineConfig, DateTime)`, computed live by `lib/core/utils/routine_occurrence.dart`'s `RoutineOccurrenceStatus` — a "missed" day is never written back as a record.

**Providers** (`lib/providers/`) are `ChangeNotifier`s registered in `lib/app.dart`'s `MultiProvider`. Each subscribes to its repository's (or, for Trips, `TripSyncService`'s) stream in its constructor and rebuilds its list on every emission. Writes go through the repository/sync service and come back via the stream — providers never mutate their list directly.

**Navigation.** `lib/app.dart` mounts `AuthGate` as `home:`, with `onGenerateRoute: RouteGenerator.generateRoute` (route names in `lib/core/routes/app_routes.dart`, `AppRoutes`) handling every pushed route. **AuthGate is the root route** and it reactively switches on `AuthProvider.status` (`unknown` → splash, `unauthenticated`/`authenticating` → Login, `authenticated` → Home). That means:
- Never `pushReplacementNamed` from a top-level screen — it destroys AuthGate and breaks both back navigation and logout. Use `goToSection()` in `lib/widgets/app_scaffold.dart`, which pops to the root and then pushes, keeping the stack at exactly `[Home, section]`.
- Logout just calls `signOut()` (after `popUntil(isFirst)`); AuthGate handles the rest. Don't navigate to Login explicitly. `signOut()` also calls `LocalStore.clearAll()`, wiping every local Hive box — so a second account signing in on the same device never inherits the previous account's on-device data.
- Every screen except Home uses `AppScaffold` (`lib/widgets/app_scaffold.dart`), which supplies the AppBar, the back/hamburger leading widget, and the drawer. Home rolls its own Scaffold because of its custom header.
- `lib/core/routes/route_observer.dart`'s `appRouteObserver` is registered as a `navigatorObserver` so a screen can detect "a route pushed on top of me just got popped" (e.g. to reset an armed swipe-confirm card) via `RouteAware`.

**Theming.** `AppTheme.light()/.dark()` build from the "Cabin" palette in `lib/core/constants/app_colors.dart`, seeded by the user's accent choice (gold or sage) via `ThemeProvider`. The ramps (`accent100`…`accent900`) are **fixed light-mode swatches** — reaching for them directly in a widget produces a near-white chip on a dark card and pins the widget to gold even when the user picked sage. Instead use the brightness-aware derivations at the bottom of `app_colors.dart`:
- `AppColors.softFill(color, brightness)` / `softInk(...)` — chip and pill backgrounds and their ink.
- `AppColors.accentInk(color, brightness)` — accent-tinted icons/links directly on the page background.

Pass `Theme.of(context).colorScheme.primary` as the color so widgets follow the accent setting.

## Conventions

- Auth session state (the "stay logged in" flag, plus a local display-name override) lives in `shared_preferences`, separate from Firebase Auth's own session. `AuthProvider._restoreSession()` does a passive local lookup (`currentCachedUser()`), not an interactive sign-in, so app launch doesn't re-prompt.
- Card radius is 32; pills, buttons and inputs are `StadiumBorder` / radius 999.
- `TextStyles` (`lib/core/theme/text_styles.dart`): Caprasimo for headings (`h1`–`h4`), Figtree for body. Card sub-styles take a `BuildContext`.

## CI/CD

`.github/workflows/preview-distribution.yml` runs only on pushes to a `preview` branch (never `main`, never PRs). It decodes `google-services.json`, a release keystore, and `key.properties` from repo secrets (all three are gitignored locally), builds a signed release APK, wipes previous Firebase App Distribution releases for the app, and distributes the new one to the `preview` tester group. Local builds never touch this path — `flutter build apk --debug` works with no secrets and no signing config.
