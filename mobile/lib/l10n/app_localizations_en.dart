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
  String get navRun => 'Training';

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
  String get personalChatsEmpty => 'Personal chats — coming soon';

  @override
  String get coachMessagesEmpty => 'Coach messages — coming soon';

  @override
  String get noClubChats => 'No club chats\n\nYou are not in any club yet';

  @override
  String get messagesBackToClubs => 'Back to clubs';

  @override
  String get messagesSelectClub => 'Select a club to chat';

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
  String get roleTrainer => 'Trainer';

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
  String get profileMyClubsButton => 'Clubs';

  @override
  String get profileMyClubsTitle => 'My clubs';

  @override
  String get profileMyClubsEmpty => 'You are not in any clubs yet';

  @override
  String profileMyClubsLoadError(String error) {
    return 'Could not load clubs: $error';
  }

  @override
  String get profileMyClub => 'My club';

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
  String get activityNoActivities =>
      'No upcoming workouts. Find an event on the map!';

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
  String get deleteAccountTitle => 'Delete account';

  @override
  String get deleteAccountConfirm =>
      'Delete your account permanently? This cannot be undone. All your data will be removed.';

  @override
  String get deleteAccountConfirmButton => 'Delete';

  @override
  String get statsTrainings => 'Workouts';

  @override
  String get statsTerritories => 'Territories';

  @override
  String get statsKm => 'Km';

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
  String get eventCreateTitle => 'Create event';

  @override
  String get eventCreateName => 'Event name';

  @override
  String get eventCreateNameRequired => 'Event name is required';

  @override
  String get eventCreateType => 'Event type';

  @override
  String get eventCreateDate => 'Date';

  @override
  String get eventCreateTime => 'Time';

  @override
  String get eventCreateCity => 'City';

  @override
  String get eventCreateCityRequired => 'Select a city in profile first';

  @override
  String get eventCreateOrganizerId => 'Organizer ID';

  @override
  String get eventCreateOrganizerRequired => 'Organizer is required';

  @override
  String get eventCreateOrganizerType => 'Organizer type';

  @override
  String get eventCreateOrganizerClub => 'Club';

  @override
  String get eventCreateOrganizerTrainer => 'Trainer';

  @override
  String get eventCreateLocationName => 'Location name';

  @override
  String get eventCreateLatitude => 'Latitude';

  @override
  String get eventCreateLongitude => 'Longitude';

  @override
  String get eventCreateCoordinatesRequired => 'Coordinates are required';

  @override
  String get eventCreateCoordinatesInvalid => 'Invalid coordinates';

  @override
  String get eventCreateParticipantLimit => 'Participant limit';

  @override
  String get eventCreateLimitInvalid => 'Invalid participant limit';

  @override
  String get eventCreateDescription => 'Description';

  @override
  String get eventCreateSave => 'Create';

  @override
  String get eventCreateSuccess => 'Event created';

  @override
  String eventCreateError(String message) {
    return 'Could not create event: $message';
  }

  @override
  String get filterToday => 'Today';

  @override
  String get filterTomorrow => 'Tomorrow';

  @override
  String get filter7days => '7 days';

  @override
  String get filterOnlyOpen => 'Open only';

  @override
  String get filterParticipantOnly => 'Participating';

  @override
  String get filterAll => 'All';

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
  String get eventJoinTodo => 'Joining...';

  @override
  String get eventJoinInProgress => 'Joining...';

  @override
  String get eventJoinSuccess => 'You are registered';

  @override
  String eventJoinError(String message) {
    return 'Could not join: $message';
  }

  @override
  String get eventYouAreRegistered => 'You are registered';

  @override
  String get eventYouParticipate => 'You participate';

  @override
  String get eventLeave => 'Cancel participation';

  @override
  String get eventLeaveSuccess => 'Participation cancelled';

  @override
  String eventLeaveError(String message) {
    return 'Could not cancel: $message';
  }

  @override
  String get eventCheckInSuccess => 'Check-in successful';

  @override
  String eventCheckInError(String message) {
    return 'Could not check in: $message';
  }

  @override
  String get eventSwipeToRunTitle => 'Swipe to start run';

  @override
  String get eventSwipeToRunHint => 'Swipe left to check in and start your run';

  @override
  String get eventSwipeToRunSuccess => 'Check-in successful! Run started.';

  @override
  String eventSwipeToRunError(String error) {
    return 'Error: $error';
  }

  @override
  String get eventSwipeToRunAlreadyCheckedIn => 'You have already checked in';

  @override
  String get eventSwipeToRunTooEarly =>
      'Check-in opens 30 minutes before the event';

  @override
  String get eventSwipeToRunTooLate => 'Check-in window has closed';

  @override
  String get eventSwipeToRunTooFar =>
      'Move closer to the start point (within 500 m)';

  @override
  String get eventSwipeToRunLocationError => 'Could not get your location';

  @override
  String get eventSwipeToRunCheckingLocation => 'Checking location...';

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
  String territoryLeading(String km) {
    return 'Contested (You are leading: $km km)';
  }

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
  String get runStart => 'Start';

  @override
  String get runPause => 'Pause';

  @override
  String get runResume => 'Resume';

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
  String get runFindMe => 'Find me';

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
  String get clubRequestJoin => 'Apply to join';

  @override
  String get clubRequestPending => 'Request pending';

  @override
  String get clubRequestApprove => 'Approved';

  @override
  String get clubRequestReject => 'Rejected';

  @override
  String get clubMembershipRequests => 'Membership requests';

  @override
  String get clubJoin => 'Join';

  @override
  String get clubJoinSuccess => 'You joined the club';

  @override
  String clubJoinError(String message) {
    return 'Could not join: $message';
  }

  @override
  String get clubYouAreMember => 'You are a member';

  @override
  String get clubLeave => 'Leave club';

  @override
  String get clubLeaveSuccess => 'You left the club';

  @override
  String clubLeaveError(String message) {
    return 'Could not leave: $message';
  }

  @override
  String get clubChatButton => 'Club chat';

  @override
  String get clubMembersLabel => 'Members';

  @override
  String get clubTerritoriesLabel => 'Territories';

  @override
  String get clubCityRankLabel => 'City rank';

  @override
  String get clubMetricPlaceholder => '—';

  @override
  String clubLeaderboardSubtitle(int members, int territories) {
    return 'Members: $members, Territories: $territories';
  }

  @override
  String clubLeaderboardPoints(int points) {
    return '$points pts';
  }

  @override
  String get clubActivationHint =>
      'Add 1 more member to activate the club and participate in territory capture.';

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
  String get editProfileFirstName => 'First name';

  @override
  String get editProfileLastName => 'Last name';

  @override
  String get editProfileBirthDate => 'Birth date';

  @override
  String get editProfileCountry => 'Country';

  @override
  String get editProfileGender => 'Gender';

  @override
  String get editProfileCity => 'City';

  @override
  String get editProfilePhotoUrl => 'Photo URL';

  @override
  String get editProfileSave => 'Save';

  @override
  String get editProfileNameRequired => 'Name is required';

  @override
  String get editProfileEditAction => 'Edit';

  @override
  String get profilePersonalInfoTitle => 'Personal info';

  @override
  String get profileFirstNameLabel => 'First name';

  @override
  String get profileLastNameLabel => 'Last name';

  @override
  String get profileBirthDateLabel => 'Birth date';

  @override
  String get profileCountryLabel => 'Country';

  @override
  String get profileGenderLabel => 'Gender';

  @override
  String get profileCityLabel => 'City';

  @override
  String get profileNotSpecified => 'Not specified';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderOther => 'Other';

  @override
  String get genderUnknown => 'Prefer not to say';

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

  @override
  String get editClubTitle => 'Edit Club';

  @override
  String get editClubName => 'Club Name';

  @override
  String get editClubDescription => 'Description';

  @override
  String get editClubNameHelperText => 'characters';

  @override
  String get editClubDescriptionHelperText => 'Optional, up to 500 characters';

  @override
  String get editClubNameError => 'Name must be 3-50 characters';

  @override
  String get editClubSave => 'Save';

  @override
  String get editClubError => 'Failed to update club';

  @override
  String get clubEditButton => 'Edit Club';

  @override
  String get clubManagementTitle => 'Trainer Management';

  @override
  String get clubManageSchedule => 'Weekly Schedule';

  @override
  String get clubManageRoster => 'Roster & Plans';

  @override
  String get clubMembersTitle => 'Members';

  @override
  String get clubMembersEmpty => 'No members yet';

  @override
  String get clubMembersLoadError => 'Could not load members';

  @override
  String get clubMemberRoleChange => 'Change role';

  @override
  String get clubMemberRoleChangeSuccess => 'Role updated';

  @override
  String clubMemberRoleChangeError(String message) {
    return 'Could not update role: $message';
  }

  @override
  String get rosterTitle => 'Club Roster';

  @override
  String get rosterNoTrainer => 'Unassigned';

  @override
  String get rosterPersonalClient => 'Personal client';

  @override
  String get rosterAssignTrainer => 'Assign trainer';

  @override
  String get rosterRemoveTrainer => 'Remove trainer';

  @override
  String get rosterAddToGroup => 'Add to group';

  @override
  String get rosterRemoveFromGroup => 'Remove from group';

  @override
  String get rosterSelectTrainer => 'Select trainer';

  @override
  String get rosterSelectGroup => 'Select group';

  @override
  String get rosterAssignmentUpdated => 'Assignment updated';

  @override
  String get scheduleTitle => 'Schedule Template';

  @override
  String get planTypeClub => 'Club';

  @override
  String get planTypePersonal => 'Personal';

  @override
  String get eventOpenOnMap => 'Open on map';

  @override
  String get eventCreateSelectCity => 'Select city';

  @override
  String get clubFounder => 'Founder';

  @override
  String get clubsListTitle => 'City clubs';

  @override
  String get clubsListEmpty => 'No clubs yet';

  @override
  String get clubsListAllClubs => 'All city clubs';

  @override
  String get clubEventsTitle => 'Upcoming events';

  @override
  String get clubEventsEmpty => 'No upcoming events';

  @override
  String get clubEventsError => 'Failed to load';

  @override
  String get clubEventsViewAll => 'All club events';

  @override
  String get eventCreatePickLocation => 'Pick on map';

  @override
  String get eventCreateLocationSelected => 'Location selected';

  @override
  String get eventCreateLocationRequired => 'Select a start point';

  @override
  String get eventCreateLocationOutOfCity =>
      'Selected location is outside the city bounds. Pick a point closer to the city.';

  @override
  String get locationPickerTitle => 'Pick location';

  @override
  String get locationPickerConfirm => 'Confirm';

  @override
  String get locationPickerSearchHint => 'Search address...';

  @override
  String get leaderCannotLeave => 'Transfer leadership first';

  @override
  String get transferLeadership => 'Transfer leadership';

  @override
  String get disbandClub => 'Disband club';

  @override
  String get disbandConfirm => 'Are you sure? This cannot be undone.';

  @override
  String get selectNewLeader => 'Select new leader';

  @override
  String get transferSuccess => 'Leadership transferred';

  @override
  String get disbandSuccess => 'Club disbanded';

  @override
  String get runHistoryTitle => 'Training Journal';

  @override
  String get runHistoryEmpty => 'No runs yet';

  @override
  String get runHistoryEmptyHint => 'Start your first run to see it here';

  @override
  String get runHistoryToday => 'Today';

  @override
  String get runHistoryYesterday => 'Yesterday';

  @override
  String get runStatsTitle => 'Statistics';

  @override
  String get runStatsTotalRuns => 'Runs';

  @override
  String get runStatsTotalDistance => 'Total distance';

  @override
  String get runStatsAvgPace => 'Avg pace';

  @override
  String get runDetailTitle => 'Run details';

  @override
  String get runDetailLoadError => 'Could not load run details';

  @override
  String get runGpsPoints => 'GPS points';

  @override
  String get tierGreen => 'Green Zone';

  @override
  String get tierBlue => 'Blue Zone';

  @override
  String get tierRed => 'Red Zone';

  @override
  String get tierBlack => 'Black Zone';

  @override
  String get tierLabelNovice => 'Novice';

  @override
  String get tierLabelAdvanced => 'Advanced';

  @override
  String get tierLabelSpecialist => 'Specialist';

  @override
  String get tierLabelElite => 'Elite';

  @override
  String zoneCaptured(String clubName) {
    return 'Controlled by $clubName';
  }

  @override
  String get zoneOpenSeason => 'Open Season';

  @override
  String get zoneContested => 'Contested';

  @override
  String paceBonus(String pace, String multiplier) {
    return 'Pace < $pace → x$multiplier';
  }

  @override
  String zoneBountyLabel(String bounty) {
    return 'x$bounty Points';
  }

  @override
  String seasonResetIn(int days) {
    return 'Reset in ${days}d';
  }

  @override
  String runForZone(String bounty) {
    return 'RUN FOR ZONE (+${bounty}x)';
  }

  @override
  String leaderboardTitle(String zoneName) {
    return '$zoneName — Leaderboard';
  }

  @override
  String get yourClub => 'Your club';

  @override
  String gapToLeader(String km) {
    return '$km km to leader';
  }

  @override
  String get joinClubCta => 'Join a club to compete for territories';

  @override
  String get findClub => 'FIND A CLUB';

  @override
  String get seasonStarted => 'New season started, no data yet. Be the first!';

  @override
  String get loadError => 'Failed to load data';

  @override
  String leaderKm(String km) {
    return '$km km';
  }

  @override
  String clubLeading(String km) {
    return 'Your club is leading! +$km km ahead';
  }

  @override
  String clubPosition(String km, String position) {
    return 'Your club: $km km ($position place)';
  }

  @override
  String get trainerProfile => 'Trainer Profile';

  @override
  String get trainerEditProfile => 'Edit Trainer Profile';

  @override
  String get trainerBio => 'About';

  @override
  String get trainerBioHint => 'Describe your coaching philosophy...';

  @override
  String get trainerSpecialization => 'Specialization';

  @override
  String get trainerExperience => 'Experience (years)';

  @override
  String get trainerCertificates => 'Certificates';

  @override
  String get trainerCertificateName => 'Certificate name';

  @override
  String get trainerCertificateDate => 'Date';

  @override
  String get trainerCertificateOrg => 'Organization';

  @override
  String get trainerAddCertificate => 'Add certificate';

  @override
  String get trainerProfileSaved => 'Profile saved';

  @override
  String get trainerProfileNotAvailable => 'Trainer profile not available';

  @override
  String get trainerRoleRequired =>
      'You need a trainer role in a club to edit your profile';

  @override
  String get trainerSpecializationRequired =>
      'Select at least one specialization';

  @override
  String get trainerExperienceRange => 'Value must be between 0 and 50';

  @override
  String get specMarathon => 'Marathon';

  @override
  String get specSprint => 'Sprint';

  @override
  String get specTrail => 'Trail';

  @override
  String get specRecovery => 'Recovery';

  @override
  String get specGeneral => 'General';

  @override
  String get workouts => 'Workouts';

  @override
  String get myWorkouts => 'My Workouts';

  @override
  String get createWorkout => 'Create Workout';

  @override
  String get editWorkout => 'Edit Workout';

  @override
  String get workoutName => 'Name';

  @override
  String get workoutDescription => 'Description';

  @override
  String get workoutDescriptionHint => 'Describe the workout plan...';

  @override
  String get workoutType => 'Type';

  @override
  String get workoutDifficulty => 'Difficulty';

  @override
  String get workoutTargetMetric => 'Target metric';

  @override
  String get workoutClub => 'Club (optional)';

  @override
  String get workoutPersonal => 'Personal';

  @override
  String get workoutSaved => 'Workout saved';

  @override
  String get workoutDeleted => 'Workout deleted';

  @override
  String get workoutDeleteConfirm => 'Delete this workout?';

  @override
  String get workoutDeleteAction => 'Delete';

  @override
  String get workoutInUse => 'Cannot delete: linked to upcoming events';

  @override
  String get workoutEmpty => 'No workouts yet';

  @override
  String get workoutFromTrainer => 'From Trainer';

  @override
  String get workoutAssignedEmpty => 'No workouts assigned by trainer yet';

  @override
  String workoutAssignedBy(String name) {
    return 'Trainer: $name';
  }

  @override
  String get workoutAssignToClient => 'Assign to client';

  @override
  String get workoutAssignSelectClient => 'Select client';

  @override
  String get workoutAssigned => 'Workout assigned';

  @override
  String get workoutAssignError => 'Failed to assign workout';

  @override
  String get typeRecovery => 'Recovery';

  @override
  String get typeTempo => 'Tempo';

  @override
  String get typeFunctional => 'Functional';

  @override
  String get typeAccelerations => 'Accelerations';

  @override
  String get workoutDistanceM => 'Distance (m)';

  @override
  String get workoutHeartRate => 'Target HR (bpm)';

  @override
  String get workoutPaceTarget => 'Target Pace (min/km)';

  @override
  String get workoutRepCount => 'Repetitions';

  @override
  String get workoutRepDistance => 'Rep Distance (m)';

  @override
  String get workoutExercise => 'Exercise';

  @override
  String get workoutInstructions => 'Instructions (how to)';

  @override
  String get diffBeginner => 'Beginner';

  @override
  String get diffIntermediate => 'Intermediate';

  @override
  String get diffAdvanced => 'Advanced';

  @override
  String get diffPro => 'Pro';

  @override
  String get metricDistance => 'Distance';

  @override
  String get metricTime => 'Time';

  @override
  String get metricPace => 'Pace';

  @override
  String get workoutTargetValueDistance => 'Distance (meters)';

  @override
  String get workoutTargetValueTime => 'Duration (minutes)';

  @override
  String get workoutTargetValuePace => 'Pace (sec/km)';

  @override
  String get workoutTargetZone => 'Target Zone';

  @override
  String get zoneNone => 'None';

  @override
  String get zoneZ1 => 'Z1 Recovery';

  @override
  String get zoneZ2 => 'Z2 Easy';

  @override
  String get zoneZ3 => 'Z3 Aerobic';

  @override
  String get zoneZ4 => 'Z4 Threshold';

  @override
  String get zoneZ5 => 'Z5 Maximum';

  @override
  String get eventWorkout => 'Workout';

  @override
  String get eventSelectWorkout => 'Select workout';

  @override
  String get eventTrainer => 'Trainer';

  @override
  String get eventSelectTrainer => 'Select trainer';

  @override
  String get eventNoWorkout => 'No workout assigned';

  @override
  String get eventEditTitle => 'Edit Event';

  @override
  String get eventEditSave => 'Save Changes';

  @override
  String get eventEditSuccess => 'Event updated';

  @override
  String eventEditError(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get captureButton => 'Capture';

  @override
  String get captureSuccess => 'Territory capture contribution submitted!';

  @override
  String captureError(String message) {
    return 'Could not capture: $message';
  }

  @override
  String get eventCreatePrivate => 'Private Event';

  @override
  String get eventCreatePrivateDescription => 'Only visible to invited members';

  @override
  String get runSelectClubTitle => 'Select Club for Scoring';

  @override
  String get runNoClubs => 'No active clubs found';

  @override
  String get runSkipScoring => 'Skip Scoring (Not Saved)';

  @override
  String get runClubRequired => 'Please select a club to contribute points.';

  @override
  String get trainerSection => 'Trainer';

  @override
  String get trainerAcceptsClients => 'Accept private clients';

  @override
  String get trainerAcceptsClientsHint =>
      'Your profile will appear in trainer discovery';

  @override
  String get trainerSetupProfile => 'Configure trainer profile';

  @override
  String get trainerPrivateBadge => 'Private trainer';

  @override
  String get findTrainers => 'Find Trainers';

  @override
  String get trainersList => 'Trainers';

  @override
  String get trainersEmpty => 'No trainers found';

  @override
  String get trainersLoadError => 'Could not load trainers';

  @override
  String get watchNotPaired => 'Watch not connected';

  @override
  String mapActiveClub(String name) {
    return 'Club: $name';
  }

  @override
  String get mapNoActiveClub => 'No club';

  @override
  String mapCurrentTerritory(String name) {
    return 'Territory: $name';
  }

  @override
  String get mapNoTerritory => 'No territory';

  @override
  String get selectClub => 'Select club';

  @override
  String get messagesScrollToBottom => 'Scroll to bottom';

  @override
  String get trainerGroupsTab => 'Groups';

  @override
  String get trainerPersonalTab => 'Personal';

  @override
  String get trainerBadge => 'Trainer';

  @override
  String get trainerNoPrivateClients => 'No private clients';

  @override
  String get trainerNoPersonalTrainer => 'No personal trainer';

  @override
  String get memberActionWriteAsTrainer => 'Write as trainer';

  @override
  String get memberActionChangeRole => 'Change role';

  @override
  String get memberActionPrivateMessages => 'Private messages';

  @override
  String get memberActionPrivateMessagesHint => 'Coming soon';

  @override
  String get directChatWaitForTrainer => 'Your trainer will write you first';

  @override
  String get trainerGroupsTitle => 'Groups';

  @override
  String get trainerCreateGroup => 'Create Group';

  @override
  String get trainerGroupName => 'Group Name';

  @override
  String get trainerGroupNameHint => 'Enter group name';

  @override
  String get trainerSelectMembers => 'Select Members';

  @override
  String get trainerNoGroups => 'No groups yet';

  @override
  String get trainerGroupCreated => 'Group created successfully';

  @override
  String trainerCreateGroupError(String error) {
    return 'Could not create group: $error';
  }

  @override
  String get errorUnauthorizedTitle => 'Authorization error';

  @override
  String get errorUnauthorizedMessage =>
      'Session expired or invalid. Please sign in again.';

  @override
  String get errorUnauthorizedAction => 'Sign in again';

  @override
  String get workoutIntensityZone => 'Intensity Zone';

  @override
  String get runRPE => 'Effort (RPE)';

  @override
  String get notesForCoach => 'Notes for coach';

  @override
  String get recoveryType => 'Recovery Type';

  @override
  String get mediaUrlInstruction => 'Video Instruction';

  @override
  String get surfaceRoad => 'Road';

  @override
  String get surfaceTrack => 'Track';

  @override
  String get surfaceTrail => 'Trail';

  @override
  String get workoutSurface => 'Surface';

  @override
  String get segmentTypeWarmup => 'Warmup';

  @override
  String get segmentTypeRun => 'Run';

  @override
  String get segmentTypeRest => 'Rest';

  @override
  String get segmentTypeCooldown => 'Cooldown';

  @override
  String get recoveryJog => 'Jog';

  @override
  String get recoveryWalk => 'Walk';

  @override
  String get recoveryStand => 'Stand';

  @override
  String get durationTime => 'Time';

  @override
  String get durationDistance => 'Distance';

  @override
  String get durationManual => 'Manual (Lap)';

  @override
  String get filtersEventType => 'Event type';

  @override
  String get filtersDifficulty => 'Difficulty';

  @override
  String get eventsEmptyFiltered => 'No events match the selected filters';

  @override
  String get eventsResetFilters => 'Reset filters';

  @override
  String eventTimeToday(String time) {
    return 'Today at $time';
  }

  @override
  String eventTimeTomorrow(String time) {
    return 'Tomorrow at $time';
  }

  @override
  String eventTimeInMinutes(int minutes) {
    return 'In $minutes min';
  }

  @override
  String eventTimeInHoursMinutes(int hours, int minutes) {
    return 'In $hours h $minutes min';
  }

  @override
  String get runClubNotSelected => 'Not selected';

  @override
  String get runSelectTaskTitle => 'Select today\'s task';

  @override
  String get runNoTask => 'Just a run (no task)';

  @override
  String get runStatsTotalTime => 'Total time';

  @override
  String runCountedTerritoryForClub(String clubName) {
    return 'Territory points for $clubName';
  }

  @override
  String get loadMore => 'Load more';

  @override
  String get findPeople => 'Find people';

  @override
  String get peopleSearchHint => 'Search by name...';

  @override
  String get peopleSearchPlaceholder => 'Enter at least 2 characters to search';

  @override
  String get peopleSearchEmpty => 'No users found';

  @override
  String get peopleMyCity => 'My city';

  @override
  String get messageComingSoon => 'Messaging — coming soon';

  @override
  String get profileVisibilityToggle => 'Public profile';

  @override
  String get profileVisibilityHint => 'Other users can find you in search';

  @override
  String get publicProfileRuns => 'runs';

  @override
  String get publicProfileKm => 'km';

  @override
  String get publicProfilePoints => 'points';

  @override
  String get publicProfileRecentRuns => 'Recent runs';

  @override
  String get publicProfileNoRuns => 'No runs yet';

  @override
  String get clientRunsTitle => 'Client runs';

  @override
  String get clientRunsEmpty => 'No completed runs yet';

  @override
  String get clientRunsViewResults => 'View runs';

  @override
  String get clientRunsDistance => 'Distance';

  @override
  String get clientRunsRpe => 'RPE';

  @override
  String get clientRunsAssignment => 'Assignment';

  @override
  String get workoutAssignSelectGroup => 'Select group';

  @override
  String get workoutAssignedToGroup => 'Assigned to group';

  @override
  String get workoutAssignTabClient => 'Client';

  @override
  String get workoutAssignTabGroup => 'Group';

  @override
  String get updateAvailableTitle => 'Update available';

  @override
  String get updateDescription =>
      'A new version is available. Check your email for the download link.';

  @override
  String get updateCurrentVersionLabel => 'Current version';

  @override
  String get updateLatestVersionLabel => 'New version';

  @override
  String get updateClose => 'Close';

  @override
  String get updateInstall => 'Update';

  @override
  String get calendarTitle => 'Training schedule';

  @override
  String get calendarRun => 'Run';

  @override
  String get calendarEvent => 'Event';

  @override
  String get calendarChoose => 'Open';

  @override
  String get mapLayerTerritories => 'Territories';

  @override
  String get mapLayerRaces => 'Races';

  @override
  String get mapLayerLocal => 'Local events';

  @override
  String get mapLayerVenues => 'Where to run';

  @override
  String get mapLayerRoutes => 'Routes';

  @override
  String get mapLayerRoutesComingSoon => 'Coming soon';
}
