/// Yandex MapKit style that hides POI clutter (cafes, shops, transit stops, etc.)
/// Apply via: controller.setMapStyle(kCleanMapStyle)
const String kCleanMapStyle = '''
[
  {
    "types": "point",
    "tags": { "all": ["poi"] },
    "stylers": { "visibility": "off" }
  },
  {
    "types": "point",
    "tags": { "all": ["transit"] },
    "stylers": { "visibility": "off" }
  },
  {
    "types": "point",
    "tags": { "all": ["business"] },
    "stylers": { "visibility": "off" }
  }
]
''';
