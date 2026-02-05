import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/core/providers.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: const Text('ADMIN PANEL', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: AppTheme.primaryGold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatOverview(ref),
            const Gap(32),
            _buildSectionHeader("USER MANAGEMENT"),
            const Gap(16),
            _buildUserList(ref),
          ],
        ),
      ),
    );
  }

  Widget _buildStatOverview(WidgetRef ref) {
    // In a real app, these would be real aggregate streams
    return Row(
      children: [
        Expanded(child: _buildStatCard("TOTAL USERS", "1,240", Icons.people, Colors.blueAccent)),
        const Gap(12),
        Expanded(child: _buildStatCard("TOTAL MASTERS", "42", Icons.business_center, Colors.purpleAccent)),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const Gap(12),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(4),
          Text(title, style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
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

  Widget _buildUserList(WidgetRef ref) {
    final firebaseService = ref.read(firebaseServiceProvider);
    
    // For demo, we just get discovery masters and maybe some clients
    return StreamBuilder<List<AppUser>>(
      stream: firebaseService.getDiscoveryMastersStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!;

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: users.length,
          separatorBuilder: (_, __) => const Gap(12),
          itemBuilder: (context, index) {
            final user = users[index];
            return Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white10,
                  backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                  child: user.photoURL == null ? const Icon(Icons.person, color: Colors.white24) : null,
                ),
                title: Text(user.displayName ?? 'Unknown', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text(user.role.name.toUpperCase(), style: TextStyle(color: user.role == UserRole.master ? AppTheme.primaryGold : Colors.white54, fontSize: 10)),
                trailing: const Icon(Icons.more_vert, color: Colors.white24),
              ),
            );
          },
        );
      },
    );
  }
}
