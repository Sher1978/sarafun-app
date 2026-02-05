import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/service_card_model.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:sara_fun/core/providers.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<ServiceCard> _serviceResults = [];
  List<AppUser> _masterResults = [];
  bool _isLoading = false;

  Future<void> _performSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _serviceResults = [];
        _masterResults = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    final firebaseService = ref.read(firebaseServiceProvider);
    
    final results = await Future.wait([
      firebaseService.searchServices(query),
      firebaseService.searchMasters(query),
    ]);

    if (mounted) {
      setState(() {
        _serviceResults = results[0] as List<ServiceCard>;
        _masterResults = results[1] as List<AppUser>;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.deepBlack,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search services or masters...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            border: InputBorder.none,
          ),
          onChanged: _performSearch,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _performSearch('');
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold))
          : _buildResults(),
    );
  }

  Widget _buildResults() {
    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 64, color: Colors.white.withValues(alpha: 0.1)),
            const Gap(16),
            Text(
              'Explore SaraFun',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_serviceResults.isEmpty && _masterResults.isEmpty) {
      return Center(
        child: Text(
          'No results found for "${_searchController.text}"',
          style: const TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        if (_masterResults.isNotEmpty) ...[
          _buildSectionHeader('MASTERS'),
          const Gap(16),
          ..._masterResults.map((master) => _buildMasterTile(master)),
          const Gap(24),
        ],
        if (_serviceResults.isNotEmpty) ...[
          _buildSectionHeader('SERVICES'),
          const Gap(16),
          ..._serviceResults.map((service) => _buildServiceTile(service)),
        ],
      ],
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

  Widget _buildMasterTile(AppUser master) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: Colors.white10,
        backgroundImage: master.photoURL != null ? NetworkImage(master.photoURL!) : null,
        child: master.photoURL == null ? const Icon(Icons.person, color: Colors.white24) : null,
      ),
      title: Text(
        master.displayName ?? 'Unknown Master',
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        master.businessName ?? 'Independent Consultant',
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () {
        // Navigate to discovery with filter or master profile
        context.push('/discovery?masterId=${master.uid}');
      },
    );
  }

  Widget _buildServiceTile(ServiceCard service) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: service.mediaUrls.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(service.mediaUrls.first, fit: BoxFit.cover),
              )
            : const Icon(Icons.spa, color: Colors.white24),
      ),
      title: Text(
        service.title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        '${service.priceStars} Stars',
        style: const TextStyle(color: AppTheme.primaryGold, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24),
      onTap: () {
        context.push('/discovery/detail', extra: service);
      },
    );
  }
}
