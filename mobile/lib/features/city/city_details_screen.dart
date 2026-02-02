import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/city_model.dart';
import '../../shared/ui/details_scaffold.dart';
import '../../shared/ui/error_display.dart';

/// Экран деталей города
///
/// Отображает информацию о городе, загружая данные через CitiesService.
/// Использует FutureBuilder для отображения состояний loading/error/success.
/// 
/// Принимает cityId через параметр маршрута и загружает данные города.
class CityDetailsScreen extends StatefulWidget {
  /// ID города (передается через параметр маршрута)
  final String cityId;

  const CityDetailsScreen({
    super.key,
    required this.cityId,
  });

  /// Создает Future для получения данных о городе
  /// 
  /// TODO: Backend URL вынести в конфигурацию
  /// 
  /// Примечание: Для Android эмулятора используется 10.0.2.2 вместо localhost.
  /// Для физического устройства используйте IP адрес хост-машины в локальной сети.
  @override
  State<CityDetailsScreen> createState() => _CityDetailsScreenState();
}

class _CityDetailsScreenState extends State<CityDetailsScreen> {
  /// Future for city details.
  late Future<CityModel> _cityFuture;

  /// Creates Future for loading city data.
  Future<CityModel> _fetchCity() async {
    return ServiceLocator.citiesService.getCityById(widget.cityId);
  }
  
  /// Reload data
  void _retry() {
    setState(() {
      _cityFuture = _fetchCity();
    });
  }

  @override
  void initState() {
    super.initState();
    _cityFuture = _fetchCity();
  }

  @override
  Widget build(BuildContext context) {
    return DetailsScaffold(
      title: AppLocalizations.of(context)!.cityDetailsTitle,
      body: FutureBuilder<CityModel>(
        future: _cityFuture,
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

          // Состояние успеха - отображение данных города
          if (snapshot.hasData) {
            final city = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название города
                    Text(
                      city.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    // Координаты города
                    Text(
                      AppLocalizations.of(context)!.detailCoordinates,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.detailLatLng(
                        city.coordinates.latitude.toString(),
                        city.coordinates.longitude.toString(),
                      ),
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
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
