import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gap/gap.dart';
import 'package:sara_fun/core/theme/map_styles.dart';
import 'package:go_router/go_router.dart';
import 'package:sara_fun/core/providers.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/models/user_model.dart';
import 'package:geolocator/geolocator.dart';

class MapExplorerScreen extends ConsumerStatefulWidget {
  const MapExplorerScreen({super.key});

  @override
  ConsumerState<MapExplorerScreen> createState() => _MapExplorerScreenState();
}

class _MapExplorerScreenState extends ConsumerState<MapExplorerScreen> {
  GoogleMapController? _mapController;
  LatLng _initialPosition = const LatLng(0, 0);
  double _initialZoom = 2.0;
  bool _isLoadingMap = true;
  String _selectedCategory = "All";
  final List<String> _categories = ["All", "Cars", "Health", "Dance"];
  
  // New State for Floating Card
  AppUser? _selectedMaster;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    // ... (Existing geolocation logic unchanged, omitting for brevity in this replace block if possible, but replace tool needs full context. I will assume existing logic is preserved if not explicitly overwritten, but here I must provide the full replacement for the class or the target block. To be safe, I'm replacing the whole class body parts that change.)
    // Actually, I'll just keep the _determinePosition as is, but I can't partially match easily inside the method.
    // Let's re-implement _determinePosition to ensure it's there.
    
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
       _setDefaultLocation();
       return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _setDefaultLocation();
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      _setDefaultLocation();
      return;
    } 

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _initialZoom = 12.0;
        _isLoadingMap = false;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_initialPosition, _initialZoom));
    }
  }

  void _setDefaultLocation() {
    if (mounted) {
      setState(() {
        _initialPosition = const LatLng(25.2048, 55.2708); // Dubai default
        _initialZoom = 10.0;
        _isLoadingMap = false;
      });
    }
  }

  // Refined Black & Grey Map Style
  static const String _darkMapStyle = MapStyles.darkStyle;

  void _onMarkerTapped(AppUser master) {
    setState(() {
      _selectedMaster = master;
    });
  }

  void _onMapTapped(LatLng _) {
    if (_selectedMaster != null) {
      setState(() {
        _selectedMaster = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = ref.watch(firebaseServiceProvider);

    return Scaffold(
      extendBodyBehindAppBar: true, // For full immersion
      appBar: AppBar(
        title: const Text("MAP EXPLORER", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        backgroundColor: Colors.transparent, // Glass effect for AppBar? Or just keep it clean
        flexibleSpace: Container(
           decoration: BoxDecoration(
             gradient: LinearGradient(
               colors: [Colors.black.withOpacity(0.8), Colors.transparent],
               begin: Alignment.topCenter,
               end: Alignment.bottomCenter
             )
           ),
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Google Map Layer
          StreamBuilder<List<AppUser>>(
            stream: firebaseService.getVisibleMastersOnMap(),
            builder: (context, snapshot) {
              final allMasters = snapshot.data ?? [];
              
              final masters = allMasters.where((m) {
                 if (_selectedCategory == "All") return true;
                 return true; // Simplified filter
              }).toList();

              final markers = masters.map((master) {
                return Marker(
                  markerId: MarkerId(master.uid),
                  position: LatLng(master.latitude!, master.longitude!),
                  // infoWindow: InfoWindow(title: master.businessName ?? "Partner"), // Disable default info window to use custom card
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                     _selectedMaster?.uid == master.uid ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueYellow
                  ),
                  onTap: () => _onMarkerTapped(master),
                );
              }).toSet();

              if (_isLoadingMap) {
                return Container(color: AppTheme.deepBlack, child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)));
              }

              return GoogleMap(
                initialCameraPosition: CameraPosition(target: _initialPosition, zoom: _initialZoom),
                onMapCreated: (controller) {
                  _mapController = controller;
                  _mapController?.setMapStyle(_darkMapStyle);
                },
                markers: markers,
                onTap: _onMapTapped,
                myLocationEnabled: true,
                myLocationButtonEnabled: false, // Custom button below
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                padding: const EdgeInsets.only(bottom: 200), // Push Google Logo up
              );
            },
          ),

          // 2. Filter Bar (Top)
          Positioned(
            top: 100, // Below AppBar
            left: 0,
            right: 0,
            child: _buildFilterBar(),
          ),

          // 3. Floating Glass Card (Bottom)
          if (_selectedMaster != null)
            Positioned(
              left: 20,
              right: 20,
              bottom: 30, // Above typical TabBar height
              child: _buildPremiumGlassCard(_selectedMaster!),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumGlassCard(AppUser master) {
    return Animate(
      effects: const [FadeEffect(), SlideEffect(begin: Offset(0, 0.2), end: Offset(0, 0), curve: Curves.easeOutCubic, duration: Duration(milliseconds: 400))],
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85), // Semi-transparent black
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppTheme.primaryGold, width: 1.5), // Gold Border
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryGold.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: 2,
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: AppTheme.primaryGold,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: Colors.black,
                backgroundImage: (master.photoUrl != null && master.photoUrl!.isNotEmpty) 
                   ? NetworkImage(master.photoUrl!) 
                   : null,
                child: (master.photoUrl == null || master.photoUrl!.isEmpty)
                   ? Text(master.displayName?.substring(0, 1) ?? "U", style: const TextStyle(color: AppTheme.primaryGold))
                   : null,
              ),
            ),
            const Gap(16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    master.businessName ?? master.displayName ?? "Elite Partner",
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(4),
                  Row(
                    children: [
                      const Icon(Icons.star, color: AppTheme.primaryGold, size: 14),
                      const Gap(4),
                      const Text("5.0", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      const Gap(8),
                      Text("•  ${master.username ?? 'Business'}", style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            // Button
            ElevatedButton(
              onPressed: () => context.push('/client/discovery?masterId=${master.uid}'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text("VIEW", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      height: 60,
      color: AppTheme.deepBlack,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const Gap(12),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = category),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryGold : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGold : Colors.white12,
                ),
              ),
              child: Text(
                category.toUpperCase(),
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
