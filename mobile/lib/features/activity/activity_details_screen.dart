import 'package:flutter/material.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/activity_model.dart';
import '../../shared/ui/details_scaffold.dart';
import '../../shared/ui/error_display.dart';

/// Экран деталей активности
///
/// Отображает информацию об активности, загружая данные через ActivitiesService.
/// Использует FutureBuilder для отображения состояний loading/error/success.
/// 
/// Принимает activityId через параметр маршрута и загружает данные активности.
class ActivityDetailsScreen extends StatefulWidget {
  /// ID активности (передается через параметр маршрута)
  final String activityId;

  const ActivityDetailsScreen({
    super.key,
    required this.activityId,
  });

  /// Создает Future для получения данных об активности
  /// 
  /// TODO: Backend URL вынести в конфигурацию
  /// 
  /// Примечание: Для Android эмулятора используется 10.0.2.2 вместо localhost.
  /// Для физического устройства используйте IP адрес хост-машины в локальной сети.
  @override
  State<ActivityDetailsScreen> createState() => _ActivityDetailsScreenState();
}

class _ActivityDetailsScreenState extends State<ActivityDetailsScreen> {
  /// Future for activity details.
  late Future<ActivityModel> _activityFuture;

  /// Creates Future for loading activity data.
  Future<ActivityModel> _fetchActivity() async {
    return ServiceLocator.activitiesService.getActivityById(widget.activityId);
  }
  
  /// Reload data
  void _retry() {
    setState(() {
      _activityFuture = _fetchActivity();
    });
  }

  @override
  void initState() {
    super.initState();
    _activityFuture = _fetchActivity();
  }

  @override
  Widget build(BuildContext context) {
    return DetailsScaffold(
      title: 'Активность',
      body: FutureBuilder<ActivityModel>(
        future: _activityFuture,
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

          // Состояние успеха - отображение данных активности
          if (snapshot.hasData) {
            final activity = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название активности (если есть)
                    if (activity.name != null) ...[
                      Text(
                        activity.name!,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                    ],
                    // Тип активности
                    Text(
                      'Тип',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.type,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    // Статус активности
                    Text(
                      'Статус',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      activity.status,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 16),
                    // Описание активности (если есть)
                    if (activity.description != null) ...[
                      Text(
                        'Описание',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activity.description!,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }

          // Fallback (не должно произойти)
          return const Center(
            child: Text('Нет данных'),
          );
        },
      ),
    );
  }
}
