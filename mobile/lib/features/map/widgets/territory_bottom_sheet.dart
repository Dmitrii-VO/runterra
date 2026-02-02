import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/territory_map_model.dart';

/// Bottom sheet для отображения информации о территории
/// 
/// Показывается при тапе на территорию на карте.
/// Содержит: название, статус, клуб-владелец, счётчик, CTA.
class TerritoryBottomSheet extends StatelessWidget {
  final TerritoryMapModel territory;

  const TerritoryBottomSheet({
    super.key,
    required this.territory,
  });

  /// Получает цвет статуса территории
  Color _getStatusColor(String status) {
    switch (status) {
      case 'captured':
        return Colors.blue; // 🟦
      case 'free':
        return Colors.grey; // ⚪
      case 'contested':
        return Colors.yellow; // 🟨
      case 'locked':
        return Colors.grey.shade800; // тёмно-серый
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case 'captured':
        return l10n.territoryCaptured;
      case 'free':
        return l10n.territoryFree;
      case 'contested':
        return l10n.territoryContested;
      case 'locked':
        return l10n.territoryLocked;
      default:
        return l10n.territoryUnknown;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Заголовок с названием
          Row(
            children: [
              Expanded(
                child: Text(
                  territory.name,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              // Индикатор статуса
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _getStatusColor(territory.status),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Статус
          Text(
            _getStatusText(context, territory.status),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          
          // Клуб-владелец (если есть)
          if (territory.clubId != null)
            Text(
              AppLocalizations.of(context)!.territoryOwnerLabel(territory.clubId!),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.territoryHoldTodo,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          
          const SizedBox(height: 20),
          
          // CTA кнопки
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Навигация на список тренировок территории
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.territoryViewTrainings),
                ),
              ),
              const SizedBox(width: 12),
              if (territory.status == 'free' || territory.status == 'contested')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(AppLocalizations.of(context)!.territoryHelpCapture),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () {
                Navigator.pop(context);
                context.push('/territory/${territory.id}');
              },
              child: Text(AppLocalizations.of(context)!.territoryMore),
            ),
          ),
        ],
      ),
    );
  }
}
