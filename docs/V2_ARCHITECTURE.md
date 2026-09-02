# StudyMate V2 Phase 1 Architecture

## V1 baseline

StudyMate V1 is a local-first Flutter application. Feature folders contain immutable map-backed models, SQLite repositories, Riverpod providers and screens. `AppDatabase` owns schema creation and sequential migrations. GoRouter owns navigation, SharedPreferences stores small settings, local notifications schedule reminders, and ZIP backups contain a manifest, JSON table data and managed document files.

The audited V1 schema version was **6**. Its user tables are `profile`, `semesters`, `courses`, `schedules`, `attendance`, `tasks`, `grades`, `grading_boundaries`, `notes`, and `documents`. V1 uses integer semester/profile identifiers and string identifiers for other records.

## Phase 1 goals and database change

Schema version **7** is an additive, in-place migration. It creates:

- `study_sessions`
- `exam_preparations`
- `exam_topics`
- `study_plans`
- `study_plan_blocks`

No V1 table, column, identifier, or record is rewritten. Existing integer IDs remain authoritative. New records use the established string-ID convention. Sync IDs were deliberately deferred: adding them to every V1 row without a sync backend would increase migration risk without current value.

The migration uses `CREATE TABLE/INDEX IF NOT EXISTS`, making the additive step deterministic and safely repeatable in partial-schema testing. SQLite upgrades are transactional. Foreign-key behavior is deliberate: plan/topic children cascade with their owner; course-owned exam preparation cascades; historical sessions and optional block links use `SET NULL` when their course/task is deleted.

## New local architecture

Each V2 entity has map serialization and a SQLite repository compatible with existing Riverpod patterns. Study sessions support CRUD, completion/cancellation, date/course filtering and aggregate study minutes. Exam preparation and plan repositories manage their child records. Plans are ordinary local records and never depend on AI.

`GradePredictionService` is pure deterministic math. `AnalyticsService` derives study totals from stored completed sessions; derived values are not persisted or calculated in widget build methods.

`AppConfig` separates development/release context and provides static module flags. `AccountService`, `SyncService`, and `AiAssistantService` are interfaces. Phase 1 supplies local/no-op/disabled implementations only. They make no network calls and contain no credentials.

## Routes and UI

Routes are reserved for `/study-planner`, `/study-session`, `/exam-prep`, `/analytics`, `/grade-predictor`, `/cloud-sync`, and `/ai-assistant`. Debug builds use internal placeholders. Release builds redirect these unfinished routes to `/more`. The five primary destinations and all V1 design components remain unchanged.

## Privacy and configuration

`cloudSyncEnabled` and `aiFeaturesEnabled` preferences default to `false` and are removed by full reset. Phase 1 contains no API key, backend URL, telemetry, remote configuration, AI provider, or data transmission.

## Backup compatibility

New exports use backup format version 2 and include all five V2 tables. The inspector accepts format 1 and treats absent V2 collections as empty, so V1 archives remain restorable. Unknown future versions are rejected before mutation. Restore validation occurs before the transactional database replacement, and document rollback behavior is retained.

## Timestamp and sync limitations

All new mutable records have `created_at` and `updated_at`. Historical V1 timestamp limitations remain unchanged to avoid inventing inaccurate history. Conflict metadata, tombstones, authentication, networking, and conflict resolution are intentionally deferred until a concrete optional-sync design exists.

## Version decision

The application version remains `1.0.0+1`. Phase 1 is an internal foundation and no V2 build is being distributed yet.
