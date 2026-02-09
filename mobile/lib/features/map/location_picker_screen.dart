import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../l10n/app_localizations.dart';

/// Full-screen map for picking a location (start point for events).
///
/// Returns a `Map<String, double>` with 'lat' and 'lon' keys via Navigator.pop.
/// Center-pin approach: the user pans/drags the map, pin stays at center, coordinates update on stop.
class LocationPickerScreen extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;

  const LocationPickerScreen({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late double _selectedLat;
  late double _selectedLon;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLatitude;
    _selectedLon = widget.initialLongitude;
  }

  void _onCameraPositionChanged(CameraPosition position, CameraUpdateReason reason, bool finished) {
    if (finished) {
      setState(() {
        _selectedLat = position.target.latitude;
        _selectedLon = position.target.longitude;
      });
    }
  }

  void _confirm() {
    Navigator.pop(context, {'lat': _selectedLat, 'lon': _selectedLon});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locationPickerTitle),
        actions: [
          TextButton(
            onPressed: _confirm,
            child: Text(l10n.locationPickerConfirm),
          ),
        ],
      ),
      body: Stack(
        children: [
          YandexMap(
            onMapCreated: (controller) {
              controller.moveCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    target: Point(latitude: _selectedLat, longitude: _selectedLon),
                    zoom: 15.0,
                  ),
                ),
              );
            },
            onCameraPositionChanged: _onCameraPositionChanged,
            mapObjects: const [],
          ),
          // Pin icon at center of map (always centered)
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 48),
              child: IgnorePointer(
                child: Icon(
                  Icons.location_on,
                  size: 48,
                  color: Colors.deepOrange,
                ),
              ),
            ),
          ),
          // Coordinates display at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.location_on, size: 18, color: Colors.deepOrange),
                    const SizedBox(width: 8),
                    Text(
                      '${_selectedLat.toStringAsFixed(5)}, ${_selectedLon.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
