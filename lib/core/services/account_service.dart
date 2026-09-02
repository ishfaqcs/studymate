import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocalAccount {
  const LocalAccount();
}

abstract interface class AccountService {
  LocalAccount? get currentUser;
  bool get isSignedIn;
  Future<void> signOut();
  Future<void> deleteAccount();
}

class LocalAccountService implements AccountService {
  const LocalAccountService();
  @override
  LocalAccount get currentUser => const LocalAccount();
  @override
  bool get isSignedIn => false;
  @override
  Future<void> signOut() async {}
  @override
  Future<void> deleteAccount() async {}
}

final accountServiceProvider =
    Provider<AccountService>((ref) => const LocalAccountService());
