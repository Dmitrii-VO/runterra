import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/city_model.dart';
import '../../main.dart' show DevRemoteLogger;

/// Показывает диалог выбора города и возвращает выбранный cityId.
///
/// Возвращает:
/// - String cityId — если пользователь выбрал город;
/// - null — если пользователь закрыл диалог.
Future<String?> showCityPickerDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      final l10n = AppLocalizations.of(dialogContext)!;
      return AlertDialog(
        title: Text(l10n.cityPickerTitle),
        content: FutureBuilder<List<CityModel>>(
          future: ServiceLocator.citiesService.getCities(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 80,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              DevRemoteLogger.logError(
                'Failed to load cities for picker',
                error: snapshot.error ?? 'unknown',
              );
              return Text(l10n.cityPickerLoadError(snapshot.error.toString()));
            }

            final cities = snapshot.data ?? <CityModel>[];
            if (cities.isEmpty) {
              return Text(l10n.cityPickerEmpty);
            }

            return SizedBox(
              width: double.maxFinite,
              height: 240,
              child: ListView.builder(
                itemCount: cities.length,
                itemBuilder: (context, index) {
                  final city = cities[index];
                  return ListTile(
                    title: Text(city.name),
                    subtitle: Text(
                      '${city.coordinates.latitude.toStringAsFixed(4)}, '
                      '${city.coordinates.longitude.toStringAsFixed(4)}',
                    ),
                    onTap: () {
                      Navigator.of(dialogContext).pop(city.id);
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
        ],
      );
    },
  );
}
