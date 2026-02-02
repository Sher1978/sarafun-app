import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gap/gap.dart';
import 'package:sara_fun/core/theme/app_theme.dart';
import 'package:sara_fun/core/theme/map_styles.dart';

class MasterLocationPicker extends StatefulWidget {
  final LatLng? initialLocation;
  final Function(LatLng)? onLocationPicked;
  const MasterLocationPicker({super.key, this.initialLocation, this.onLocationPicked});

  @override
  State<MasterLocationPicker> createState() => _MasterLocationPickerState();
}

class _MasterLocationPickerState extends State<MasterLocationPicker> {
  LatLng? _selectedPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _selectedPosition = widget.initialLocation;
  }

  Future<void> _handleSave() async {
    if (_selectedPosition != null) {
      if (widget.onLocationPicked != null) {
        widget.onLocationPicked!(_selectedPosition!);
      }
      Navigator.pop(context, _selectedPosition);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    final latLng = LatLng(position.latitude, position.longitude);
    
    setState(() => _selectedPosition = latLng);
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Your Location"),
        backgroundColor: AppTheme.deepBlack,
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text("SAVE", style: TextStyle(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedPosition ?? const LatLng(25.2048, 55.2708), // Default to Dubai
              zoom: 12,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
              controller.setMapStyle(MapStyles.darkStyle);
            },
            onTap: (position) => setState(() => _selectedPosition = position),
            markers: _selectedPosition != null
                ? {
                    Marker(
                      markerId: const MarkerId("selected"),
                      position: _selectedPosition!,
                      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow),
                    ),
                  }
                : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),
          Positioned(
            bottom: 24,
            left: 24,
            right: 80, // Leave room for FAB
            child: ElevatedButton(
              onPressed: _selectedPosition != null ? _handleSave : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("CONFIRM SELECTION", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ),
          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _getCurrentLocation,
              backgroundColor: AppTheme.primaryGold,
              child: const Icon(Icons.my_location, color: Colors.black),
            ),
          ),
          if (_selectedPosition == null)
            const Center(
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    "Tap on the map to set your business location",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
