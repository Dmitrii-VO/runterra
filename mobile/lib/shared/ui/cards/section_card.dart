import 'package:flutter/material.dart';

/// Универсальный UI-компонент-контейнер для секций
/// 
/// Простой StatelessWidget без логики и состояний.
/// Используется как обертка для группировки контента в карточки.
/// 
/// Использование:
/// ```dart
/// SectionCard(
///   title: 'Заголовок секции',
///   child: YourContentWidget(),
/// )
/// ```
class SectionCard extends StatelessWidget {
  /// Заголовок секции (опционально)
  final String? title;

  /// Дочерний виджет с содержимым секции
  final Widget child;

  /// Отступы внутри карточки
  final EdgeInsetsGeometry? padding;

  const SectionCard({
    super.key,
    this.title,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) ...[
              Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}
