import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';

class ProfileRepository {
  Future<Map<String, Object?>?> get() async {
    final rows =
        await (await AppDatabase.instance.database).query('profile', limit: 1);
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> updateName(String name) async {
    await (await AppDatabase.instance.database).update(
      'profile',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

final profileProvider = FutureProvider<Map<String, Object?>?>((ref) {
  return ref.watch(profileRepositoryProvider).get();
});
