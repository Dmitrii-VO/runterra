import 'package:flutter/material.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/club_model.dart';
import '../../shared/ui/details_scaffold.dart';
import '../../shared/ui/error_display.dart';

/// Экран деталей клуба
///
/// Отображает информацию о клубе, загружая данные через ClubsService.
/// Использует FutureBuilder для отображения состояний loading/error/success.
/// 
/// Принимает clubId через параметр маршрута и загружает данные клуба.
class ClubDetailsScreen extends StatefulWidget {
  /// ID клуба (передается через параметр маршрута)
  final String clubId;

  const ClubDetailsScreen({
    super.key,
    required this.clubId,
  });

  /// Создает Future для получения данных о клубе
  /// 
  /// TODO: Backend URL вынести в конфигурацию
  /// 
  /// Примечание: Для Android эмулятора используется 10.0.2.2 вместо localhost.
  /// Для физического устройства используйте IP адрес хост-машины в локальной сети.
  @override
  State<ClubDetailsScreen> createState() => _ClubDetailsScreenState();
}

class _ClubDetailsScreenState extends State<ClubDetailsScreen> {
  /// Future for club details.
  late Future<ClubModel> _clubFuture;

  /// Creates Future for loading club data.
  Future<ClubModel> _fetchClub() async {
    return ServiceLocator.clubsService.getClubById(widget.clubId);
  }
  
  /// Reload data
  void _retry() {
    setState(() {
      _clubFuture = _fetchClub();
    });
  }

  @override
  void initState() {
    super.initState();
    _clubFuture = _fetchClub();
  }

  @override
  Widget build(BuildContext context) {
    return DetailsScaffold(
      title: 'Клуб',
      body: FutureBuilder<ClubModel>(
        future: _clubFuture,
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

          // Состояние успеха - отображение данных клуба
          if (snapshot.hasData) {
            final club = snapshot.data!;
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Название клуба
                    Text(
                      club.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 16),
                    // Описание клуба (если есть)
                    if (club.description != null) ...[
                      Text(
                        'Описание',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        club.description!,
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
