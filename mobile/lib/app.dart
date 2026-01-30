import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'features/activity/activity_details_screen.dart';
import 'features/city/city_details_screen.dart';
import 'features/club/club_details_screen.dart';
import 'features/territory/territory_details_screen.dart';
import 'features/map/map_screen.dart';
import 'features/run/run_screen.dart';
import 'features/messages/messages_screen.dart';
import 'features/events/events_screen.dart';
import 'features/events/event_details_screen.dart';
import 'features/profile/profile_screen.dart';
import 'shared/navigation/bottom_nav.dart';

/// Notifier for auth state changes; when [refresh] is called, GoRouter refreshes (e.g. redirect).
/// On skeleton: no real auth yet — call refresh() from Firebase auth listener when added.
class AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final authRefreshNotifier = AuthRefreshNotifier();

/// Main application widget for Runterra
/// Uses GoRouter for navigation
class RunterraApp extends StatelessWidget {
  const RunterraApp({super.key});

  /// Настройка маршрутов GoRouter
  /// 
  /// Маршруты через BottomNav:
  /// - /map - MapScreen (index 0)
  /// - /run - RunScreen (index 1); /run?activityId=... — задел под привязку к тренировке
  /// - /messages - MessagesScreen (index 2)
  /// - /events - EventsScreen (index 3)
  /// - / - ProfileScreen (index 4)
  ///
  /// ProfileScreen = точка входа после логина, центр личного кабинета.
  /// initialLocation: '/' — открываем профиль. Всегда доступен из TabBar.
  ///
  /// Отдельные маршруты (без BottomNav):
  /// - /club/:id - ClubDetailsScreen (отдельный экран с параметром clubId)
  /// - /city/:id - CityDetailsScreen (отдельный экран с параметром cityId)
  /// - /territory/:id - TerritoryDetailsScreen (отдельный экран с параметром territoryId)
  /// - /activity/:id - ActivityDetailsScreen (отдельный экран с параметром activityId)
  /// - /event/:id - EventDetailsScreen (отдельный экран с параметром eventId)
  static final GoRouter _router = GoRouter(
    initialLocation: '/', // Profile — entry point
    refreshListenable: authRefreshNotifier,
    routes: [
      // ShellRoute для BottomNav (Map, Run, Messages, Events, Profile)
      ShellRoute(
        builder: (context, state, child) {
          // Определяем текущий индекс на основе маршрута
          int currentIndex = 0;
          final path = state.uri.path;
          if (path == '/map') {
            currentIndex = 0; // Map
          } else if (path == '/run') {
            currentIndex = 1; // Run
          } else if (path == '/messages') {
            currentIndex = 2; // Messages
          } else if (path == '/events') {
            currentIndex = 3; // Events
          } else if (path == '/') {
            currentIndex = 4; // Profile
          }
          
          return BottomNav(
            currentIndex: currentIndex,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/run',
            builder: (context, state) {
              final activityId = state.uri.queryParameters['activityId'];
              return RunScreen(activityId: activityId);
            },
          ),
          GoRoute(
            path: '/messages',
            builder: (context, state) => const MessagesScreen(),
          ),
          GoRoute(
            path: '/events',
            builder: (context, state) => const EventsScreen(),
          ),
          GoRoute(
            path: '/',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      // Отдельный маршрут для ClubDetailsScreen (без BottomNav)
      GoRoute(
        path: '/club/:id',
        builder: (context, state) {
          final clubId = state.pathParameters['id'] ?? '';
          return ClubDetailsScreen(clubId: clubId);
        },
      ),
      // Отдельный маршрут для CityDetailsScreen (без BottomNav)
      GoRoute(
        path: '/city/:id',
        builder: (context, state) {
          final cityId = state.pathParameters['id'] ?? '';
          return CityDetailsScreen(cityId: cityId);
        },
      ),
      // Отдельный маршрут для TerritoryDetailsScreen (без BottomNav)
      GoRoute(
        path: '/territory/:id',
        builder: (context, state) {
          final territoryId = state.pathParameters['id'] ?? '';
          return TerritoryDetailsScreen(territoryId: territoryId);
        },
      ),
      // Отдельный маршрут для ActivityDetailsScreen (без BottomNav)
      GoRoute(
        path: '/activity/:id',
        builder: (context, state) {
          final activityId = state.pathParameters['id'] ?? '';
          return ActivityDetailsScreen(activityId: activityId);
        },
      ),
      // Отдельный маршрут для EventDetailsScreen (без BottomNav)
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id'] ?? '';
          return EventDetailsScreen(eventId: eventId);
        },
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Runterra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}
