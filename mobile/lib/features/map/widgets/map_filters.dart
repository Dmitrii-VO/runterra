import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Фильтры для карты
/// 
/// Минимальный набор фильтров согласно MVP:
/// - Сегодня / неделя
/// - Мой клуб
/// - Только активные территории
class MapFilters {
  /// Фильтр по дате: 'today' | 'week' | null (все)
  String? dateFilter;
  
  /// Фильтр по клубу (ID клуба пользователя)
  String? clubId;
  
  /// Только активные территории
  bool onlyActive = false;

  MapFilters({
    this.dateFilter,
    this.clubId,
    this.onlyActive = false,
  });

  /// Creates a copy of MapFilters with updated values
  MapFilters copyWith({
    String? dateFilter,
    String? clubId,
    bool? onlyActive,
  }) {
    return MapFilters(
      dateFilter: dateFilter ?? this.dateFilter,
      clubId: clubId ?? this.clubId,
      onlyActive: onlyActive ?? this.onlyActive,
    );
  }

  /// Проверяет, применены ли какие-либо фильтры
  bool get hasFilters {
    return dateFilter != null || clubId != null || onlyActive;
  }
}

/// Виджет панели фильтров
/// 
/// Отображается при свайпе или нажатии на кнопку.
/// Содержит переключатели для фильтров.
class MapFiltersPanel extends StatefulWidget {
  final MapFilters initialFilters;
  final Function(MapFilters) onFiltersChanged;

  const MapFiltersPanel({
    super.key,
    required this.initialFilters,
    required this.onFiltersChanged,
  });

  @override
  State<MapFiltersPanel> createState() => _MapFiltersPanelState();
}

class _MapFiltersPanelState extends State<MapFiltersPanel> {
  late MapFilters _filters;

  @override
  void initState() {
    super.initState();
    _filters = MapFilters(
      dateFilter: widget.initialFilters.dateFilter,
      clubId: widget.initialFilters.clubId,
      onlyActive: widget.initialFilters.onlyActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.filtersTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.filtersDate,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.filtersToday),
                selected: _filters.dateFilter == 'today',
                onSelected: (selected) {
                  setState(() {
                    _filters.dateFilter = selected ? 'today' : null;
                  });
                  widget.onFiltersChanged(_filters);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: Text(AppLocalizations.of(context)!.filtersWeek),
                selected: _filters.dateFilter == 'week',
                onSelected: (selected) {
                  setState(() {
                    _filters.dateFilter = selected ? 'week' : null;
                  });
                  widget.onFiltersChanged(_filters);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Фильтр "Мой клуб"
          Row(
            children: [
              Checkbox(
                value: _filters.clubId != null,
                onChanged: (value) {
                  setState(() {
                    // TODO: Получить реальный clubId из профиля пользователя или ServiceLocator
                    // На текущей стадии (skeleton) используем null вместо хардкода
                    _filters.clubId = (value ?? false) ? null : null; // Placeholder: будет заменено на реальный clubId
                  });
                  widget.onFiltersChanged(_filters);
                },
              ),
              Text(AppLocalizations.of(context)!.filtersMyClub),
            ],
          ),
          const SizedBox(height: 8),
          
          // Фильтр "Только активные территории"
          Row(
            children: [
              Checkbox(
                value: _filters.onlyActive,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _filters.onlyActive = value;
                    });
                    widget.onFiltersChanged(_filters);
                  }
                },
              ),
              Text(AppLocalizations.of(context)!.filtersActiveTerritories),
            ],
          ),
        ],
      ),
    );
  }
}
