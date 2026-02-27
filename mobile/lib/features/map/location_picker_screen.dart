import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/utils/map_style.dart';

/// Full-screen map for picking a location (start point for events).
///
/// Returns a `Map<String, dynamic>` with 'lat', 'lon', and optionally 'address' keys via Navigator.pop.
/// Center-pin approach: the user pans/drags the map, pin stays at center, coordinates update on stop.
/// Includes address search via Yandex Suggest.
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
  YandexMapController? _mapController;
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  List<SuggestItem> _searchResults = [];
  bool _isSearching = false;
  String? _selectedAddress;
  String? _searchError;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLatitude;
    _selectedLon = widget.initialLongitude;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onCameraPositionChanged(CameraPosition position, CameraUpdateReason reason, bool finished) {
    if (finished) {
      setState(() {
        _selectedLat = position.target.latitude;
        _selectedLon = position.target.longitude;
        if (reason == CameraUpdateReason.gestures) {
          _selectedAddress = null; // pin moved manually — address no longer valid
        }
      });
    }
  }

  void _confirm() {
    Navigator.pop(context, <String, double>{
      'lat': _selectedLat,
      'lon': _selectedLon,
    });
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    if (text.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = null;
      });
      return;
    }
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      _performSearch(text.trim());
    });
  }

  Future<void> _performSearch(String query) async {
    setState(() {
      _isSearching = true;
      _searchError = null;
    });
    try {
      final boundingBox = BoundingBox(
        southWest: Point(
          latitude: _selectedLat - 0.5,
          longitude: _selectedLon - 0.5,
        ),
        northEast: Point(
          latitude: _selectedLat + 0.5,
          longitude: _selectedLon + 0.5,
        ),
      );

      final (session, future) = await YandexSuggest.getSuggestions(
        text: query,
        boundingBox: boundingBox,
        suggestOptions: const SuggestOptions(
          suggestType: SuggestType.geo,
          suggestWords: false,
        ),
      );

      final result = await future;
      await session.close();

      if (!mounted) return;
      setState(() {
        // Show all items — center may be null for some suggest types,
        // but we still display them so user can select and accept pin position
        _searchResults = result.items ?? [];
        _isSearching = false;
      });
    } catch (e) {
      debugPrint('Suggest error: $e');
      if (!mounted) return;
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _searchError = e.toString();
      });
    }
  }

  void _onSuggestItemSelected(SuggestItem item) {
    final center = item.center;
    if (center == null) return; // ignore suggestions without coordinates

    setState(() {
      _selectedAddress = item.displayText;
      _selectedLat = center.latitude;
      _selectedLon = center.longitude;
      _searchResults = [];
      _searchController.clear();
      _searchError = null;
    });

    _mapController?.moveCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: Point(latitude: center.latitude, longitude: center.longitude),
          zoom: 16.0,
        ),
      ),
      animation: const MapAnimation(type: MapAnimationType.smooth, duration: 0.5),
    );
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
              _mapController = controller;
              controller.setMapStyle(kCleanMapStyle);
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
          // Search field at top
          Positioned(
            top: 8,
            left: 8,
            right: 8,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: l10n.locationPickerSearchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _isSearching
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : _searchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchResults = [];
                                    });
                                  },
                                )
                              : null,
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                if (_searchError != null)
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Search error: $_searchError',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (_searchResults.isNotEmpty)
                  Material(
                    elevation: 4,
                    borderRadius: BorderRadius.circular(8),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 240),
                      child: ListView.builder(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place, size: 20),
                            title: Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: item.subtitle != null
                                ? Text(
                                    item.subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  )
                                : null,
                            onTap: () => _onSuggestItemSelected(item),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Coordinates (and optional address) display at bottom
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
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
                    if (_selectedAddress != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        _selectedAddress!,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
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
