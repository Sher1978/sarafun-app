import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sara_fun/services/firebase_service.dart';
import 'package:sara_fun/services/telegram_service.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/models/transaction_model.dart';

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
final currentUserProvider = StateProvider<AsyncValue<AppUser?>>((ref) {
  // Default behavior: Listen to Auth Changes
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return const AsyncValue.data(null);
      return const AsyncValue.loading();
    },
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});

// Deep Link Data Provider
final deepLinkDataProvider = StateProvider<DeepLinkData?>((ref) => null);

// Transactions Provider
final userTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  final user = userAsync.asData?.value;
  if (user == null) return Stream.value([]);
  
  return ref.watch(firebaseServiceProvider).getTransactionsStream(user.uid);
});
