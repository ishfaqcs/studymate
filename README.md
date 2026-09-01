# StudyMate

StudyMate is an Android-first, local-first student planner for courses, schedules, attendance, deadlines, grades, GPA/CGPA, notes, and academic documents.

## Features

- Five-destination Material 3 navigation with system/light/dark themes
- Onboarding, student profile, semester setup, course CRUD, and weekly timetable
- Attendance history with requirement, safe-miss, and recovery calculations
- Tasks, local reminder notifications, grades, configurable scale, GPA/CGPA, and academic history
- Searchable course-linked notes and an app-private document library with PDF preview
- Global local search across courses, tasks, notes, and documents
- Versioned ZIP backup, validated atomic restore, storage totals, and PDF academic summary
- In-app privacy information, version/licenses, and two-stage full-data deletion

## Architecture and technology

The code is organized by feature. Riverpod owns application state, GoRouter owns navigation, SQLite/sqflite stores academic records, and SharedPreferences stores small preferences. Platform integrations are isolated in services/repositories. The Android application ID is `com.studymate.studentplanner`.

## Local data and privacy

V1 has no account, cloud synchronization, advertising, analytics, Firebase, or AI service. Academic records and managed document copies remain in app-private storage. User-initiated picker/share/print/open actions can hand selected content to an Android provider or application chosen by the user. See `docs/PRIVACY_POLICY_DRAFT.md` and `docs/PLAY_STORE_DATA_SAFETY.md`.

## Development setup

This is an existing Flutter project. Do **not** run `flutter create .`; regenerating platform files can overwrite working Gradle, NDK, desugaring, and Android 16 configuration.

Requirements:

- Flutter 3.47 / Dart 3.13 or a compatible stable release
- Java 17
- Android SDK with API 36 and the NDK version selected by Flutter
- An Android emulator/device (the established development target is `emulator-5554`)

```powershell
flutter pub get
dart format .
flutter analyze
flutter test
flutter run -d emulator-5554
```

## Android requirements

The app is phone-first and targets the SDK configured by the installed Flutter toolchain. Core-library desugaring and the existing Gradle/NDK/Kotlin settings are required. Do not change the application ID. Debug builds declare internet permission for Flutter tooling; the main manifest does not.

## Backup

Backup format version 1 is a ZIP containing `manifest.json`, structured `database.json`, and managed documents. Restore validates version, paths, sizes, required sections, relationships, and managed files before replacement.

## Project structure

- `lib/app`: app shell, routing, theme, and design tokens
- `lib/core`: database, services, utilities, and shared widgets
- `lib/features`: feature models, repositories, providers, and screens
- `test`: calculation, repository, screen, persistence, and backup-security tests
- `docs`: privacy, dependency, data-safety, listing, and screenshot preparation
- `android`: established Android application configuration and branded resources

## Testing and release preparation

Run formatting, analysis, and the complete test suite before every release. A production Play release still requires a private upload key/signing configuration, hosted privacy-policy URL, developer support contact, final Play Console declarations, and real-device QA. The current Gradle release block uses debug signing for local release testing only.

## Future roadmap

Possible later product decisions include optional authentication/cloud sync and StudyMate AI. They are not present in V1 and should not be advertised until implemented with appropriate privacy/security design.
