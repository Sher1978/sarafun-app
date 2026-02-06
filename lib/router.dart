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
import 'package:sara_fun/screens/admin/admin_dashboard_screen.dart';
import 'package:sara_fun/screens/common/settings_screen.dart';
import 'package:sara_fun/screens/common/main_layout.dart';
import 'package:sara_fun/screens/client/service_detail_screen.dart';
import 'package:sara_fun/screens/client/search_screen.dart';
import 'package:sara_fun/screens/client/favorites_screen.dart';
import 'package:sara_fun/models/service_card_model.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/screens/common/chat_list_screen.dart';
import 'package:sara_fun/screens/common/chat_screen.dart';
import 'package:sara_fun/screens/business/leads_screen.dart';
import 'package:sara_fun/screens/business/add_service_screen.dart';

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
      
      final isLoggingIn = state.matchedLocation == '/login';
      final isOnboarding = state.matchedLocation == '/onboarding';
      if (!isLoggedIn) {
        if (isLoggingIn || isOnboarding) return null;
        return '/login';
      }

      if (user != null && !user.onboardingComplete) {
        if (isOnboarding) return null;
        return '/onboarding';
      }

      if (isLoggingIn || isOnboarding) {
        return '/discovery';
      }

      if (user.role != UserRole.admin && state.matchedLocation.startsWith('/admin')) {
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
                    path: 'search',
                    builder: (context, state) => const SearchScreen(),
                  ),
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final service = state.extra as ServiceCard;
                      return ServiceDetailScreen(service: service);
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
          // Branch 3: Favorites
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/favorites',
                builder: (context, state) => const FavoritesScreen(),
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
        path: '/business',
        builder: (context, state) {
          final user = authState.asData?.value;
          return MasterDashboardScreen(master: user ?? dummyMaster);
        },
        routes: [
           GoRoute(
            path: 'leads',
            builder: (context, state) => const LeadsScreen(),
          ),
           GoRoute(
            path: 'history',
            builder: (context, state) => const WalletScreen(), // Reusing generic history for now or create specific? 
            // Wait, WalletScreen is for client? 
            // Better to make a placeholder or reuse HistoryScreen if possible.
          ),
          GoRoute(
            path: 'add-service',
            builder: (context, state) => const AddServiceScreen(),
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
      GoRoute(
        path: '/chats',
        builder: (context, state) => const ChatListScreen(),
        routes: [
           GoRoute(
            path: ':roomId',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return ChatScreen(roomId: roomId);
            },
          ),
        ],
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
  );
});
