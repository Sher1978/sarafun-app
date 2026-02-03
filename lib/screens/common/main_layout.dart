import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/models/user_model.dart';

class MainLayout extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayout({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.asData?.value;
    final isMaster = user?.role == UserRole.master;

    // Branches: 0:Discovery, 1:Map, 2:Wallet, 3:Business, 4:Profile
    // Navigation bar indices must map to these branches correctly.
    
    int currentIndex = navigationShell.currentIndex;
    if (!isMaster && currentIndex == 4) {
      currentIndex = 3; // Shift Profile index if Business is hidden
    }

    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      body: navigationShell,
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color(0xFF0F0F0F),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppTheme.primaryGold,
          unselectedItemColor: Colors.white30,
          currentIndex: currentIndex,
          onTap: (index) => _onTap(context, index, isMaster),
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined),
              activeIcon: Icon(Icons.explore),
              label: 'Discovery',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              activeIcon: Icon(Icons.map),
              label: 'Map',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            if (isMaster)
              const BottomNavigationBarItem(
                icon: Icon(Icons.business_center_outlined),
                activeIcon: Icon(Icons.business_center),
                label: 'Business',
              ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
          unselectedLabelStyle: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }

  void _onTap(BuildContext context, int index, bool isMaster) {
    int branchIndex = index;
    if (!isMaster && index == 3) {
      branchIndex = 4; // Map Profile tab back to Branch 4
    }
    
    navigationShell.goBranch(
      branchIndex,
      initialLocation: branchIndex == navigationShell.currentIndex,
    );
  }
}
