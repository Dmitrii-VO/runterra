import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/territory_model.dart';
import '../../shared/ui/details_scaffold.dart';
import '../../shared/ui/error_display.dart';

/// Экран деталей территории
///
/// Отображает информацию о территории, загружая данные через TerritoriesService.
/// Использует FutureBuilder для отображения состояний loading/error/success.
/// 
/// Принимает territoryId через параметр маршрута и загружает данные территории.
class TerritoryDetailsScreen extends StatefulWidget {
  /// ID территории (передается через параметр маршрута)
  final String territoryId;

  const TerritoryDetailsScreen({
    super.key,
    required this.territoryId,
  });

  /// Создает Future для получения данных о территории
  /// 
  /// TODO: Backend URL вынести в конфигурацию
  /// 
  /// Примечание: Для Android эмулятора используется 10.0.2.2 вместо localhost.
  /// Для физического устройства используйте IP адрес хост-машины в локальной сети.
  @override
  State<TerritoryDetailsScreen> createState() => _TerritoryDetailsScreenState();
}

class _TerritoryDetailsScreenState extends State<TerritoryDetailsScreen> {
  /// Future for territory details.
  late Future<TerritoryModel> _territoryFuture;

  /// Creates Future for loading territory data.
  Future<TerritoryModel> _fetchTerritory() async {
    return ServiceLocator.territoriesService.getTerritoryById(widget.territoryId);
  }
  
  /// Reload data
  void _retry() {
    setState(() {
      _territoryFuture = _fetchTerritory();
    });
  }

  @override
  void initState() {
    super.initState();
    _territoryFuture = _fetchTerritory();
  }

  @override
  Widget build(BuildContext context) {
    return DetailsScaffold(
      title: AppLocalizations.of(context)!.territoryDetailsTitle,
      body: FutureBuilder<TerritoryModel>(
        future: _territoryFuture,
        builder: (context, snapshot) {
          // Состояние загрузки
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Состояние ошибки
          if (snapshot.hasError) {
            return ErrorDisplay(
              errorMessage: snapshot.error.toString(),
              onRetry: _retry,
            );
          }

          // Состояние успеха - отображение данных территории
          if (snapshot.hasData) {
            final territory = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название территории
                    Text(
                      territory.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    // Статус территории
                    Text(
                      AppLocalizations.of(context)!.detailStatus,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      territory.status,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    // Координаты центра территории
                    Text(
                      AppLocalizations.of(context)!.detailCoordinatesCenter,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.detailLatLng(
                        territory.coordinates.latitude.toString(),
                        territory.coordinates.longitude.toString(),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.detailCity,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      territory.cityId,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    // Захвативший игрок (если есть)
                    if (territory.capturedByUserId != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.detailCapturedBy,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        territory.capturedByUserId!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          // Fallback (не должно произойти)
          return Center(
            child: Text(AppLocalizations.of(context)!.noData),
          );
        },
      ),
    );
  }
}
