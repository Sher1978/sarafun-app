import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/screens/wallet_screen.dart';
import 'package:sara_fun/screens/client/history_screen.dart';
import 'package:sara_fun/screens/client/discovery_screen.dart';
import 'package:sara_fun/screens/client/map_explorer_screen.dart';
import 'package:sara_fun/screens/business/master_dashboard_screen.dart';
import 'package:sara_fun/screens/business/scanner_screen.dart';
import 'package:sara_fun/screens/auth/login_screen.dart';
import 'package:sara_fun/screens/client/confirm_deal_screen.dart';
import 'package:sara_fun/models/transaction_model.dart';
import 'package:sara_fun/screens/onboarding_screen.dart';
import 'package:sara_fun/screens/common/profile_screen.dart';
import 'package:sara_fun/screens/business/master_onboarding_screen.dart';
import 'package:sara_fun/screens/common/main_layout.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:flutter/material.dart';

// Dummy user for MVP demo
const dummyClient = AppUser(
  uid: 'client-123',
  telegramId: 123456789,
  role: UserRole.client,
  balanceStars: 500,
  isVip: true,
  dealCountMonthly: 12,
);

const dummyMaster = AppUser(
  uid: 'master-999',
  telegramId: 987654321,
  role: UserRole.master,
  balanceStars: 2000,
  depositBalance: 800, // Low balance for demo
  isVisible: true,
);

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(currentUserProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  
  return GoRouter(
    initialLocation: '/discovery',
    redirect: (context, state) {
      final user = authState.asData?.value;
      final isLoggedIn = user != null;
      final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;
      
      final isLoggingIn = state.uri.path == '/login';
      final isOnboarding = state.uri.path == '/onboarding';

      if (!isLoggedIn) {
        if (!onboardingComplete) {
          if (isOnboarding) return null;
          return '/onboarding';
        }
        if (isLoggingIn || isOnboarding) return null;
        return '/login';
      }

      if (isLoggingIn || isOnboarding) {
        return '/discovery';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainLayout(navigationShell: navigationShell),
        branches: [
          // Branch 0: Discovery
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discovery',
                builder: (context, state) {
                  final masterId = state.uri.queryParameters['masterId'];
                  return DiscoveryScreen(filterMasterId: masterId);
                },
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      // Service detail normally logic
                      return const SizedBox.shrink(); // Placeholder
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 1: Map
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) => const MapExplorerScreen(),
              ),
            ],
          ),
          // Branch 2: Wallet
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) {
                      final user = authState.asData?.value;
                      final List<Transaction>? transactions = state.extra as List<Transaction>?;
                      return HistoryScreen(
                        client: user ?? dummyClient,
                        initialData: transactions,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          // Branch 3: Business (Master Only - handled by visibility in MainLayout)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/business',
                builder: (context, state) {
                  final user = authState.asData?.value;
                  return MasterDashboardScreen(master: user ?? dummyMaster);
                },
              ),
            ],
          ),
          // Branch 4: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/scanner',
        builder: (context, state) => const ScannerScreen(),
      ),
      GoRoute(
        path: '/master-onboarding',
        builder: (context, state) => const BecomeMasterOnboardingScreen(),
      ),
      GoRoute(
        path: '/confirm-deal',
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>? ?? {};
          return ConfirmDealScreen(
            serviceTitle: extras['serviceTitle'] ?? 'Service',
            serviceId: extras['serviceId'] ?? '',
            masterName: extras['masterName'] ?? 'Partner',
            masterId: extras['masterId'] ?? '',
            amountStars: extras['amountStars'] ?? 0,
          );
        },
      ),
    ],
  );
});
