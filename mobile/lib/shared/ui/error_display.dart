import 'package:flutter/material.dart';

/// Общий виджет для отображения ошибок загрузки данных
/// 
/// Устраняет дублирование кода обработки ошибок в detail screens.
/// Предоставляет единообразное отображение ошибок с понятными сообщениями.
class ErrorDisplay extends StatelessWidget {
  /// Сообщение об ошибке (обычно из snapshot.error.toString())
  final String errorMessage;
  
  /// Опциональный заголовок ошибки
  final String? title;
  
  /// Callback для повторной попытки загрузки
  final VoidCallback? onRetry;

  const ErrorDisplay({
    super.key,
    required this.errorMessage,
    this.title,
    this.onRetry,
  });

  /// Преобразует техническое сообщение об ошибке в понятное для пользователя
  static String _getUserFriendlyMessage(String errorMessage) {
    if (errorMessage.contains('TimeoutException') ||
        errorMessage.contains('Semaphore timeout') ||
        errorMessage.contains('превысил таймаут')) {
      return 'Превышен таймаут подключения.\n\n'
          'Убедитесь, что:\n'
          '1. Backend сервер запущен (npm run dev в папке backend)\n'
          '2. Сервер слушает на всех интерфейсах (0.0.0.0)\n'
          '3. Нет проблем с сетью или файрволом';
    } else if (errorMessage.contains('SocketException') ||
        errorMessage.contains('connection refused') ||
        errorMessage.contains('отклонил это сетевое подключение')) {
      return 'Не удалось подключиться к серверу.\n\n'
          'Убедитесь, что backend сервер запущен и доступен.';
    } else {
      return 'Ошибка: $errorMessage';
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMessage = _getUserFriendlyMessage(errorMessage);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              title ?? 'Ошибка загрузки',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              userMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Повторить'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
