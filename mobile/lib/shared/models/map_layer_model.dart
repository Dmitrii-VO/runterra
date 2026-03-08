enum MapLayer {
  territories, // А: club territory polygons
  races, // Б: large events (open_event)
  local, // В: local events (group_run, training, club_event)
  venues, // Г: running POI (stadiums, tracks)
  routes, // Д: running routes (coming soon)
}

class MapLayerState {
  final Map<MapLayer, bool> _layers;

  MapLayerState(Map<MapLayer, bool> layers) : _layers = Map.unmodifiable(layers);

  factory MapLayerState.defaults() => MapLayerState({
        MapLayer.territories: true,
        MapLayer.races: true,
        MapLayer.local: true,
        MapLayer.venues: false,
        MapLayer.routes: false,
      });

  bool isEnabled(MapLayer layer) => _layers[layer] ?? false;

  MapLayerState withToggled(MapLayer layer) {
    // routes layer is not interactive — always stays off
    if (layer == MapLayer.routes) return this;
    final updated = Map<MapLayer, bool>.from(_layers);
    updated[layer] = !(updated[layer] ?? false);
    return MapLayerState(updated);
  }
}
