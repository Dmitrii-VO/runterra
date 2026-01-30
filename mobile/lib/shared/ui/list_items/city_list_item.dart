import 'package:flutter/material.dart';
import '../../navigation/user_action.dart';

/// UI-компонент для отображения элемента списка города
/// 
/// Простой StatelessWidget без логики и состояний.
/// Принимает данные через конструктор и отображает их.
/// 
/// Использование:
/// ```dart
/// CityListItem(
///   cityId: 'city-123',
///   cityName: 'Москва',
///   onAction: (action) => print('Action: $action'),
/// )
/// ```
class CityListItem extends StatelessWidget {
  /// ID города (используется для навигации)
  final String cityId;

  /// Название города для отображения
  final String cityName;

  /// Callback для обработки действий пользователя (intent-based navigation)
  final void Function(UserAction)? onAction;

  const CityListItem({
    super.key,
    required this.cityId,
    required this.cityName,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(
        cityName,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        onAction?.call(SelectCityAction(cityId: cityId));
      },
    );
  }
}
