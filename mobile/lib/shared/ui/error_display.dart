import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

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

  /// Returns user-friendly message key or builds message from l10n.
  static String _getUserFriendlyMessage(BuildContext context, String errorMessage) {
    final l10n = AppLocalizations.of(context)!;
    if (errorMessage.contains('TimeoutException') ||
        errorMessage.contains('Semaphore timeout') ||
        errorMessage.contains('превысил таймаут')) {
      return l10n.errorTimeoutMessage;
    } else if (errorMessage.contains('SocketException') ||
        errorMessage.contains('connection refused') ||
        errorMessage.contains('отклонил это сетевое подключение')) {
      return l10n.errorConnectionMessage;
    } else {
      return l10n.errorGeneric(errorMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userMessage = _getUserFriendlyMessage(context, errorMessage);
    final l10n = AppLocalizations.of(context)!;

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
              title ?? l10n.errorLoadTitle,
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
                label: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
