import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'l10n/app_localizations.dart';
import 'features/activity/activity_details_screen.dart';
import 'features/city/city_details_screen.dart';
import 'features/club/club_details_screen.dart';
import 'features/club/clubs_list_screen.dart';
import 'features/club/club_schedule_screen.dart';
import 'features/club/club_roster_screen.dart';
import 'features/club/personal_schedule_screen.dart';
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
import 'features/messages/chat_screen.dart';
import 'features/events/events_screen.dart';
import 'features/events/event_details_screen.dart';
import 'features/events/create_event_screen.dart';
import 'features/events/edit_event_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/profile/edit_profile_screen.dart';
import 'features/profile/my_clubs_screen.dart';
import 'features/trainer/trainer_profile_screen.dart';
import 'features/trainer/trainer_edit_profile_screen.dart';
import 'features/trainer/trainers_list_screen.dart';
import 'features/trainer/workouts_list_screen.dart';
import 'features/trainer/workout_detail_screen.dart';
import 'features/trainer/workout_form_screen.dart';
import 'features/trainer/create_trainer_group_screen.dart';
import 'features/trainer/client_runs_screen.dart';
import 'features/trainer/trainer_requests_screen.dart';
import 'features/trainer/my_trainers_screen.dart';
import 'features/people/people_search_screen.dart';
import 'features/people/public_profile_screen.dart';
import 'shared/models/profile_model.dart' show ProfileUserData;
import 'shared/models/user_search_result_model.dart';
import 'shared/models/club_model.dart';
import 'shared/models/club_member_model.dart';
import 'shared/models/trainer_group_model.dart';
import 'shared/models/workout.dart';
import 'shared/models/trainer_profile.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'shared/api/version_service.dart';
import 'shared/auth/auth_service.dart';
import 'shared/di/service_locator.dart';
import 'shared/navigation/bottom_nav.dart';
import 'shared/ui/update_dialog.dart';

/// Notifier for auth state changes; when [refresh] is called, GoRouter refreshes (e.g. redirect).
/// Called from AuthService listener when auth state changes.
class AuthRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final authRefreshNotifier = AuthRefreshNotifier();

/// Main application widget for Runterra.
///
/// Uses GoRouter for navigation. Checks for app updates once after first frame.
class RunterraApp extends StatefulWidget {
  const RunterraApp({super.key});

  @override
  State<RunterraApp> createState() => _RunterraAppState();
}

class _RunterraAppState extends State<RunterraApp> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _appVersion = 'v${info.version}');
    });
  }

  Future<void> _checkForUpdate() async {
    final update = await VersionService.checkForUpdate();
    if (update == null) return;
    final ctx = _router.routerDelegate.navigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (_) => UpdateDialog(
        currentVersion: update.currentVersion,
        latestVersion: update.latestVersion,
      ),
    );
  }

  static final GoRouter _router = GoRouter(
    initialLocation: '/', // Profile — entry point
    refreshListenable: authRefreshNotifier,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
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
                  final assignmentId = state.uri.queryParameters['assignmentId'];
                  return RunScreen(activityId: activityId, assignmentId: assignmentId);
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
        path: '/club/:id/schedule',
        builder: (context, state) {
          final clubId = state.pathParameters['id'] ?? '';
          return ClubScheduleScreen(clubId: clubId);
        },
      ),
      GoRoute(
        path: '/club/:id/roster',
        builder: (context, state) {
          final clubId = state.pathParameters['id'] ?? '';
          return ClubRosterScreen(clubId: clubId);
        },
      ),
      GoRoute(
        path: '/club/:id/members/:userId/plan',
        builder: (context, state) {
          final clubId = state.pathParameters['id'] ?? '';
          final userId = state.pathParameters['userId'] ?? '';
          final member = state.extra as ClubMemberModel;
          return PersonalScheduleScreen(
            clubId: clubId,
            userId: userId,
            member: member,
          );
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
        builder: (context, state) {
          final initialType = state.uri.queryParameters['type'];
          return CreateEventScreen(initialType: initialType);
        },
      ),
      GoRoute(
        path: '/event/:id',
        builder: (context, state) {
          final eventId = state.pathParameters['id'] ?? '';
          return EventDetailsScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/event/:id/edit',
        builder: (context, state) {
          final eventId = state.pathParameters['id'] ?? '';
          return EditEventScreen(eventId: eventId);
        },
      ),
      GoRoute(
        path: '/trainers',
        builder: (context, state) => const TrainersListScreen(),
      ),
      GoRoute(
        path: '/trainer/edit',
        builder: (context, state) {
          final profile = state.extra as TrainerProfile?;
          return TrainerEditProfileScreen(existingProfile: profile);
        },
      ),
      GoRoute(
        path: '/trainer/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId'] ?? '';
          return TrainerProfileScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/workouts',
        builder: (context, state) => const WorkoutsListScreen(),
      ),
      GoRoute(
        path: '/workouts/create',
        builder: (context, state) => const WorkoutFormScreen(),
      ),
      GoRoute(
        path: '/workouts/:id',
        builder: (context, state) {
          final workout = state.extra as Workout;
          return WorkoutDetailScreen(workout: workout);
        },
      ),
      GoRoute(
        path: '/workouts/:id/edit',
        builder: (context, state) {
          final workout = state.extra as Workout?;
          return WorkoutFormScreen(existing: workout);
        },
      ),
      GoRoute(
        path: '/trainer/groups/create',
        builder: (context, state) {
          final clubId = state.uri.queryParameters['clubId'] ?? '';
          final clubName = state.uri.queryParameters['clubName'] ?? '';
          final trainerId = state.uri.queryParameters['trainerId'];
          final trainerName = state.uri.queryParameters['trainerName'];
          final group = state.extra as TrainerGroupModel?;
          return CreateTrainerGroupScreen(
            clubId: clubId,
            clubName: clubName,
            existingGroup: group,
            forcedTrainerId: trainerId,
            forcedTrainerName: trainerName,
          );
        },
      ),
      GoRoute(
        path: '/chat/:type/:id',
        builder: (context, state) {
          final type = state.pathParameters['type'] ?? '';
          final id = state.pathParameters['id'] ?? '';
          final title = state.uri.queryParameters['title'] ?? 'Chat';
          return ChatScreen(channelType: type, channelId: id, title: title);
        },
      ),
      GoRoute(
        path: '/people',
        builder: (context, state) => const PeopleSearchScreen(),
      ),
      GoRoute(
        path: '/user/:id',
        builder: (context, state) => PublicProfileScreen(
          userId: state.pathParameters['id']!,
          preload: state.extra as UserSearchResult?,
        ),
      ),
      GoRoute(
        path: '/trainer/clients/:clientId/runs',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>;
          return ClientRunsScreen(
            clientId: state.pathParameters['clientId']!,
            clientName: extra['clientName'] ?? '',
          );
        },
      ),
      GoRoute(
        path: '/trainer/requests',
        builder: (context, state) => const TrainerRequestsScreen(),
      ),
      GoRoute(
        path: '/my-trainers',
        builder: (context, state) => const MyTrainersScreen(),
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
      locale: const Locale('ru'), // Forced Russian locale
      routerConfig: _router,
      builder: (context, child) {
        final statusBarHeight = MediaQuery.of(context).padding.top;
        return Stack(
          children: [
            child!,
            if (_appVersion.isNotEmpty)
              Positioned(
                top: statusBarHeight > 0 ? (statusBarHeight - 14) / 2 : 4,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    _appVersion,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.black45,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
