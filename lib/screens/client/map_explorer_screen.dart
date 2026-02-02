import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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

  // Custom Dark Luxury Map Style (Black & Gold aesthetic)
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry",
    "stylers": [{"color": "#121212"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#ae965d"}] 
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  }
]
''';

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
        title: const Text("Map Explorer"),
        backgroundColor: AppTheme.deepBlack,
      ),
      body: StreamBuilder<List<AppUser>>(
        stream: firebaseService.getVisibleMastersOnMap(),
        builder: (context, snapshot) {
          final masters = snapshot.data ?? [];
          
          final markers = masters.map((master) {
            return Marker(
              markerId: MarkerId(master.uid),
              position: LatLng(master.latitude!, master.longitude!),
              infoWindow: InfoWindow(title: master.businessName ?? master.displayName ?? "Elite Partner"),
              icon: BitmapDescriptor.defaultMarkerWithHue(45.0),
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
    );
  }
}
