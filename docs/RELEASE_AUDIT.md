# StudyMate 1.0 release audit

## Android configuration

- Package/namespace: `com.studymate.studentplanner`
- Version: `1.0.0+1` (`versionName 1.0.0`, `versionCode 1`)
- AGP: 9.1.0
- Gradle: 9.3.1
- JDK: 25.0.2 (Java 17 source/target compatibility)
- Flutter: 3.47.0 stable
- Dart: 3.13.0
- compileSdk: 36
- targetSdk: 36
- minSdk: 24 (Android 7.0)
- NDK: 28.2.13676358

## Dependency blocker

StudyMate no longer uses `file_picker` or its federated `android_file_picker` implementation. It uses `file_selector ^1.1.0` for document import and ZIP backup open/save flows. Existing extension filters, cancellation handling, document repository validation, and backup inspection remain in place.

## Release manifest gate

The generated release manifest was audited from `build/app/intermediates/merged_manifest/release/processReleaseMainManifest/AndroidManifest.xml`. It contains:

- `android.permission.RECEIVE_BOOT_COMPLETED`
- `android.permission.VIBRATE`
- `android.permission.POST_NOTIFICATIONS`
- `com.studymate.studentplanner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` (app-scoped signature permission contributed by AndroidX)

It does not contain `INTERNET`, broad storage/media access, location, camera, or microphone permissions. The source manifest removes legacy/media read permissions contributed by dependencies. Debug/profile builds retain Flutter's development-only `INTERNET` permission.

## Build and device gates

- Debug APK: successful, 166,824,908 bytes (159.10 MiB)
- Android 16/API 36 install: APK installed successfully on `emulator-5554`
- Runtime smoke QA: blocked because the emulator's Pixel Launcher was not responding; StudyMate did not become the focused activity
- Release APK/AAB: intentionally blocked until a private upload key is supplied through ignored `android/key.properties`

## Supported Android version

StudyMate supports Android 7.0 (API 24) and later. This is the Flutter 3.47.0 default resolved by the current Gradle configuration.
