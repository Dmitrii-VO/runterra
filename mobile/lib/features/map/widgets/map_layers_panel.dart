import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/map_layer_model.dart';

class MapLayersPanel extends StatefulWidget {
  const MapLayersPanel({
    super.key,
    required this.layerState,
    required this.onToggle,
  });

  final MapLayerState layerState;
  final void Function(MapLayer) onToggle;

  @override
  State<MapLayersPanel> createState() => _MapLayersPanelState();
}

class _MapLayersPanelState extends State<MapLayersPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                _expanded ? Icons.layers : Icons.layers_outlined,
                color: Colors.black87,
                size: 24,
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 4),
          Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _LayerRow(
                    icon: Icons.map_outlined,
                    iconColor: Colors.indigo,
                    label: l.mapLayerTerritories,
                    value: widget.layerState.isEnabled(MapLayer.territories),
                    onChanged: (_) => widget.onToggle(MapLayer.territories),
                  ),
                  _LayerRow(
                    icon: Icons.emoji_events_outlined,
                    iconColor: Colors.deepOrange,
                    label: l.mapLayerRaces,
                    value: widget.layerState.isEnabled(MapLayer.races),
                    onChanged: (_) => widget.onToggle(MapLayer.races),
                  ),
                  _LayerRow(
                    icon: Icons.directions_run,
                    iconColor: Colors.green,
                    label: l.mapLayerLocal,
                    value: widget.layerState.isEnabled(MapLayer.local),
                    onChanged: (_) => widget.onToggle(MapLayer.local),
                  ),
                  _LayerRow(
                    icon: Icons.place_outlined,
                    iconColor: Colors.teal,
                    label: l.mapLayerVenues,
                    value: widget.layerState.isEnabled(MapLayer.venues),
                    onChanged: (_) => widget.onToggle(MapLayer.venues),
                  ),
                  Tooltip(
                    message: l.mapLayerRoutesComingSoon,
                    child: _LayerRow(
                      icon: Icons.route_outlined,
                      iconColor: Colors.grey,
                      label: l.mapLayerRoutes,
                      value: false,
                      onChanged: null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _LayerRow extends StatelessWidget {
  const _LayerRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final active = onChanged != null;
    return SizedBox(
      width: 210,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          children: [
            Icon(icon, color: active ? iconColor : Colors.grey.shade400, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: active ? Colors.black87 : Colors.grey.shade400,
                ),
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              activeColor: iconColor,
            ),
          ],
        ),
      ),
    );
  }
}
