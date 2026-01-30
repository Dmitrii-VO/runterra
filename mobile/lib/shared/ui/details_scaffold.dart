import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Единый Scaffold для экранов деталей
/// 
/// Выносит общую структуру AppBar + back navigation.
/// Используется для экранов, которые открываются поверх основного навигационного стека.
/// 
/// Параметры:
/// - title: заголовок в AppBar
/// - body: содержимое экрана
/// 
/// Навигация: использует context.pop() если возможно, иначе context.go('/').
/// Минимальная проверка для корректной работы с GoRouter.
class DetailsScaffold extends StatelessWidget {
  /// Заголовок экрана (отображается в AppBar)
  final String title;

  /// Содержимое экрана (body)
  final Widget body;

  const DetailsScaffold({
    super.key,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: body,
    );
  }
}
