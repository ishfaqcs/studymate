# Play Store data-safety handoff

This is an engineering audit, not a completed Play Console declaration.

StudyMate stores user-entered profile, semester, course, schedule, attendance, task, grade, note, preference, reminder, and document data locally. Selected documents are copied into app-private storage. Core features contain no authentication, analytics, advertising, Firebase, AI API, or cloud-sync integration and do not intentionally transmit academic data.

User-directed picker, print, share, external-open, and backup flows can pass selected content to an application or provider chosen by the user. Exported files remain outside StudyMate until the user deletes them.

Verified merged release permissions are `POST_NOTIFICATIONS`, `VIBRATE`, `RECEIVE_BOOT_COMPLETED`, and the app-scoped AndroidX signature permission `com.studymate.studentplanner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`. Broad storage, media-read, location, camera, microphone, and `INTERNET` permissions are absent from release. Reconfirm these statements against the final signed AAB before completing Play Console Data Safety.
