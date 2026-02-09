import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yandex_mapkit/yandex_mapkit.dart';
import '../../../l10n/app_localizations.dart';

/// Read-only mini-map showing event start location.
/// Tap navigates to the Map tab centered on these coordinates.
class EventMiniMap extends StatelessWidget {
  final double latitude;
  final double longitude;

  const EventMiniMap({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final point = Point(latitude: latitude, longitude: longitude);

    return GestureDetector(
      onTap: () => context.go('/map?lat=$latitude&lon=$longitude'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: AbsorbPointer(
                child: YandexMap(
                  tiltGesturesEnabled: false,
                  scrollGesturesEnabled: false,
                  zoomGesturesEnabled: false,
                  rotateGesturesEnabled: false,
                  mapObjects: [
                    CircleMapObject(
                      mapId: const MapObjectId('event_start'),
                      circle: Circle(center: point, radius: 30),
                      fillColor: const Color.fromRGBO(33, 150, 243, 0.4),
                      strokeColor: Colors.blue,
                      strokeWidth: 2.0,
                    ),
                  ],
                  onMapCreated: (controller) {
                    controller.moveCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(target: point, zoom: 15),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.open_in_new, size: 14, color: Colors.blue[700]),
              const SizedBox(width: 4),
              Text(
                l10n.eventOpenOnMap,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.blue[700],
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
