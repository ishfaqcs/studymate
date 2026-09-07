# Play Store data-safety working notes

This document records observed StudyMate V1 behavior; it is not a submitted Play Console declaration.

## Stored locally

- Name, university/college, program, and semester details entered by the user.
- Courses, timetable, attendance, tasks, grades/GPA, notes, grading scale.
- Document metadata and app-private copies of user-selected documents.
- Theme/onboarding preferences and scheduled reminder information.

## Transmission and collection

- The application source contains no authentication, analytics, ads, Firebase, AI API, or cloud-sync integration.
- Core academic features do not intentionally transmit data.
- User-initiated Android picker, share, print, external-open, and backup destination flows can pass selected content to an app/provider chosen by the user.

## Permissions

- `POST_NOTIFICATIONS` may be contributed by the notification dependency and is requested contextually when scheduling a reminder; reminders are optional.
- `RECEIVE_BOOT_COMPLETED` allows scheduled reminders to be restored after reboot.
- `VIBRATE` is contributed by the notification dependency for reminder feedback.
- `com.studymate.studentplanner.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` is an app-scoped signature permission added by AndroidX to protect dynamically registered receivers; it does not grant access to user data or a device capability.
- `INTERNET` is declared only in the debug manifest for Flutter tooling, not the main release manifest.
- No broad storage or `MANAGE_EXTERNAL_STORAGE` permission is declared.
- Media/legacy read permissions contributed by the external-open dependency are explicitly removed during manifest merging because StudyMate opens only its app-private managed copies.

## Deletion and backups

The app supports record deletion and a two-stage full local-data reset. Exported backups are ZIP files containing structured data and managed documents. External copies are not removed by an in-app reset.

Publisher must verify the final merged release manifest and completed Play Console questionnaire before submission.

## Privacy Policy

Intended public URL: https://ishfaqcs.github.io/studymate/privacy-policy/

Publisher support email: `ishfaqcs@uoswabi.edu.pk`

The remaining publication requirement is successful deployment and verification of the public privacy-policy URL.
