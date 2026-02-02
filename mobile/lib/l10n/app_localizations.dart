import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Runterra'**
  String get appTitle;

  /// No description provided for @navMap.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get navMap;

  /// No description provided for @navRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get navRun;

  /// No description provided for @navMessages.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get navMessages;

  /// No description provided for @navEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get navEvents;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @errorLoadTitle.
  ///
  /// In en, this message translates to:
  /// **'Load error'**
  String get errorLoadTitle;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @errorTimeoutMessage.
  ///
  /// In en, this message translates to:
  /// **'Connection timeout.\n\nMake sure:\n1. Backend server is running (npm run dev in backend folder)\n2. Server listens on all interfaces (0.0.0.0)\n3. No network or firewall issues'**
  String get errorTimeoutMessage;

  /// No description provided for @errorConnectionMessage.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to server.\n\nMake sure backend server is running and available.'**
  String get errorConnectionMessage;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorGeneric(String message);

  /// No description provided for @profileCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Set your city in profile to participate in chat'**
  String get profileCityRequired;

  /// No description provided for @globalChatEmpty.
  ///
  /// In en, this message translates to:
  /// **'It\'s quiet here. Send the first message and set the pace 🏃‍♂️'**
  String get globalChatEmpty;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message...'**
  String get messageHint;

  /// No description provided for @messagesLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading messages: {error}'**
  String messagesLoadError(String error);

  /// No description provided for @messagesTitle.
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messagesTitle;

  /// No description provided for @tabCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get tabCity;

  /// No description provided for @tabClubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get tabClubs;

  /// No description provided for @tabNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get tabNotifications;

  /// No description provided for @noClubChats.
  ///
  /// In en, this message translates to:
  /// **'No club chats\n\nYou are not in any club yet'**
  String get noClubChats;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// No description provided for @clubChatsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading club chats: {error}'**
  String clubChatsLoadError(String error);

  /// No description provided for @notificationsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading notifications: {error}'**
  String notificationsLoadError(String error);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileNotFound.
  ///
  /// In en, this message translates to:
  /// **'Profile data not found'**
  String get profileNotFound;

  /// No description provided for @profileConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to server.\n\nMake sure:\n1. Backend server is running (npm run dev in backend folder)\n2. For Android emulator use 10.0.2.2:3000\n3. For physical device use your computer IP address'**
  String get profileConnectionError;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutTitle;

  /// No description provided for @logoutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to sign out?'**
  String get logoutConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logout;

  /// No description provided for @headerMercenary.
  ///
  /// In en, this message translates to:
  /// **'Mercenary'**
  String get headerMercenary;

  /// No description provided for @headerNoClub.
  ///
  /// In en, this message translates to:
  /// **'No club'**
  String get headerNoClub;

  /// No description provided for @roleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get roleMember;

  /// No description provided for @roleModerator.
  ///
  /// In en, this message translates to:
  /// **'Moderator'**
  String get roleModerator;

  /// No description provided for @roleLeader.
  ///
  /// In en, this message translates to:
  /// **'Leader'**
  String get roleLeader;

  /// No description provided for @quickOpenMap.
  ///
  /// In en, this message translates to:
  /// **'Open map'**
  String get quickOpenMap;

  /// No description provided for @quickFindTraining.
  ///
  /// In en, this message translates to:
  /// **'Find workout'**
  String get quickFindTraining;

  /// No description provided for @quickStartRun.
  ///
  /// In en, this message translates to:
  /// **'Start run'**
  String get quickStartRun;

  /// No description provided for @quickFindClub.
  ///
  /// In en, this message translates to:
  /// **'Find club'**
  String get quickFindClub;

  /// No description provided for @quickCreateClub.
  ///
  /// In en, this message translates to:
  /// **'Create club'**
  String get quickCreateClub;

  /// No description provided for @activityNext.
  ///
  /// In en, this message translates to:
  /// **'Next workout'**
  String get activityNext;

  /// No description provided for @activityLast.
  ///
  /// In en, this message translates to:
  /// **'Last activity'**
  String get activityLast;

  /// No description provided for @activityDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get activityDefaultName;

  /// No description provided for @activityDefaultActivity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityDefaultActivity;

  /// No description provided for @openOnMap.
  ///
  /// In en, this message translates to:
  /// **'Open on map'**
  String get openOnMap;

  /// No description provided for @activityStatusPlanned.
  ///
  /// In en, this message translates to:
  /// **'Registered'**
  String get activityStatusPlanned;

  /// No description provided for @activityStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get activityStatusInProgress;

  /// No description provided for @activityStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get activityStatusCompleted;

  /// No description provided for @activityStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get activityStatusCancelled;

  /// No description provided for @activityResultCounted.
  ///
  /// In en, this message translates to:
  /// **'Counted'**
  String get activityResultCounted;

  /// No description provided for @activityResultNotCounted.
  ///
  /// In en, this message translates to:
  /// **'Not counted'**
  String get activityResultNotCounted;

  /// No description provided for @settingsLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get settingsLocation;

  /// No description provided for @settingsLocationAllowed.
  ///
  /// In en, this message translates to:
  /// **'Allowed'**
  String get settingsLocationAllowed;

  /// No description provided for @settingsLocationDenied.
  ///
  /// In en, this message translates to:
  /// **'Not allowed'**
  String get settingsLocationDenied;

  /// No description provided for @settingsVisibility.
  ///
  /// In en, this message translates to:
  /// **'Profile visibility'**
  String get settingsVisibility;

  /// No description provided for @settingsVisible.
  ///
  /// In en, this message translates to:
  /// **'Visible'**
  String get settingsVisible;

  /// No description provided for @settingsHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get settingsHidden;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsLogout;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @statsTrainings.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get statsTrainings;

  /// No description provided for @statsTerritories.
  ///
  /// In en, this message translates to:
  /// **'Territories'**
  String get statsTerritories;

  /// No description provided for @statsPoints.
  ///
  /// In en, this message translates to:
  /// **'Points'**
  String get statsPoints;

  /// No description provided for @notificationsSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsSectionTitle;

  /// No description provided for @eventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get eventsTitle;

  /// No description provided for @eventsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Error loading events'**
  String get eventsLoadError;

  /// No description provided for @eventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No events found'**
  String get eventsEmpty;

  /// No description provided for @eventsEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Try changing filters'**
  String get eventsEmptyHint;

  /// No description provided for @eventsCreateTodo.
  ///
  /// In en, this message translates to:
  /// **'Create event - TODO'**
  String get eventsCreateTodo;

  /// No description provided for @eventsCreateTooltip.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get eventsCreateTooltip;

  /// No description provided for @filterToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filterToday;

  /// No description provided for @filterTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get filterTomorrow;

  /// No description provided for @filter7days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get filter7days;

  /// No description provided for @filterOnlyOpen.
  ///
  /// In en, this message translates to:
  /// **'Open only'**
  String get filterOnlyOpen;

  /// No description provided for @eventTypeTraining.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get eventTypeTraining;

  /// No description provided for @eventTypeGroupRun.
  ///
  /// In en, this message translates to:
  /// **'Group run'**
  String get eventTypeGroupRun;

  /// No description provided for @eventTypeClubEvent.
  ///
  /// In en, this message translates to:
  /// **'Club event'**
  String get eventTypeClubEvent;

  /// No description provided for @eventTypeOpenEvent.
  ///
  /// In en, this message translates to:
  /// **'Open event'**
  String get eventTypeOpenEvent;

  /// No description provided for @eventStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get eventStatusOpen;

  /// No description provided for @eventStatusFull.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get eventStatusFull;

  /// No description provided for @eventStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get eventStatusCancelled;

  /// No description provided for @eventStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get eventStatusCompleted;

  /// No description provided for @eventDifficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get eventDifficultyBeginner;

  /// No description provided for @eventDifficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get eventDifficultyIntermediate;

  /// No description provided for @eventDifficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get eventDifficultyAdvanced;

  /// No description provided for @eventDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get eventDetailsTitle;

  /// No description provided for @eventDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eventDescription;

  /// No description provided for @eventInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get eventInfo;

  /// No description provided for @eventType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get eventType;

  /// No description provided for @eventDateTime.
  ///
  /// In en, this message translates to:
  /// **'Date & time'**
  String get eventDateTime;

  /// No description provided for @eventLocation.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get eventLocation;

  /// No description provided for @eventOrganizer.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get eventOrganizer;

  /// No description provided for @eventDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get eventDifficulty;

  /// No description provided for @eventTerritory.
  ///
  /// In en, this message translates to:
  /// **'Territory'**
  String get eventTerritory;

  /// No description provided for @eventTerritoryLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to territory'**
  String get eventTerritoryLinked;

  /// No description provided for @eventStartPoint.
  ///
  /// In en, this message translates to:
  /// **'Start point'**
  String get eventStartPoint;

  /// No description provided for @eventMapTodo.
  ///
  /// In en, this message translates to:
  /// **'Map (TODO)'**
  String get eventMapTodo;

  /// No description provided for @eventParticipation.
  ///
  /// In en, this message translates to:
  /// **'Participation'**
  String get eventParticipation;

  /// No description provided for @eventJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get eventJoin;

  /// No description provided for @eventJoinTodo.
  ///
  /// In en, this message translates to:
  /// **'Join event - TODO'**
  String get eventJoinTodo;

  /// No description provided for @eventNoPlaces.
  ///
  /// In en, this message translates to:
  /// **'No spots left'**
  String get eventNoPlaces;

  /// No description provided for @eventCancelled.
  ///
  /// In en, this message translates to:
  /// **'Event cancelled'**
  String get eventCancelled;

  /// No description provided for @eventOrganizerLabel.
  ///
  /// In en, this message translates to:
  /// **'Organizer: {id}'**
  String eventOrganizerLabel(String id);

  /// No description provided for @participantsTitle.
  ///
  /// In en, this message translates to:
  /// **'Participants ({count})'**
  String participantsTitle(int count);

  /// No description provided for @participantsNone.
  ///
  /// In en, this message translates to:
  /// **'No participants yet'**
  String get participantsNone;

  /// No description provided for @participantsMore.
  ///
  /// In en, this message translates to:
  /// **'And {count} more participants'**
  String participantsMore(int count);

  /// No description provided for @participantN.
  ///
  /// In en, this message translates to:
  /// **'Participant {n}'**
  String participantN(int n);

  /// No description provided for @mapTitle.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapTitle;

  /// No description provided for @mapFiltersTooltip.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get mapFiltersTooltip;

  /// No description provided for @mapMyLocationTooltip.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get mapMyLocationTooltip;

  /// No description provided for @mapLocationDeniedSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Location access not granted. Using default position.'**
  String get mapLocationDeniedSnackbar;

  /// No description provided for @mapLoadErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Error loading data: {error}'**
  String mapLoadErrorSnackbar(String error);

  /// No description provided for @mapNoLocationSnackbar.
  ///
  /// In en, this message translates to:
  /// **'No location access'**
  String get mapNoLocationSnackbar;

  /// No description provided for @mapLocationErrorSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Location error: {error}'**
  String mapLocationErrorSnackbar(String error);

  /// No description provided for @filtersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filtersTitle;

  /// No description provided for @filtersDate.
  ///
  /// In en, this message translates to:
  /// **'📅 Date'**
  String get filtersDate;

  /// No description provided for @filtersToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get filtersToday;

  /// No description provided for @filtersWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get filtersWeek;

  /// No description provided for @filtersMyClub.
  ///
  /// In en, this message translates to:
  /// **'🏃 My club'**
  String get filtersMyClub;

  /// No description provided for @filtersActiveTerritories.
  ///
  /// In en, this message translates to:
  /// **'🔥 Active territories only'**
  String get filtersActiveTerritories;

  /// No description provided for @territoryCaptured.
  ///
  /// In en, this message translates to:
  /// **'Captured by club'**
  String get territoryCaptured;

  /// No description provided for @territoryFree.
  ///
  /// In en, this message translates to:
  /// **'Neutral'**
  String get territoryFree;

  /// No description provided for @territoryContested.
  ///
  /// In en, this message translates to:
  /// **'Contested'**
  String get territoryContested;

  /// No description provided for @territoryLocked.
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get territoryLocked;

  /// No description provided for @territoryUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get territoryUnknown;

  /// No description provided for @territoryOwnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Owner club: {id}'**
  String territoryOwnerLabel(String id);

  /// No description provided for @territoryHoldTodo.
  ///
  /// In en, this message translates to:
  /// **'Until hold: TODO'**
  String get territoryHoldTodo;

  /// No description provided for @territoryViewTrainings.
  ///
  /// In en, this message translates to:
  /// **'View workouts'**
  String get territoryViewTrainings;

  /// No description provided for @territoryHelpCapture.
  ///
  /// In en, this message translates to:
  /// **'Help capture'**
  String get territoryHelpCapture;

  /// No description provided for @territoryMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get territoryMore;

  /// No description provided for @runTitle.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get runTitle;

  /// No description provided for @runStart.
  ///
  /// In en, this message translates to:
  /// **'Start run'**
  String get runStart;

  /// No description provided for @runFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get runFinish;

  /// No description provided for @runFinishing.
  ///
  /// In en, this message translates to:
  /// **'Finishing...'**
  String get runFinishing;

  /// No description provided for @runDone.
  ///
  /// In en, this message translates to:
  /// **'Done 🎉'**
  String get runDone;

  /// No description provided for @runGpsSearching.
  ///
  /// In en, this message translates to:
  /// **'Searching for signal'**
  String get runGpsSearching;

  /// No description provided for @runGpsRecording.
  ///
  /// In en, this message translates to:
  /// **'Recording'**
  String get runGpsRecording;

  /// No description provided for @runGpsError.
  ///
  /// In en, this message translates to:
  /// **'GPS error'**
  String get runGpsError;

  /// No description provided for @runForActivity.
  ///
  /// In en, this message translates to:
  /// **'Run will count for workout \"{activityId}\"'**
  String runForActivity(String activityId);

  /// No description provided for @runCountedTraining.
  ///
  /// In en, this message translates to:
  /// **'Workout participation counted'**
  String get runCountedTraining;

  /// No description provided for @runCountedTerritory.
  ///
  /// In en, this message translates to:
  /// **'Territory contribution'**
  String get runCountedTerritory;

  /// No description provided for @runReady.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get runReady;

  /// No description provided for @runStartError.
  ///
  /// In en, this message translates to:
  /// **'Error starting run'**
  String get runStartError;

  /// No description provided for @runStartPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission not granted.\n\nFor Windows: Settings → Privacy → Location → App permissions and enable Runterra.\n\nFor Android: allow location access when prompted.'**
  String get runStartPermissionDenied;

  /// No description provided for @runStartPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location access blocked.\n\nPlease enable permission in device settings:\nWindows: Settings → Privacy → Location\nAndroid: Settings → Apps → Runterra → Permissions'**
  String get runStartPermanentlyDenied;

  /// No description provided for @runStartServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location service is disabled.\n\nPlease enable location in device settings.'**
  String get runStartServiceDisabled;

  /// No description provided for @runStartErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Error starting run:\n{error}'**
  String runStartErrorGeneric(String error);

  /// No description provided for @runFinishError.
  ///
  /// In en, this message translates to:
  /// **'Error finishing run: {error}'**
  String runFinishError(String error);

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{value} m'**
  String distanceMeters(String value);

  /// No description provided for @distanceKm.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String distanceKm(String value);

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Runterra'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Running app for territory capture'**
  String get loginSubtitle;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get loginButton;

  /// No description provided for @loginLoading.
  ///
  /// In en, this message translates to:
  /// **'Signing in...'**
  String get loginLoading;

  /// No description provided for @loginError.
  ///
  /// In en, this message translates to:
  /// **'Sign-in error: {error}'**
  String loginError(String error);

  /// No description provided for @noData.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get noData;

  /// No description provided for @activityDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get activityDetailsTitle;

  /// No description provided for @cityDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityDetailsTitle;

  /// No description provided for @clubDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get clubDetailsTitle;

  /// No description provided for @territoryDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Territory'**
  String get territoryDetailsTitle;

  /// No description provided for @detailType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get detailType;

  /// No description provided for @detailStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get detailStatus;

  /// No description provided for @detailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get detailDescription;

  /// No description provided for @detailCoordinates.
  ///
  /// In en, this message translates to:
  /// **'Coordinates'**
  String get detailCoordinates;

  /// No description provided for @detailLatLng.
  ///
  /// In en, this message translates to:
  /// **'Latitude: {lat}\nLongitude: {lng}'**
  String detailLatLng(String lat, String lng);

  /// No description provided for @detailCoordinatesCenter.
  ///
  /// In en, this message translates to:
  /// **'Center coordinates'**
  String get detailCoordinatesCenter;

  /// No description provided for @detailCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get detailCity;

  /// No description provided for @detailCapturedBy.
  ///
  /// In en, this message translates to:
  /// **'Captured by player'**
  String get detailCapturedBy;

  /// No description provided for @eventTerritoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Territory'**
  String get eventTerritoryLabel;

  /// No description provided for @clubLabel.
  ///
  /// In en, this message translates to:
  /// **'Club: {id}'**
  String clubLabel(String id);

  /// No description provided for @trainerLabel.
  ///
  /// In en, this message translates to:
  /// **'Coach: {id}'**
  String trainerLabel(String id);

  /// No description provided for @cityPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get cityPickerTitle;

  /// No description provided for @cityPickerLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load cities:\n{error}'**
  String cityPickerLoadError(String error);

  /// No description provided for @cityPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'City list is empty'**
  String get cityPickerEmpty;

  /// No description provided for @cityNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get cityNotSelected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
