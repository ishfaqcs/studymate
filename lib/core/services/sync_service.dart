import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SyncStatus { disabled, idle, syncing, failed }

abstract interface class SyncService {
  DateTime? get lastSyncAt;
  SyncStatus get status;
  Future<void> sync();
}

class NoOpSyncService implements SyncService {
  const NoOpSyncService();
  @override
  DateTime? get lastSyncAt => null;
  @override
  SyncStatus get status => SyncStatus.disabled;
  @override
  Future<void> sync() async {}
}

final syncServiceProvider =
    Provider<SyncService>((ref) => const NoOpSyncService());
