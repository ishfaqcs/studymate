# Production dependency audit

| Dependency | Purpose | Relevant behavior |
|---|---|---|
| Flutter / Material | Android UI and runtime | Framework; debug tooling uses network permission in debug only. |
| flutter_riverpod | Local state management | In-process; no network function. |
| go_router | Navigation | In-process; no data collection. |
| shared_preferences | Theme/onboarding preferences | Local key-value storage. |
| intl | Local date/number formatting | In-process. |
| sqflite | SQLite persistence | App-private local database. |
| path / uuid | Safe paths and internal identifiers | In-process. |
| flutter_local_notifications / timezone | Local reminders and scheduling | Uses Android notification APIs; requests notification permission contextually. |
| file_selector | System file open/save UI | Accesses only user-selected documents/providers. |
| archive | ZIP backup encoding/validation | Local processing; no execution of archive content. |
| pdf / printing | Academic-summary PDF, preview, print/share | Local PDF generation; user-initiated platform print/share may hand data to a chosen service. |
| open_filex | External document opening | Sends a selected app-private managed file through a FileProvider. Its unnecessary media/legacy read permissions are removed by StudyMate’s manifest. |
| package_info_plus | Actual version/build display | Reads installed package metadata. |

No analytics, advertising, authentication, cloud, or AI SDK is present. Re-audit dependency release notes and the final merged manifest before every store release.

## Release-lock verification

The resolved picker packages are `file_selector 1.1.0` and `file_selector_android 0.5.2+9`. `package_info_plus` resolves to 10.2.1. No dependency in the application source provides analytics, advertising, authentication, cloud synchronization, or AI services. The merged release manifest contains no `INTERNET` permission.

## Android picker stabilization

Phase 6 briefly evaluated `file_picker` 12.x, whose federated `android_file_picker` implementation required additional Kotlin artifacts that blocked reliable Android dependency resolution. A temporary `file_picker` 11.0.3 fallback then proved incompatible with the current AGP 9 plugin registration path. StudyMate now uses official `file_selector` 1.1.0 (`file_selector_android` 0.5.2+9) instead. The affected document-import and ZIP backup open/save flows preserve their extension filters, cancellation handling, repository validation, and backup inspection. Neither `file_picker` nor `android_file_picker` remains in the lockfile or generated plugin metadata.
