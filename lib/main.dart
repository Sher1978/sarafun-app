import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:sara_fun/services/telegram_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sara_fun/core/notification_manager.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Telegram Web App
    final telegramService = TelegramService();
    telegramService.init();

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    
    // Global Error Handling for Flutter Framework Errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print("🔴 Flutter Error: ${details.exception}");
      print("🔴 Stack: ${details.stack}");
    };
    
    runApp(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SaraFunApp(),
    ));
  }, (error, stack) {
    print("🔴 Uncaught Async Error: $error");
    print(stack);
  });
}

class SaraFunApp extends ConsumerStatefulWidget {
  const SaraFunApp({super.key});

  @override
  ConsumerState<SaraFunApp> createState() => _SaraFunAppState();
}

class _SaraFunAppState extends ConsumerState<SaraFunApp> {
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleStartup();
  }

  Future<void> _handleStartup() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if we are in Telegram
      final tgService = TelegramService();
      var tgUser = tgService.getTelegramUser();
      
      // MOCK for browser testing if not in TG
      Map<String, dynamic>? mockData;
      if (tgUser == null) {
        final uri = Uri.base;
        final mockId = uri.queryParameters['tg_user_id'];
        if (mockId != null) {
          mockData = {
            'id': int.tryParse(mockId) ?? 12345,
            'first_name': "MockUser",
            'username': "mock_user"
          };
        }
      }

      if (tgUser != null || mockData != null) {
        // Capture Deep Link Data
        final deepLink = tgService.getDeepLinkData();
        if (deepLink != null) {
          ref.read(deepLinkDataProvider.notifier).setData(deepLink);
        }

        // We are in Telegram (or Mock)! Sync user.
        final firebaseService = ref.read(firebaseServiceProvider);
        
        // 1. Authenticate via Telegram
        final String? rawInitData = tgService.getRawInitData();
        if (rawInitData != null) {
          await firebaseService.signInWithTelegram(rawInitData);
        } else if (mockData != null) {
          // Fallback to anonymous for mock testing if needed, or implement mock auth
          // For now, let's allow anonymous for mock so development doesn't block
          if (firebaseService.currentUser == null) {
            await FirebaseAuth.instance.signInAnonymously();
          }
        }

        // 2. Sync Profile
        final appUser = await firebaseService.syncTelegramUser(
          tgUser?.id ?? mockData!['id'], 
          tgUser?.firstName ?? mockData!['first_name'], 
          tgUser?.username ?? mockData!['username'],
          referrerId: deepLink?.referrerId,
        );

        await firebaseService.checkAndRefreshVipStatus(appUser);
        
        // 4. Handle Deep Link Navigation
        if (deepLink != null && deepLink.masterId != null) {
          final appRouter = ref.read(routerProvider);
          // Small delay to ensure router is ready and auth redirect has completed
          Future.delayed(const Duration(milliseconds: 500), () {
            appRouter.go('/client/discovery?masterId=${deepLink.masterId}');
          });
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: AppTheme.deepBlack,
          body: Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        ),
      );
    }

    if (_errorMessage != null) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkLuxury,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.wifi_off, size: 64, color: AppTheme.errorRed),
                const Gap(16),
                const Text(
                  "Connection Error",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const Gap(8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
                const Gap(32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleStartup,
                    child: const Text("Retry"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    // Watch the router provider to react to auth state changes
    final appRouter = ref.watch(routerProvider);


    return MaterialApp.router(
      title: 'SaraFun',
      theme: AppTheme.darkLuxury,
      routerConfig: appRouter,
      builder: (context, child) => NotificationManager(child: child ?? const SizedBox()),
      debugShowCheckedModeBanner: false,
    );
  }
}
