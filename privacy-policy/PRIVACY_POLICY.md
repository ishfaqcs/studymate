# StudyMate Privacy Policy

**Effective date: September 6, 2026**

Privacy information for the StudyMate Student Planner application (`com.studymate.studentplanner`), Version 1.

## 1. Introduction

StudyMate is a local-first academic productivity application. This policy explains what information StudyMate Version 1 handles, where it is stored, when it may leave your device, and the choices available to you. StudyMate works without an account.

## 2. Information You Provide

StudyMate handles information that you choose to enter or import, including your name, university or college, program, semester dates and details, courses, course codes, instructors, rooms, class schedules, attendance records, tasks and deadlines, grades and GPA information, grading scale, notes, and document metadata. It also stores app preferences such as theme and reminder-permission state.

## 3. How StudyMate Stores Your Information

Academic records are stored in a SQLite database in the application's local storage. Preferences are stored locally on the device. Notes are stored in the local database. Managed copies of documents you import are stored in StudyMate's app-private storage. This locally handled information is not the same as information collected on a developer server.

## 4. Information We Collect or Transmit

StudyMate Version 1 has no developer backend and does not transmit your profile, academic records, notes, documents, preferences, or backups to StudyMate or developer servers. It does not require an account and includes no Firebase, authentication, cloud synchronization, AI service, advertising SDK, or analytics SDK.

User-directed operating-system actions are different from automatic transmission by StudyMate. If you choose another application or provider when opening, saving, printing, or sharing a file, that selected service may receive the content you directed to it under its own terms and privacy practices.

## 5. Documents and File Access

StudyMate uses the Android system file-selection interface. You explicitly choose the files that StudyMate may access; StudyMate does not scan your entire device storage. It accesses only files you select as permitted by Android, validates supported file types and size, and may copy selected files into app-private storage so they remain available inside the app.

When you ask to open a managed document externally, Android may provide that specific file to an application you select. StudyMate does not request broad storage or media-library access in its release configuration.

## 6. Notifications

Reminders are optional and are scheduled locally using Android notification services. StudyMate may request notification permission when you configure a reminder. It remains usable if you deny that permission. The boot-completed permission allows Android to restore scheduled reminder behavior after a device reboot, and vibration may be used for notification feedback.

## 7. Backups and Exports

Backups and academic PDF reports are created only when you initiate them. A backup may contain your profile, semesters, courses, schedules, attendance, tasks, grades, grading scale, notes, document metadata, and copies of managed documents. You control where an exported backup or report is saved or which application receives it. StudyMate Version 1 does not automatically upload backups to a cloud service.

Once an exported file is outside StudyMate's private storage, its retention and handling are controlled by you and by the destination or application you selected.

## 8. Permissions

The StudyMate Version 1 release requests or declares only permissions needed for optional local reminders:

- **Notifications (`POST_NOTIFICATIONS`)** — allows StudyMate to display reminders on supported Android versions.
- **Receive boot completed (`RECEIVE_BOOT_COMPLETED`)** — supports restoring scheduled reminders after reboot.
- **Vibrate (`VIBRATE`)** — allows notification vibration feedback.
- **App-scoped dynamic receiver permission** — an AndroidX-generated signature permission that protects app receivers; it does not provide access to personal data or a device sensor.

The release does not request Internet, manage-all-files, legacy storage read, media read, location, camera, or microphone permission.

## 9. How Your Information Is Used

Information you provide is processed on your device to deliver the features you request: semester and course organization, schedules, attendance calculations and insights, task reminders, grades, GPA and CGPA, academic history, notes, documents, search, backups, and academic report export.

## 10. Data Sharing

StudyMate does not sell or share your academic information with the developer, advertisers, data brokers, or analytics providers. Information leaves the app only through actions you initiate, such as selecting a source document or choosing to open, save, print, or share a backup, managed document, or report through Android and another application or provider.

## 11. Advertising and Analytics

StudyMate Version 1 contains no advertising and no analytics or behavioral-tracking SDK. The privacy-policy website also uses no advertisements, cookies, analytics, external JavaScript, tracking pixels, or external fonts.

## 12. Data Retention

Local information remains on your device until you delete individual records where that option is available, use StudyMate's Delete All Data function, clear the application's storage through Android, or uninstall the application. Android device backup or restore behavior may be controlled by your device and operating-system settings. Exported files remain wherever you saved or shared them until you delete them there.

## 13. Deleting Your Data

The two-step **Data & Backup → Delete all StudyMate data** function cancels scheduled StudyMate notifications, removes profile and academic database records, deletes StudyMate-managed document copies, resets local preferences, and returns the app to onboarding. It does not delete backup files, reports, or documents previously exported to locations or applications outside StudyMate's control. You must delete those external copies separately.

You may also clear StudyMate's app storage or uninstall the application through Android to remove app-local data, subject to Android's own device-backup and restore settings.

## 14. Security

StudyMate's local-first design limits routine data transmission, uses Android app-private storage where applicable, validates imported files and backup structure, and avoids unnecessary permissions. No storage method can be guaranteed completely secure. Protect your device with an appropriate screen lock, keep Android updated, and store exported backups securely because anyone with access to a backup may be able to read its contents.

## 15. Children's Privacy

StudyMate is an academic organization tool that may be useful to students. Version 1 does not operate an advertising, analytics, account, or behavioral-profiling system and does not knowingly transmit student records to developer servers. Parents, guardians, schools, and users should decide whether the app and the information entered into it are appropriate for their circumstances. This policy does not claim approval by an educational institution or compliance certification under a particular children's privacy law.

## 16. Third-Party Services and Libraries

StudyMate is built with Flutter and uses local-purpose libraries including Riverpod, GoRouter, SQLite/sqflite, SharedPreferences, local notifications, the Android system file selector, ZIP archive processing, PDF generation and printing, external file opening, and package-information access. These libraries support app functions and do not, merely by being included, mean that StudyMate sends personal information to their authors.

Android and any application or storage, print, or sharing provider you deliberately select may process the content involved in that action according to their own privacy policies.

## 17. International Data Transfers

StudyMate Version 1 does not transfer your academic information to StudyMate or developer servers in any country. If you choose an external application or cloud provider to save, print, open, or share content, that provider may process data in other countries under its own practices.

## 18. Changes to This Privacy Policy

This policy may be updated when StudyMate's behavior changes or clarification is needed. The effective date at the top will be updated when a revised policy is published. Material changes to data handling should be disclosed before the affected app version is released.

## 19. Contact

Questions about this policy or StudyMate's privacy practices may be sent to:

**DEVELOPER_SUPPORT_EMAIL_TODO**

This placeholder must be replaced with the publisher's valid support email before this policy is submitted to Google Play.

---

**StudyMate**  
Package: `com.studymate.studentplanner`
