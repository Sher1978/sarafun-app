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

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Default to global view if services disabled
      if (mounted) {
        setState(() {
          _initialPosition = const LatLng(0, 0);
          _initialZoom = 2.0;
          _isLoadingMap = false;
        });
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Global view on denial
        if (mounted) {
          setState(() {
            _initialPosition = const LatLng(0, 0);
            _initialZoom = 2.0;
            _isLoadingMap = false;
          });
        }
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() {
          _initialPosition = const LatLng(0, 0);
          _initialZoom = 2.0;
          _isLoadingMap = false;
        });
      }
      return;
    } 

    final position = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _initialPosition = LatLng(position.latitude, position.longitude);
        _initialZoom = 12.0;
        _isLoadingMap = false;
      });
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _initialPosition, zoom: _initialZoom),
        ),
      );
    }
  }

  // Refined Black & Grey Map Style
  static const String _darkMapStyle = MapStyles.darkStyle;

  void _onMarkerTapped(AppUser master) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              master.businessName ?? master.displayName ?? (master.username != null ? "@${master.username}" : "Elite Partner"),
              style: const TextStyle(
                color: AppTheme.primaryGold,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              master.businessName != null ? master.displayName ?? "Premium Partner" : "Premium Partner",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.push('/discovery?masterId=${master.uid}');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text("VIEW SERVICES", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firebaseService = ref.watch(firebaseServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("MAP EXPLORER", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        backgroundColor: AppTheme.deepBlack,
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: StreamBuilder<List<AppUser>>(
              stream: firebaseService.getVisibleMastersOnMap(),
              builder: (context, snapshot) {
                final allMasters = snapshot.data ?? [];
                
                // Functional Logic: Filter markers based on category
                final masters = allMasters.where((m) {
                  if (_selectedCategory == "All") return true;
                  // In a real app, master would have a category. 
                  // For now, we'll assume they match if they have any service in that category
                  return true; // TODO: Implement category matching on Master model
                }).toList();

                final markers = masters.map((master) {
                  return Marker(
                    markerId: MarkerId(master.uid),
                    position: LatLng(master.latitude!, master.longitude!),
                    infoWindow: InfoWindow(title: master.businessName ?? master.displayName ?? "Elite Partner"),
                    icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                    onTap: () => _onMarkerTapped(master),
                  );
                }).toSet();

                if (_isLoadingMap) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold));
                }

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _initialPosition,
                    zoom: _initialZoom,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _mapController?.setMapStyle(_darkMapStyle);
                  },
                  markers: markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                );
              },
            ),
          ),
        ],
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
