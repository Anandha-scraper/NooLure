# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

NooLure — a Flutter (Dart) Android app: tasks, notes, birthdays, a PIN-locked password vault, and a shared trip planner. Package `com.noolure.app`.

## Common commands

```bash
flutter pub get                       # install dependencies (run after touching pubspec.yaml)
flutter run                           # run on a connected device/emulator
flutter build apk --release           # release APK (what CI produces)
flutter test                          # run tests (there is currently no test/ directory)
flutter analyze                       # static analysis (flutter_lints)
```

There is no `test/` directory in this repo yet — don't assume test infrastructure exists before checking.

`pubspec.lock` is gitignored, so a fresh `flutter pub get` always re-resolves. `pubspec.yaml` pins `jni: ^1.0.2` via `dependency_overrides` — see the comment there before touching that override; a bare `^1.0.0` transitively pulled in by `google_sign_in_android`/`firebase_database` resolves to a version that breaks the Gradle build.

## Architecture

**Local-first data layer.** Hive (`lib/core/data/local_store.dart`) is the source of truth; every read/write hits disk first, so the app works fully offline with no backend configured. `Repository<T>` (`lib/core/data/repository.dart`) wraps one Hive box with JSON (de)serialization and exposes a `watch()` stream driven by `box.watch()` — writes from anywhere in the app, or an incoming sync update, push straight to every listening screen. `lib/core/data/repositories.dart` is the single place all five collections (`tasks`, `notes`, `birthdays`, `passwords`, `passwordVault`) are wired up; nothing outside `Repository`/`SyncService` should touch Hive or Firebase directly.

**Optional Firebase mirror.** `SyncService` (`lib/core/data/sync_service.dart`) is a singleton that tries `Firebase.initializeApp()` in `init()` and **swallows the failure** — with no `google-services.json` present, sync silently stays disabled and the app runs local-only with no degraded behavior. When enabled, per-user data lives under `/users/<uid>/<collection>/<id>`; conflicts resolve by newest `updatedAt` (`_reconcile`/`mergeRemote`). `TripSyncService` (`lib/core/data/trip_sync_service.dart`) is a separate, non-Hive-backed sync path for trips: trip data is group-owned (shared across uids) and lives in a parallel tree (`/trips/{id}`, `/tripInviteCodes/{code}`, `/userTrips/{uid}/{tripId}`) rather than under `/users/<uid>/...`, and trips are unavailable offline by design (empty list, not stale cache).

**State management: Provider.** `lib/app.dart` wires one `ChangeNotifierProvider` per domain (`AuthProvider`, `TaskProvider`, `NoteProvider`, `BirthdayProvider`, `ThemeProvider`, `TripProvider`, `PasswordProvider`) under a single `MultiProvider`, all above a `MaterialApp` whose `home` is `AuthGate`. `AuthGate` switches on `AuthProvider.status` (`unknown` → splash, `authenticating`/`unauthenticated` → login, `authenticated` → home); `Login`/`SettingUp` screens use `pushReplacement` so Back never re-enters the sign-in flow.

**Auth.** `AuthService` (`lib/core/services/auth_service.dart`) wraps Google Sign-In + Firebase Auth. `AuthProvider` (`lib/providers/auth_provider.dart`) layers session persistence (`shared_preferences` flag + Firebase Auth's own cached session), a locally-editable display name that survives what the identity provider reports, and binds/unbinds `SyncService`/`TripSyncService` on sign-in/out. Sign-out and account deletion both call `LocalStore.clearAll()` so a new account on the same device never inherits the previous account's local data — `signOut()` explicitly refuses to proceed if there's an unsynced write and no connection, to avoid silently losing or cross-merging data.

**Password vault encryption.** `VaultCrypto` (`lib/core/security/vault_crypto.dart`) derives an AES-256 key from the user's PIN via PBKDF2-HMAC-SHA256 (200k iterations) plus a stored salt; the derived key is never persisted. Unlock is verified against a stored canary ciphertext (a known plaintext re-encrypted under the derived key) rather than a separate PIN hash, so PIN verification is inseparable from decryption capability.

**Routing.** Named routes only, no `MaterialApp.routes` map — `RouteGenerator.generateRoute` (`lib/core/routes/route_generator.dart`) switches on `settings.name` against constants in `lib/core/routes/app_routes.dart`. Screens that need arguments (`taskDetail`, `editNote`, `editBirthday`, `birthdayDetail`, `tripDetail`, `editPassword`) read them via `settings.arguments`, typed as either a raw `String` id or a record type (see `editPassword`'s `({String id, PasswordEntryData data, String tag})`).

## CI/CD

`.github/workflows/preview-distribution.yml` triggers on push to the `preview` branch: builds a signed release APK and distributes it via Firebase App Distribution to the `preview` tester group. The normal ship flow is a PR from `main` into `preview`; merging it kicks off the build automatically. See `Noolure.md` for the full non-technical runbook (secrets inventory, failure-mode table, what each CI step does) — read it before touching the workflow file or Android signing config.

Key facts if touching CI or signing:
- The release keystore (`ANDROID_KEYSTORE_BASE64` + passwords) is irreplaceable — losing it means any future Play Store listing has to start over. Never commit `android/app/release-keystore.jks` (already gitignored).
- The workflow verifies `applicationId` in `android/app/build.gradle.kts` is a valid reverse-domain identifier before building anything, and fails fast if not.
