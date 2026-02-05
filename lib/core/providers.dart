import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sara_fun/services/chat_service.dart';

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

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService();
});

final telegramServiceProvider = Provider<TelegramService>((ref) {
  return TelegramService();
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(firebaseServiceProvider).authStateChanges;
});

// Current AppUser Provider (Reads from Firestore based on Auth User)
// Current AppUser Provider (Reads from Firestore based on Auth User)
final currentUserProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(firebaseServiceProvider).getUserStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});

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
  if (user == null) return Stream.value([]);
  
  return ref.watch(firebaseServiceProvider).getTransactionsStream(user.uid);
});
