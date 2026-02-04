// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Runterra';

  @override
  String get navMap => 'Map';

  @override
  String get navRun => 'Run';

  @override
  String get navMessages => 'Messages';

  @override
  String get navEvents => 'Events';

  @override
  String get navProfile => 'Profile';

  @override
  String get errorLoadTitle => 'Load error';

  @override
  String get retry => 'Retry';

  @override
  String get errorTimeoutMessage =>
      'Connection timeout.\n\nMake sure:\n1. Backend server is running (npm run dev in backend folder)\n2. Server listens on all interfaces (0.0.0.0)\n3. No network or firewall issues';

  @override
  String get errorConnectionMessage =>
      'Could not connect to server.\n\nMake sure backend server is running and available.';

  @override
  String errorGeneric(String message) {
    return 'Error: $message';
  }

  @override
  String get profileCityRequired =>
      'Set your city in profile to participate in chat';

  @override
  String get messageHint => 'Message...';

  @override
  String messagesLoadError(String error) {
    return 'Error loading messages: $error';
  }

  @override
  String get messagesTitle => 'Messages';

  @override
  String get cityLabel => 'City';

  @override
  String get tabPersonal => 'Personal';

  @override
  String get tabClub => 'Club';

  @override
  String get tabCoach => 'Coach';

  @override
  String get personalChatsEmpty => 'No personal messages yet';

  @override
  String get coachMessagesEmpty => 'No coach messages yet';

  @override
  String get noClubChats => 'No club chats\n\nYou are not in any club yet';

  @override
  String get noNotifications => 'No notifications';

  @override
  String clubChatsLoadError(String error) {
    return 'Error loading club chats: $error';
  }

  @override
  String notificationsLoadError(String error) {
    return 'Error loading notifications: $error';
  }

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileNotFound => 'Profile data not found';

  @override
  String get profileConnectionError =>
      'Could not connect to server.\n\nMake sure:\n1. Backend server is running (npm run dev in backend folder)\n2. For Android emulator use 10.0.2.2:3000\n3. For physical device use your computer IP address';

  @override
  String get logoutTitle => 'Sign out';

  @override
  String get logoutConfirm => 'Are you sure you want to sign out?';

  @override
  String get cancel => 'Cancel';

  @override
  String get logout => 'Sign out';

  @override
  String get headerMercenary => 'Mercenary';

  @override
  String get headerNoClub => 'No club';

  @override
  String get roleMember => 'Member';

  @override
  String get roleModerator => 'Moderator';

  @override
  String get roleLeader => 'Leader';

  @override
  String get quickOpenMap => 'Open map';

  @override
  String get quickFindTraining => 'Find workout';

  @override
  String get quickStartRun => 'Start run';

  @override
  String get quickFindClub => 'Find club';

  @override
  String get quickCreateClub => 'Create club';

  @override
  String get activityNext => 'Next workout';

  @override
  String get activityLast => 'Last activity';

  @override
  String get activityDefaultName => 'Workout';

  @override
  String get activityDefaultActivity => 'Activity';

  @override
  String get openOnMap => 'Open on map';

  @override
  String get activityStatusPlanned => 'Registered';

  @override
  String get activityStatusInProgress => 'In progress';

  @override
  String get activityStatusCompleted => 'Completed';

  @override
  String get activityStatusCancelled => 'Cancelled';

  @override
  String get activityResultCounted => 'Counted';

  @override
  String get activityResultNotCounted => 'Not counted';

  @override
  String get settingsLocation => 'Location';

  @override
  String get settingsLocationAllowed => 'Allowed';

  @override
  String get settingsLocationDenied => 'Not allowed';

  @override
  String get settingsVisibility => 'Profile visibility';

  @override
  String get settingsVisible => 'Visible';

  @override
  String get settingsHidden => 'Hidden';

  @override
  String get settingsLogout => 'Sign out';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get statsTrainings => 'Workouts';

  @override
  String get statsTerritories => 'Territories';

  @override
  String get statsPoints => 'Points';

  @override
  String get notificationsSectionTitle => 'Notifications';

  @override
  String get eventsTitle => 'Events';

  @override
  String get eventsLoadError => 'Error loading events';

  @override
  String get eventsEmpty => 'No events found';

  @override
  String get eventsEmptyHint => 'Try changing filters';

  @override
  String get eventsCreateTodo => 'Create event - TODO';

  @override
  String get eventsCreateTooltip => 'Create event';

  @override
  String get filterToday => 'Today';

  @override
  String get filterTomorrow => 'Tomorrow';

  @override
  String get filter7days => '7 days';

  @override
  String get filterOnlyOpen => 'Open only';

  @override
  String get eventTypeTraining => 'Workout';

  @override
  String get eventTypeGroupRun => 'Group run';

  @override
  String get eventTypeClubEvent => 'Club event';

  @override
  String get eventTypeOpenEvent => 'Open event';

  @override
  String get eventStatusOpen => 'Open';

  @override
  String get eventStatusFull => 'Full';

  @override
  String get eventStatusCancelled => 'Cancelled';

  @override
  String get eventStatusCompleted => 'Completed';

  @override
  String get eventDifficultyBeginner => 'Beginner';

  @override
  String get eventDifficultyIntermediate => 'Intermediate';

  @override
  String get eventDifficultyAdvanced => 'Advanced';

  @override
  String get eventDetailsTitle => 'Event';

  @override
  String get eventDescription => 'Description';

  @override
  String get eventInfo => 'Info';

  @override
  String get eventType => 'Type';

  @override
  String get eventDateTime => 'Date & time';

  @override
  String get eventLocation => 'Location';

  @override
  String get eventOrganizer => 'Organizer';

  @override
  String get eventDifficulty => 'Difficulty';

  @override
  String get eventTerritory => 'Territory';

  @override
  String get eventTerritoryLinked => 'Linked to territory';

  @override
  String get eventStartPoint => 'Start point';

  @override
  String get eventMapTodo => 'Map (TODO)';

  @override
  String get eventParticipation => 'Participation';

  @override
  String get eventJoin => 'Join';

  @override
  String get eventJoinTodo => 'Join event - TODO';

  @override
  String get eventNoPlaces => 'No spots left';

  @override
  String get eventCancelled => 'Event cancelled';

  @override
  String eventOrganizerLabel(String id) {
    return 'Organizer: $id';
  }

  @override
  String participantsTitle(int count) {
    return 'Participants ($count)';
  }

  @override
  String get participantsNone => 'No participants yet';

  @override
  String participantsMore(int count) {
    return 'And $count more participants';
  }

  @override
  String participantN(int n) {
    return 'Participant $n';
  }

  @override
  String get mapTitle => 'Map';

  @override
  String get mapFiltersTooltip => 'Filters';

  @override
  String get mapClubsSheetTitle => 'Clubs';

  @override
  String get mapClubsEmpty => 'No clubs in this city';

  @override
  String get mapMyLocationTooltip => 'My location';

  @override
  String get mapLocationDeniedSnackbar =>
      'Location access not granted. Using default position.';

  @override
  String mapLoadErrorSnackbar(String error) {
    return 'Error loading data: $error';
  }

  @override
  String get mapNoLocationSnackbar => 'No location access';

  @override
  String mapLocationErrorSnackbar(String error) {
    return 'Location error: $error';
  }

  @override
  String get filtersTitle => 'Filters';

  @override
  String get filtersDate => '📅 Date';

  @override
  String get filtersToday => 'Today';

  @override
  String get filtersWeek => 'Week';

  @override
  String get filtersMyClub => '🏃 My club';

  @override
  String get filtersActiveTerritories => '🔥 Active territories only';

  @override
  String get territoryCaptured => 'Captured by club';

  @override
  String get territoryFree => 'Neutral';

  @override
  String get territoryContested => 'Contested';

  @override
  String get territoryLocked => 'Locked';

  @override
  String get territoryUnknown => 'Unknown';

  @override
  String territoryOwnerLabel(String id) {
    return 'Owner club: $id';
  }

  @override
  String get territoryHoldTodo => 'Until hold: TODO';

  @override
  String get territoryViewTrainings => 'View workouts';

  @override
  String get territoryHelpCapture => 'Help capture';

  @override
  String get territoryMore => 'More';

  @override
  String get runTitle => 'Run';

  @override
  String get runStart => 'Start run';

  @override
  String get runFinish => 'Finish';

  @override
  String get runFinishing => 'Finishing...';

  @override
  String get runDone => 'Done 🎉';

  @override
  String get runGpsSearching => 'Searching for signal';

  @override
  String get runGpsRecording => 'Recording';

  @override
  String get runGpsError => 'GPS error';

  @override
  String runForActivity(String activityId) {
    return 'Run will count for workout \"$activityId\"';
  }

  @override
  String get runCountedTraining => 'Workout participation counted';

  @override
  String get runCountedTerritory => 'Territory contribution';

  @override
  String get runReady => 'Done';

  @override
  String get runStartError => 'Error starting run';

  @override
  String get runStartPermissionDenied =>
      'Location permission not granted.\n\nFor Windows: Settings → Privacy → Location → App permissions and enable Runterra.\n\nFor Android: allow location access when prompted.';

  @override
  String get runStartPermanentlyDenied =>
      'Location access blocked.\n\nPlease enable permission in device settings:\nWindows: Settings → Privacy → Location\nAndroid: Settings → Apps → Runterra → Permissions';

  @override
  String get runStartServiceDisabled =>
      'Location service is disabled.\n\nPlease enable location in device settings.';

  @override
  String runStartErrorGeneric(String error) {
    return 'Error starting run:\n$error';
  }

  @override
  String runFinishError(String error) {
    return 'Error finishing run: $error';
  }

  @override
  String get runDuration => 'Duration';

  @override
  String get runDistance => 'Distance';

  @override
  String get runPace => 'Pace';

  @override
  String runPaceValue(String pace) {
    return '$pace/km';
  }

  @override
  String get runAvgSpeed => 'Avg speed';

  @override
  String runAvgSpeedValue(String speed) {
    return '$speed km/h';
  }

  @override
  String get runCalories => 'Calories';

  @override
  String runCaloriesValue(int calories) {
    return '~$calories kcal';
  }

  @override
  String get runHeartRate => 'Heart rate';

  @override
  String runHeartRateValue(int bpm) {
    return '$bpm bpm';
  }

  @override
  String get runNoData => '—';

  @override
  String distanceMeters(String value) {
    return '$value m';
  }

  @override
  String distanceKm(String value) {
    return '$value km';
  }

  @override
  String get loginTitle => 'Runterra';

  @override
  String get loginSubtitle => 'Running app for territory capture';

  @override
  String get loginButton => 'Sign in with Google';

  @override
  String get loginLoading => 'Signing in...';

  @override
  String loginError(String error) {
    return 'Sign-in error: $error';
  }

  @override
  String get noData => 'No data';

  @override
  String get activityDetailsTitle => 'Activity';

  @override
  String get cityDetailsTitle => 'City';

  @override
  String get clubDetailsTitle => 'Club';

  @override
  String get territoryDetailsTitle => 'Territory';

  @override
  String get detailType => 'Type';

  @override
  String get detailStatus => 'Status';

  @override
  String get detailDescription => 'Description';

  @override
  String get detailCoordinates => 'Coordinates';

  @override
  String detailLatLng(String lat, String lng) {
    return 'Latitude: $lat\nLongitude: $lng';
  }

  @override
  String get detailCoordinatesCenter => 'Center coordinates';

  @override
  String get detailCity => 'City';

  @override
  String get detailCapturedBy => 'Captured by player';

  @override
  String get eventTerritoryLabel => 'Territory';

  @override
  String clubLabel(String id) {
    return 'Club: $id';
  }

  @override
  String trainerLabel(String id) {
    return 'Coach: $id';
  }

  @override
  String get cityPickerTitle => 'Select city';

  @override
  String cityPickerLoadError(String error) {
    return 'Failed to load cities:\n$error';
  }

  @override
  String get cityPickerEmpty => 'City list is empty';

  @override
  String get cityNotSelected => 'Not selected';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileName => 'Name';

  @override
  String get editProfilePhotoUrl => 'Photo URL';

  @override
  String get editProfileSave => 'Save';

  @override
  String get editProfileNameRequired => 'Name is required';

  @override
  String get editProfileEditAction => 'Edit';

  @override
  String get createClubTitle => 'Create club';

  @override
  String get createClubNameHint => 'Club name';

  @override
  String get createClubDescriptionHint => 'Description (optional)';

  @override
  String get createClubSave => 'Create';

  @override
  String get createClubNameRequired => 'Club name is required';

  @override
  String get createClubCityRequired => 'Select your city in profile first';

  @override
  String createClubError(String message) {
    return 'Could not create club: $message';
  }

  @override
  String get runStuckSessionTitle => 'Run in progress';

  @override
  String get runStuckSessionMessage =>
      'You have an unfinished run. Would you like to continue it or start fresh?';

  @override
  String get runStuckSessionResume => 'Continue run';

  @override
  String get runStuckSessionCancel => 'Discard and start new';
}
