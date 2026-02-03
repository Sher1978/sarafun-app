import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sara_fun/services/firebase_service.dart';
import 'package:sara_fun/services/telegram_service.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/transaction_model.dart';

// Storage Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

// Service Providers
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService();
});

final telegramServiceProvider = Provider<TelegramService>((ref) {
  return TelegramService();
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

// Current AppUser Provider (Reads from Firestore based on Auth User)
// Current AppUser Provider (Mutable StateProvider)
// This allows us to manually set the user when logging in via Telegram
// Current AppUser Provider (Managed by Notifier)
class CurrentUserNotifier extends Notifier<AsyncValue<AppUser?>> {
  @override
  AsyncValue<AppUser?> build() {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      data: (user) {
        if (user == null) return const AsyncValue.data(null);
        return const AsyncValue.loading();
      },
      loading: () => const AsyncValue.loading(),
      error: (e, st) => AsyncValue.error(e, st),
    );
  }

  void setUser(AppUser? user) {
    state = AsyncValue.data(user);
  }
}

final currentUserProvider = NotifierProvider<CurrentUserNotifier, AsyncValue<AppUser?>>(CurrentUserNotifier.new);

// Deep Link Data Provider
// Deep Link Data Provider
class DeepLinkDataNotifier extends Notifier<DeepLinkData?> {
  @override
  DeepLinkData? build() => null;

  void setData(DeepLinkData? data) => state = data;
}

final deepLinkDataProvider = NotifierProvider<DeepLinkDataNotifier, DeepLinkData?>(DeepLinkDataNotifier.new);

// Transactions Provider
final userTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  
  // Extra safety: Verify FirebaseAuth has a UID ready
  final authUser = FirebaseAuth.instance.currentUser;
  
  if (user == null || authUser == null) return Stream.value([]);
  
  return ref.watch(firebaseServiceProvider).getTransactionsStream(user.uid);
});
