import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'l10n/app_localizations.dart';
import 'features/activity/activity_details_screen.dart';
import 'features/city/city_details_screen.dart';
import 'features/club/club_details_screen.dart';
import 'features/club/clubs_list_screen.dart';
import 'features/map/location_picker_screen.dart';
import 'features/club/transfer_leadership_screen.dart';
import 'features/club/create_club_screen.dart';
import 'features/club/edit_club_screen.dart';
import 'features/login/login_screen.dart';
import 'features/territory/territory_details_screen.dart';
import 'features/map/map_screen.dart';
import 'features/run/run_screen.dart';
import 'features/run/run_detail_screen.dart';
import 'features/messages/messages_screen.dart';
import 'features/events/events_screen.dart';
import 'features/events/event_details_screen.dart';
import 'features/events/create_event_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/my_clubs_screen.dart';
import 'shared/models/profile_model.dart';
import 'shared/models/club_model.dart';
import 'shared/auth/auth_service.dart';
import 'shared/di/service_locator.dart';
import 'shared/navigation/bottom_nav.dart';

/// Notifier for auth state changes; when [refresh] is called, GoRouter refreshes (e.g. redirect).
/// Called from AuthService listener when auth state changes.
class AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final authRefreshNotifier = AuthRefreshNotifier();

/// Main application widget for Runterra.
///
/// Uses GoRouter for navigation.
class RunterraApp extends StatelessWidget {
  const RunterraApp({super.key});

  static final GoRouter _router = GoRouter(
    initialLocation: '/', // Profile — entry point
    refreshListenable: authRefreshNotifier,
    redirect: (context, state) async {
      final isAuthenticated = AuthService.instance.isAuthenticated;
      final isLoginRoute = state.matchedLocation == '/login';

      if (!isAuthenticated && !isLoginRoute) {
        return '/login';
      }

      if (isAuthenticated && isLoginRoute) {
        // Refresh token in ApiClient after successful login.
        await ServiceLocator.refreshAuthToken();
        return '/';
      }

      if (isAuthenticated && !isLoginRoute) {
        await ServiceLocator.refreshAuthToken();
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Bottom tabs (Map, Run, Messages, Events, Profile).
      //
      // StatefulShellRoute keeps each tab alive, so switching tabs does not
      // dispose and reset state (e.g. currently opened chat in Messages tab).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BottomNav(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/map',
                builder: (context, state) {
                  final showClubs =
                      state.uri.queryParameters['showClubs'] == 'true';
                  final latStr = state.uri.queryParameters['lat'];
                  final lonStr = state.uri.queryParameters['lon'];
                  final focusLat =
                      latStr != null ? double.tryParse(latStr) : null;
                  final focusLon =
                      lonStr != null ? double.tryParse(lonStr) : null;
                  return MapScreen(
                    showClubs: showClubs,
                    focusLatitude: focusLat,
                    focusLongitude: focusLon,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/run',
                builder: (context, state) {
                  final activityId = state.uri.queryParameters['activityId'];
                  return RunScreen(activityId: activityId);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/messages',
                builder: (context, state) {
                  final tab = state.uri.queryParameters['tab'];
                  final clubId = state.uri.queryParameters['clubId'];
                  final initialTabIndex =
                      tab == 'club' ? 1 : (tab == 'coach' ? 2 : 0);
                  return MessagesScreen(
                    initialTabIndex: initialTabIndex,
                    initialClubId: clubId,
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/events',
                builder: (context, state) => const EventsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // Routes without BottomNav.
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) {
          final user = state.extra as ProfileUserData;
          return EditProfileScreen(user: user);
        },
      ),
      GoRoute(
        path: '/profile/clubs',
        builder: (context, state) => const MyClubsScreen(),
      ),
      GoRoute(
        path: '/clubs',
        builder: (context, state) {
          final cityId = state.uri.queryParameters['cityId'] ?? '';
          return ClubsListScreen(cityId: cityId);
        },
      ),
      GoRoute(
        path: '/run/detail/:id',
        builder: (context, state) {
          final runId = state.pathParameters['id'] ?? '';
          return RunDetailScreen(runId: runId);
        },
      ),
      GoRoute(
        path: '/club/create',
        builder: (context, state) => const CreateClubScreen(),
      ),
      GoRoute(
        path: '/club/:id',
        builder: (context, state) {
          final clubId = state.pathParameters['id'] ?? '';
          return ClubDetailsScreen(clubId: clubId);
        },
      ),
      GoRoute(
        path: '/club/:id/transfer-leadership',
        builder: (context, state) {
          final clubId = state.pathParameters['id'] ?? '';
          return TransferLeadershipScreen(clubId: clubId);
        },
      ),
      GoRoute(
        path: '/club/:id/edit',
        builder: (context, state) {
          final club = state.extra as ClubModel;
          return EditClubScreen(club: club);
        },
      ),
      GoRoute(
        path: '/city/:id',
        builder: (context, state) {
          final cityId = state.pathParameters['id'] ?? '';
          return CityDetailsScreen(cityId: cityId);
        },
      ),
      GoRoute(
        path: '/territory/:id',
        builder: (context, state) {
          final territoryId = state.pathParameters['id'] ?? '';
          return TerritoryDetailsScreen(territoryId: territoryId);
        },
      ),
      GoRoute(
        path: '/activity/:id',
        builder: (context, state) {
          final activityId = state.pathParameters['id'] ?? '';
          return ActivityDetailsScreen(activityId: activityId);
        },
      ),
      GoRoute(
        path: '/map/pick',
        builder: (context, state) {
          final lat =
              double.tryParse(state.uri.queryParameters['lat'] ?? '') ?? 59.93;
          final lon =
              double.tryParse(state.uri.queryParameters['lon'] ?? '') ?? 30.33;
          return LocationPickerScreen(
            initialLatitude: lat,
            initialLongitude: lon,
          );
        },
      ),
      GoRoute(
        path: '/event/create',
        builder: (context, state) => const CreateEventScreen(),
      ),
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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: (locale, supported) {
        for (final l in supported) {
          if (l.languageCode == locale?.languageCode) return l;
        }
        return const Locale('ru');
      },
      routerConfig: _router,
    );
  }
}

