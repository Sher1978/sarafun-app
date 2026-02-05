import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/core/theme/app_theme.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text('SETTINGS', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: AppTheme.primaryGold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionHeader("ACCOUNT"),
          const Gap(16),
          _buildSettingsTile(
            context,
            icon: Icons.person_outline,
            title: "Edit Profile",
            onTap: () {},
          ),
          const Gap(12),
          _buildSettingsTile(
            context,
            icon: Icons.notifications_none,
            title: "Notification Preferences",
            onTap: () {},
          ),
          const Gap(32),
          _buildSectionHeader("PREFERENCES"),
          const Gap(16),
          _buildSettingsTile(
             context,
             icon: Icons.dark_mode_outlined,
             title: "Theme Mode",
             trailing: const Text("Dark", style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
             onTap: () {},
          ),
          const Gap(32),
          _buildSectionHeader("SUPPORT"),
          const Gap(16),
          _buildSettingsTile(
            context,
            icon: Icons.help_outline,
            title: "Help Center",
            onTap: () {},
          ),
          const Gap(12),
          _buildSettingsTile(
            context,
            icon: Icons.info_outline,
            title: "About SaraFun",
            onTap: () {},
          ),
          const Gap(48),
          _buildLogoutButton(context, ref),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.primaryGold,
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildSettingsTile(BuildContext context, {required IconData icon, required String title, Widget? trailing, required VoidCallback onTap}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white70, size: 20),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          // Log out logic
          // ref.read(firebaseServiceProvider).signOut(); 
          // For MVP demo, we just navigate to login
          context.go('/login');
        },
        icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
        label: const Text("LOGOUT", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, letterSpacing: 1)),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}
