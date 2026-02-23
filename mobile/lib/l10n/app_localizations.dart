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

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @tabPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get tabPersonal;

  /// No description provided for @tabClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get tabClub;

  /// No description provided for @tabCoach.
  ///
  /// In en, this message translates to:
  /// **'Coach'**
  String get tabCoach;

  /// No description provided for @personalChatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Personal chats — coming soon'**
  String get personalChatsEmpty;

  /// No description provided for @coachMessagesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Coach messages — coming soon'**
  String get coachMessagesEmpty;

  /// No description provided for @noClubChats.
  ///
  /// In en, this message translates to:
  /// **'No club chats\n\nYou are not in any club yet'**
  String get noClubChats;

  /// No description provided for @messagesBackToClubs.
  ///
  /// In en, this message translates to:
  /// **'Back to clubs'**
  String get messagesBackToClubs;

  /// No description provided for @messagesSelectClub.
  ///
  /// In en, this message translates to:
  /// **'Select a club to chat'**
  String get messagesSelectClub;

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

  /// No description provided for @roleTrainer.
  ///
  /// In en, this message translates to:
  /// **'Trainer'**
  String get roleTrainer;

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

  /// No description provided for @profileMyClubsButton.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get profileMyClubsButton;

  /// No description provided for @profileMyClubsTitle.
  ///
  /// In en, this message translates to:
  /// **'My clubs'**
  String get profileMyClubsTitle;

  /// No description provided for @profileMyClubsEmpty.
  ///
  /// In en, this message translates to:
  /// **'You are not in any clubs yet'**
  String get profileMyClubsEmpty;

  /// No description provided for @profileMyClubsLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load clubs: {error}'**
  String profileMyClubsLoadError(String error);

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

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete your account permanently? This cannot be undone. All your data will be removed.'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountConfirmButton.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteAccountConfirmButton;

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

  /// No description provided for @eventCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get eventCreateTitle;

  /// No description provided for @eventCreateName.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get eventCreateName;

  /// No description provided for @eventCreateNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Event name is required'**
  String get eventCreateNameRequired;

  /// No description provided for @eventCreateType.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get eventCreateType;

  /// No description provided for @eventCreateDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get eventCreateDate;

  /// No description provided for @eventCreateTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get eventCreateTime;

  /// No description provided for @eventCreateCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get eventCreateCity;

  /// No description provided for @eventCreateCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a city in profile first'**
  String get eventCreateCityRequired;

  /// No description provided for @eventCreateOrganizerId.
  ///
  /// In en, this message translates to:
  /// **'Organizer ID'**
  String get eventCreateOrganizerId;

  /// No description provided for @eventCreateOrganizerRequired.
  ///
  /// In en, this message translates to:
  /// **'Organizer is required'**
  String get eventCreateOrganizerRequired;

  /// No description provided for @eventCreateOrganizerType.
  ///
  /// In en, this message translates to:
  /// **'Organizer type'**
  String get eventCreateOrganizerType;

  /// No description provided for @eventCreateOrganizerClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get eventCreateOrganizerClub;

  /// No description provided for @eventCreateOrganizerTrainer.
  ///
  /// In en, this message translates to:
  /// **'Trainer'**
  String get eventCreateOrganizerTrainer;

  /// No description provided for @eventCreateLocationName.
  ///
  /// In en, this message translates to:
  /// **'Location name'**
  String get eventCreateLocationName;

  /// No description provided for @eventCreateLatitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get eventCreateLatitude;

  /// No description provided for @eventCreateLongitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get eventCreateLongitude;

  /// No description provided for @eventCreateCoordinatesRequired.
  ///
  /// In en, this message translates to:
  /// **'Coordinates are required'**
  String get eventCreateCoordinatesRequired;

  /// No description provided for @eventCreateCoordinatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid coordinates'**
  String get eventCreateCoordinatesInvalid;

  /// No description provided for @eventCreateParticipantLimit.
  ///
  /// In en, this message translates to:
  /// **'Participant limit'**
  String get eventCreateParticipantLimit;

  /// No description provided for @eventCreateLimitInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid participant limit'**
  String get eventCreateLimitInvalid;

  /// No description provided for @eventCreateDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get eventCreateDescription;

  /// No description provided for @eventCreateSave.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get eventCreateSave;

  /// No description provided for @eventCreateSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event created'**
  String get eventCreateSuccess;

  /// No description provided for @eventCreateError.
  ///
  /// In en, this message translates to:
  /// **'Could not create event: {message}'**
  String eventCreateError(String message);

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

  /// No description provided for @filterParticipantOnly.
  ///
  /// In en, this message translates to:
  /// **'Participating'**
  String get filterParticipantOnly;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

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
  /// **'Joining...'**
  String get eventJoinTodo;

  /// No description provided for @eventJoinInProgress.
  ///
  /// In en, this message translates to:
  /// **'Joining...'**
  String get eventJoinInProgress;

  /// No description provided for @eventJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'You are registered'**
  String get eventJoinSuccess;

  /// No description provided for @eventJoinError.
  ///
  /// In en, this message translates to:
  /// **'Could not join: {message}'**
  String eventJoinError(String message);

  /// No description provided for @eventYouAreRegistered.
  ///
  /// In en, this message translates to:
  /// **'You are registered'**
  String get eventYouAreRegistered;

  /// No description provided for @eventYouParticipate.
  ///
  /// In en, this message translates to:
  /// **'You participate'**
  String get eventYouParticipate;

  /// No description provided for @eventLeave.
  ///
  /// In en, this message translates to:
  /// **'Cancel participation'**
  String get eventLeave;

  /// No description provided for @eventLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Participation cancelled'**
  String get eventLeaveSuccess;

  /// No description provided for @eventLeaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel: {message}'**
  String eventLeaveError(String message);

  /// No description provided for @eventCheckInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check-in successful'**
  String get eventCheckInSuccess;

  /// No description provided for @eventCheckInError.
  ///
  /// In en, this message translates to:
  /// **'Could not check in: {message}'**
  String eventCheckInError(String message);

  /// No description provided for @eventSwipeToRunTitle.
  ///
  /// In en, this message translates to:
  /// **'Swipe to start run'**
  String get eventSwipeToRunTitle;

  /// No description provided for @eventSwipeToRunHint.
  ///
  /// In en, this message translates to:
  /// **'Swipe left to check in and start your run'**
  String get eventSwipeToRunHint;

  /// No description provided for @eventSwipeToRunSuccess.
  ///
  /// In en, this message translates to:
  /// **'Check-in successful! Run started.'**
  String get eventSwipeToRunSuccess;

  /// No description provided for @eventSwipeToRunError.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String eventSwipeToRunError(String error);

  /// No description provided for @eventSwipeToRunAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'You have already checked in'**
  String get eventSwipeToRunAlreadyCheckedIn;

  /// No description provided for @eventSwipeToRunTooEarly.
  ///
  /// In en, this message translates to:
  /// **'Check-in opens 30 minutes before the event'**
  String get eventSwipeToRunTooEarly;

  /// No description provided for @eventSwipeToRunTooLate.
  ///
  /// In en, this message translates to:
  /// **'Check-in window has closed'**
  String get eventSwipeToRunTooLate;

  /// No description provided for @eventSwipeToRunTooFar.
  ///
  /// In en, this message translates to:
  /// **'Move closer to the start point (within 500 m)'**
  String get eventSwipeToRunTooFar;

  /// No description provided for @eventSwipeToRunLocationError.
  ///
  /// In en, this message translates to:
  /// **'Could not get your location'**
  String get eventSwipeToRunLocationError;

  /// No description provided for @eventSwipeToRunCheckingLocation.
  ///
  /// In en, this message translates to:
  /// **'Checking location...'**
  String get eventSwipeToRunCheckingLocation;

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

  /// No description provided for @mapClubsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get mapClubsSheetTitle;

  /// No description provided for @mapClubsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No clubs in this city'**
  String get mapClubsEmpty;

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

  /// No description provided for @territoryLeading.
  ///
  /// In en, this message translates to:
  /// **'Contested (You are leading: {km} km)'**
  String territoryLeading(String km);

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
  /// **'Start'**
  String get runStart;

  /// No description provided for @runPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get runPause;

  /// No description provided for @runResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get runResume;

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

  /// No description provided for @runDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get runDuration;

  /// No description provided for @runDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get runDistance;

  /// No description provided for @runPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get runPace;

  /// No description provided for @runPaceValue.
  ///
  /// In en, this message translates to:
  /// **'{pace}/km'**
  String runPaceValue(String pace);

  /// No description provided for @runAvgSpeed.
  ///
  /// In en, this message translates to:
  /// **'Avg speed'**
  String get runAvgSpeed;

  /// No description provided for @runAvgSpeedValue.
  ///
  /// In en, this message translates to:
  /// **'{speed} km/h'**
  String runAvgSpeedValue(String speed);

  /// No description provided for @runCalories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get runCalories;

  /// No description provided for @runCaloriesValue.
  ///
  /// In en, this message translates to:
  /// **'~{calories} kcal'**
  String runCaloriesValue(int calories);

  /// No description provided for @runHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get runHeartRate;

  /// No description provided for @runHeartRateValue.
  ///
  /// In en, this message translates to:
  /// **'{bpm} bpm'**
  String runHeartRateValue(int bpm);

  /// No description provided for @runNoData.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get runNoData;

  /// No description provided for @runFindMe.
  ///
  /// In en, this message translates to:
  /// **'Find me'**
  String get runFindMe;

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

  /// No description provided for @clubRequestJoin.
  ///
  /// In en, this message translates to:
  /// **'Apply to join'**
  String get clubRequestJoin;

  /// No description provided for @clubRequestPending.
  ///
  /// In en, this message translates to:
  /// **'Request pending'**
  String get clubRequestPending;

  /// No description provided for @clubRequestApprove.
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get clubRequestApprove;

  /// No description provided for @clubRequestReject.
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get clubRequestReject;

  /// No description provided for @clubMembershipRequests.
  ///
  /// In en, this message translates to:
  /// **'Membership requests'**
  String get clubMembershipRequests;

  /// No description provided for @clubJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get clubJoin;

  /// No description provided for @clubJoinSuccess.
  ///
  /// In en, this message translates to:
  /// **'You joined the club'**
  String get clubJoinSuccess;

  /// No description provided for @clubJoinError.
  ///
  /// In en, this message translates to:
  /// **'Could not join: {message}'**
  String clubJoinError(String message);

  /// No description provided for @clubYouAreMember.
  ///
  /// In en, this message translates to:
  /// **'You are a member'**
  String get clubYouAreMember;

  /// No description provided for @clubLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave club'**
  String get clubLeave;

  /// No description provided for @clubLeaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'You left the club'**
  String get clubLeaveSuccess;

  /// No description provided for @clubLeaveError.
  ///
  /// In en, this message translates to:
  /// **'Could not leave: {message}'**
  String clubLeaveError(String message);

  /// No description provided for @clubChatButton.
  ///
  /// In en, this message translates to:
  /// **'Club chat'**
  String get clubChatButton;

  /// No description provided for @clubMembersLabel.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get clubMembersLabel;

  /// No description provided for @clubTerritoriesLabel.
  ///
  /// In en, this message translates to:
  /// **'Territories'**
  String get clubTerritoriesLabel;

  /// No description provided for @clubCityRankLabel.
  ///
  /// In en, this message translates to:
  /// **'City rank'**
  String get clubCityRankLabel;

  /// No description provided for @clubMetricPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get clubMetricPlaceholder;

  /// No description provided for @clubActivationHint.
  ///
  /// In en, this message translates to:
  /// **'Add 1 more member to activate the club and participate in territory capture.'**
  String get clubActivationHint;

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

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get editProfileName;

  /// No description provided for @editProfileFirstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get editProfileFirstName;

  /// No description provided for @editProfileLastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get editProfileLastName;

  /// No description provided for @editProfileBirthDate.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get editProfileBirthDate;

  /// No description provided for @editProfileCountry.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get editProfileCountry;

  /// No description provided for @editProfileGender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get editProfileGender;

  /// No description provided for @editProfileCity.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get editProfileCity;

  /// No description provided for @editProfilePhotoUrl.
  ///
  /// In en, this message translates to:
  /// **'Photo URL'**
  String get editProfilePhotoUrl;

  /// No description provided for @editProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editProfileSave;

  /// No description provided for @editProfileNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get editProfileNameRequired;

  /// No description provided for @editProfileEditAction.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editProfileEditAction;

  /// No description provided for @profilePersonalInfoTitle.
  ///
  /// In en, this message translates to:
  /// **'Personal info'**
  String get profilePersonalInfoTitle;

  /// No description provided for @profileFirstNameLabel.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get profileFirstNameLabel;

  /// No description provided for @profileLastNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get profileLastNameLabel;

  /// No description provided for @profileBirthDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Birth date'**
  String get profileBirthDateLabel;

  /// No description provided for @profileCountryLabel.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get profileCountryLabel;

  /// No description provided for @profileGenderLabel.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get profileGenderLabel;

  /// No description provided for @profileCityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get profileCityLabel;

  /// No description provided for @profileNotSpecified.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get profileNotSpecified;

  /// No description provided for @genderMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get genderFemale;

  /// No description provided for @genderOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get genderOther;

  /// No description provided for @genderUnknown.
  ///
  /// In en, this message translates to:
  /// **'Prefer not to say'**
  String get genderUnknown;

  /// No description provided for @createClubTitle.
  ///
  /// In en, this message translates to:
  /// **'Create club'**
  String get createClubTitle;

  /// No description provided for @createClubNameHint.
  ///
  /// In en, this message translates to:
  /// **'Club name'**
  String get createClubNameHint;

  /// No description provided for @createClubDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get createClubDescriptionHint;

  /// No description provided for @createClubSave.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get createClubSave;

  /// No description provided for @createClubNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Club name is required'**
  String get createClubNameRequired;

  /// No description provided for @createClubCityRequired.
  ///
  /// In en, this message translates to:
  /// **'Select your city in profile first'**
  String get createClubCityRequired;

  /// No description provided for @createClubError.
  ///
  /// In en, this message translates to:
  /// **'Could not create club: {message}'**
  String createClubError(String message);

  /// No description provided for @runStuckSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Run in progress'**
  String get runStuckSessionTitle;

  /// No description provided for @runStuckSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'You have an unfinished run. Would you like to continue it or start fresh?'**
  String get runStuckSessionMessage;

  /// No description provided for @runStuckSessionResume.
  ///
  /// In en, this message translates to:
  /// **'Continue run'**
  String get runStuckSessionResume;

  /// No description provided for @runStuckSessionCancel.
  ///
  /// In en, this message translates to:
  /// **'Discard and start new'**
  String get runStuckSessionCancel;

  /// No description provided for @editClubTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Club'**
  String get editClubTitle;

  /// No description provided for @editClubName.
  ///
  /// In en, this message translates to:
  /// **'Club Name'**
  String get editClubName;

  /// No description provided for @editClubDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get editClubDescription;

  /// No description provided for @editClubNameHelperText.
  ///
  /// In en, this message translates to:
  /// **'characters'**
  String get editClubNameHelperText;

  /// No description provided for @editClubDescriptionHelperText.
  ///
  /// In en, this message translates to:
  /// **'Optional, up to 500 characters'**
  String get editClubDescriptionHelperText;

  /// No description provided for @editClubNameError.
  ///
  /// In en, this message translates to:
  /// **'Name must be 3-50 characters'**
  String get editClubNameError;

  /// No description provided for @editClubSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get editClubSave;

  /// No description provided for @editClubError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update club'**
  String get editClubError;

  /// No description provided for @clubEditButton.
  ///
  /// In en, this message translates to:
  /// **'Edit Club'**
  String get clubEditButton;

  /// No description provided for @clubManagementTitle.
  ///
  /// In en, this message translates to:
  /// **'Trainer Management'**
  String get clubManagementTitle;

  /// No description provided for @clubManageSchedule.
  ///
  /// In en, this message translates to:
  /// **'Weekly Schedule'**
  String get clubManageSchedule;

  /// No description provided for @clubManageRoster.
  ///
  /// In en, this message translates to:
  /// **'Roster & Plans'**
  String get clubManageRoster;

  /// No description provided for @clubMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get clubMembersTitle;

  /// No description provided for @clubMembersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No members yet'**
  String get clubMembersEmpty;

  /// No description provided for @clubMembersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load members'**
  String get clubMembersLoadError;

  /// No description provided for @clubMemberRoleChange.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get clubMemberRoleChange;

  /// No description provided for @clubMemberRoleChangeSuccess.
  ///
  /// In en, this message translates to:
  /// **'Role updated'**
  String get clubMemberRoleChangeSuccess;

  /// No description provided for @clubMemberRoleChangeError.
  ///
  /// In en, this message translates to:
  /// **'Could not update role: {message}'**
  String clubMemberRoleChangeError(String message);

  /// No description provided for @rosterTitle.
  ///
  /// In en, this message translates to:
  /// **'Club Roster'**
  String get rosterTitle;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Template'**
  String get scheduleTitle;

  /// No description provided for @planTypeClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get planTypeClub;

  /// No description provided for @planTypePersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get planTypePersonal;

  /// No description provided for @eventOpenOnMap.
  ///
  /// In en, this message translates to:
  /// **'Open on map'**
  String get eventOpenOnMap;

  /// No description provided for @eventCreateSelectCity.
  ///
  /// In en, this message translates to:
  /// **'Select city'**
  String get eventCreateSelectCity;

  /// No description provided for @clubFounder.
  ///
  /// In en, this message translates to:
  /// **'Founder'**
  String get clubFounder;

  /// No description provided for @clubsListTitle.
  ///
  /// In en, this message translates to:
  /// **'City clubs'**
  String get clubsListTitle;

  /// No description provided for @clubsListEmpty.
  ///
  /// In en, this message translates to:
  /// **'No clubs yet'**
  String get clubsListEmpty;

  /// No description provided for @clubsListAllClubs.
  ///
  /// In en, this message translates to:
  /// **'All city clubs'**
  String get clubsListAllClubs;

  /// No description provided for @clubEventsTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming events'**
  String get clubEventsTitle;

  /// No description provided for @clubEventsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No upcoming events'**
  String get clubEventsEmpty;

  /// No description provided for @clubEventsError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load'**
  String get clubEventsError;

  /// No description provided for @clubEventsViewAll.
  ///
  /// In en, this message translates to:
  /// **'All club events'**
  String get clubEventsViewAll;

  /// No description provided for @eventCreatePickLocation.
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get eventCreatePickLocation;

  /// No description provided for @eventCreateLocationSelected.
  ///
  /// In en, this message translates to:
  /// **'Location selected'**
  String get eventCreateLocationSelected;

  /// No description provided for @eventCreateLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Select a start point'**
  String get eventCreateLocationRequired;

  /// No description provided for @eventCreateLocationOutOfCity.
  ///
  /// In en, this message translates to:
  /// **'Selected location is outside the city bounds. Pick a point closer to the city.'**
  String get eventCreateLocationOutOfCity;

  /// No description provided for @locationPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick location'**
  String get locationPickerTitle;

  /// No description provided for @locationPickerConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get locationPickerConfirm;

  /// No description provided for @locationPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search address...'**
  String get locationPickerSearchHint;

  /// No description provided for @leaderCannotLeave.
  ///
  /// In en, this message translates to:
  /// **'Transfer leadership first'**
  String get leaderCannotLeave;

  /// No description provided for @transferLeadership.
  ///
  /// In en, this message translates to:
  /// **'Transfer leadership'**
  String get transferLeadership;

  /// No description provided for @disbandClub.
  ///
  /// In en, this message translates to:
  /// **'Disband club'**
  String get disbandClub;

  /// No description provided for @disbandConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure? This cannot be undone.'**
  String get disbandConfirm;

  /// No description provided for @selectNewLeader.
  ///
  /// In en, this message translates to:
  /// **'Select new leader'**
  String get selectNewLeader;

  /// No description provided for @transferSuccess.
  ///
  /// In en, this message translates to:
  /// **'Leadership transferred'**
  String get transferSuccess;

  /// No description provided for @disbandSuccess.
  ///
  /// In en, this message translates to:
  /// **'Club disbanded'**
  String get disbandSuccess;

  /// No description provided for @runHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Training Journal'**
  String get runHistoryTitle;

  /// No description provided for @runHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get runHistoryEmpty;

  /// No description provided for @runHistoryEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'Start your first run to see it here'**
  String get runHistoryEmptyHint;

  /// No description provided for @runHistoryToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get runHistoryToday;

  /// No description provided for @runHistoryYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get runHistoryYesterday;

  /// No description provided for @runStatsTitle.
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get runStatsTitle;

  /// No description provided for @runStatsTotalRuns.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get runStatsTotalRuns;

  /// No description provided for @runStatsTotalDistance.
  ///
  /// In en, this message translates to:
  /// **'Total distance'**
  String get runStatsTotalDistance;

  /// No description provided for @runStatsAvgPace.
  ///
  /// In en, this message translates to:
  /// **'Avg pace'**
  String get runStatsAvgPace;

  /// No description provided for @runDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'Run details'**
  String get runDetailTitle;

  /// No description provided for @runDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load run details'**
  String get runDetailLoadError;

  /// No description provided for @runGpsPoints.
  ///
  /// In en, this message translates to:
  /// **'GPS points'**
  String get runGpsPoints;

  /// No description provided for @tierGreen.
  ///
  /// In en, this message translates to:
  /// **'Green Zone'**
  String get tierGreen;

  /// No description provided for @tierBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue Zone'**
  String get tierBlue;

  /// No description provided for @tierRed.
  ///
  /// In en, this message translates to:
  /// **'Red Zone'**
  String get tierRed;

  /// No description provided for @tierBlack.
  ///
  /// In en, this message translates to:
  /// **'Black Zone'**
  String get tierBlack;

  /// No description provided for @tierLabelNovice.
  ///
  /// In en, this message translates to:
  /// **'Novice'**
  String get tierLabelNovice;

  /// No description provided for @tierLabelAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get tierLabelAdvanced;

  /// No description provided for @tierLabelSpecialist.
  ///
  /// In en, this message translates to:
  /// **'Specialist'**
  String get tierLabelSpecialist;

  /// No description provided for @tierLabelElite.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get tierLabelElite;

  /// No description provided for @zoneCaptured.
  ///
  /// In en, this message translates to:
  /// **'Controlled by {clubName}'**
  String zoneCaptured(String clubName);

  /// No description provided for @zoneOpenSeason.
  ///
  /// In en, this message translates to:
  /// **'Open Season'**
  String get zoneOpenSeason;

  /// No description provided for @zoneContested.
  ///
  /// In en, this message translates to:
  /// **'Contested'**
  String get zoneContested;

  /// No description provided for @paceBonus.
  ///
  /// In en, this message translates to:
  /// **'Pace < {pace} → x{multiplier}'**
  String paceBonus(String pace, String multiplier);

  /// No description provided for @zoneBountyLabel.
  ///
  /// In en, this message translates to:
  /// **'x{bounty} Points'**
  String zoneBountyLabel(String bounty);

  /// No description provided for @seasonResetIn.
  ///
  /// In en, this message translates to:
  /// **'Reset in {days}d'**
  String seasonResetIn(int days);

  /// No description provided for @runForZone.
  ///
  /// In en, this message translates to:
  /// **'RUN FOR ZONE (+{bounty}x)'**
  String runForZone(String bounty);

  /// No description provided for @leaderboardTitle.
  ///
  /// In en, this message translates to:
  /// **'{zoneName} — Leaderboard'**
  String leaderboardTitle(String zoneName);

  /// No description provided for @yourClub.
  ///
  /// In en, this message translates to:
  /// **'Your club'**
  String get yourClub;

  /// No description provided for @gapToLeader.
  ///
  /// In en, this message translates to:
  /// **'{km} km to leader'**
  String gapToLeader(String km);

  /// No description provided for @joinClubCta.
  ///
  /// In en, this message translates to:
  /// **'Join a club to compete for territories'**
  String get joinClubCta;

  /// No description provided for @findClub.
  ///
  /// In en, this message translates to:
  /// **'FIND A CLUB'**
  String get findClub;

  /// No description provided for @seasonStarted.
  ///
  /// In en, this message translates to:
  /// **'New season started, no data yet. Be the first!'**
  String get seasonStarted;

  /// No description provided for @loadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load data'**
  String get loadError;

  /// No description provided for @leaderKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String leaderKm(String km);

  /// No description provided for @clubLeading.
  ///
  /// In en, this message translates to:
  /// **'Your club is leading! +{km} km ahead'**
  String clubLeading(String km);

  /// No description provided for @clubPosition.
  ///
  /// In en, this message translates to:
  /// **'Your club: {km} km ({position} place)'**
  String clubPosition(String km, String position);

  /// No description provided for @trainerProfile.
  ///
  /// In en, this message translates to:
  /// **'Trainer Profile'**
  String get trainerProfile;

  /// No description provided for @trainerEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Trainer Profile'**
  String get trainerEditProfile;

  /// No description provided for @trainerBio.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get trainerBio;

  /// No description provided for @trainerBioHint.
  ///
  /// In en, this message translates to:
  /// **'Describe your coaching philosophy...'**
  String get trainerBioHint;

  /// No description provided for @trainerSpecialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get trainerSpecialization;

  /// No description provided for @trainerExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience (years)'**
  String get trainerExperience;

  /// No description provided for @trainerCertificates.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get trainerCertificates;

  /// No description provided for @trainerCertificateName.
  ///
  /// In en, this message translates to:
  /// **'Certificate name'**
  String get trainerCertificateName;

  /// No description provided for @trainerCertificateDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get trainerCertificateDate;

  /// No description provided for @trainerCertificateOrg.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get trainerCertificateOrg;

  /// No description provided for @trainerAddCertificate.
  ///
  /// In en, this message translates to:
  /// **'Add certificate'**
  String get trainerAddCertificate;

  /// No description provided for @trainerProfileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get trainerProfileSaved;

  /// No description provided for @trainerProfileNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'Trainer profile not available'**
  String get trainerProfileNotAvailable;

  /// No description provided for @trainerRoleRequired.
  ///
  /// In en, this message translates to:
  /// **'You need a trainer role in a club to edit your profile'**
  String get trainerRoleRequired;

  /// No description provided for @trainerSpecializationRequired.
  ///
  /// In en, this message translates to:
  /// **'Select at least one specialization'**
  String get trainerSpecializationRequired;

  /// No description provided for @trainerExperienceRange.
  ///
  /// In en, this message translates to:
  /// **'Value must be between 0 and 50'**
  String get trainerExperienceRange;

  /// No description provided for @specMarathon.
  ///
  /// In en, this message translates to:
  /// **'Marathon'**
  String get specMarathon;

  /// No description provided for @specSprint.
  ///
  /// In en, this message translates to:
  /// **'Sprint'**
  String get specSprint;

  /// No description provided for @specTrail.
  ///
  /// In en, this message translates to:
  /// **'Trail'**
  String get specTrail;

  /// No description provided for @specRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get specRecovery;

  /// No description provided for @specGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get specGeneral;

  /// No description provided for @workouts.
  ///
  /// In en, this message translates to:
  /// **'Workouts'**
  String get workouts;

  /// No description provided for @myWorkouts.
  ///
  /// In en, this message translates to:
  /// **'My Workouts'**
  String get myWorkouts;

  /// No description provided for @createWorkout.
  ///
  /// In en, this message translates to:
  /// **'Create Workout'**
  String get createWorkout;

  /// No description provided for @editWorkout.
  ///
  /// In en, this message translates to:
  /// **'Edit Workout'**
  String get editWorkout;

  /// No description provided for @workoutName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get workoutName;

  /// No description provided for @workoutDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get workoutDescription;

  /// No description provided for @workoutDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Describe the workout plan...'**
  String get workoutDescriptionHint;

  /// No description provided for @workoutType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get workoutType;

  /// No description provided for @workoutDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get workoutDifficulty;

  /// No description provided for @workoutTargetMetric.
  ///
  /// In en, this message translates to:
  /// **'Target metric'**
  String get workoutTargetMetric;

  /// No description provided for @workoutClub.
  ///
  /// In en, this message translates to:
  /// **'Club (optional)'**
  String get workoutClub;

  /// No description provided for @workoutPersonal.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get workoutPersonal;

  /// No description provided for @workoutSaved.
  ///
  /// In en, this message translates to:
  /// **'Workout saved'**
  String get workoutSaved;

  /// No description provided for @workoutDeleted.
  ///
  /// In en, this message translates to:
  /// **'Workout deleted'**
  String get workoutDeleted;

  /// No description provided for @workoutDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this workout?'**
  String get workoutDeleteConfirm;

  /// No description provided for @workoutInUse.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete: linked to upcoming events'**
  String get workoutInUse;

  /// No description provided for @workoutEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts yet'**
  String get workoutEmpty;

  /// No description provided for @typeRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get typeRecovery;

  /// No description provided for @typeTempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get typeTempo;

  /// No description provided for @typeInterval.
  ///
  /// In en, this message translates to:
  /// **'Interval'**
  String get typeInterval;

  /// No description provided for @typeFartlek.
  ///
  /// In en, this message translates to:
  /// **'Fartlek'**
  String get typeFartlek;

  /// No description provided for @typeLongRun.
  ///
  /// In en, this message translates to:
  /// **'Long Run'**
  String get typeLongRun;

  /// No description provided for @diffBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get diffBeginner;

  /// No description provided for @diffIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get diffIntermediate;

  /// No description provided for @diffAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get diffAdvanced;

  /// No description provided for @diffPro.
  ///
  /// In en, this message translates to:
  /// **'Pro'**
  String get diffPro;

  /// No description provided for @metricDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get metricDistance;

  /// No description provided for @metricTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get metricTime;

  /// No description provided for @metricPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get metricPace;

  /// No description provided for @eventWorkout.
  ///
  /// In en, this message translates to:
  /// **'Workout'**
  String get eventWorkout;

  /// No description provided for @eventSelectWorkout.
  ///
  /// In en, this message translates to:
  /// **'Select workout'**
  String get eventSelectWorkout;

  /// No description provided for @eventTrainer.
  ///
  /// In en, this message translates to:
  /// **'Trainer'**
  String get eventTrainer;

  /// No description provided for @eventSelectTrainer.
  ///
  /// In en, this message translates to:
  /// **'Select trainer'**
  String get eventSelectTrainer;

  /// No description provided for @eventNoWorkout.
  ///
  /// In en, this message translates to:
  /// **'No workout assigned'**
  String get eventNoWorkout;

  /// No description provided for @eventEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Event'**
  String get eventEditTitle;

  /// No description provided for @eventEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get eventEditSave;

  /// No description provided for @eventEditSuccess.
  ///
  /// In en, this message translates to:
  /// **'Event updated'**
  String get eventEditSuccess;

  /// No description provided for @eventEditError.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String eventEditError(String error);

  /// No description provided for @captureButton.
  ///
  /// In en, this message translates to:
  /// **'Capture'**
  String get captureButton;

  /// No description provided for @captureSuccess.
  ///
  /// In en, this message translates to:
  /// **'Territory capture contribution submitted!'**
  String get captureSuccess;

  /// No description provided for @captureError.
  ///
  /// In en, this message translates to:
  /// **'Could not capture: {message}'**
  String captureError(String message);

  /// No description provided for @eventCreatePrivate.
  ///
  /// In en, this message translates to:
  /// **'Private Event'**
  String get eventCreatePrivate;

  /// No description provided for @eventCreatePrivateDescription.
  ///
  /// In en, this message translates to:
  /// **'Only visible to invited members'**
  String get eventCreatePrivateDescription;

  /// No description provided for @runSelectClubTitle.
  ///
  /// In en, this message translates to:
  /// **'Select Club for Scoring'**
  String get runSelectClubTitle;

  /// No description provided for @runNoClubs.
  ///
  /// In en, this message translates to:
  /// **'No active clubs found'**
  String get runNoClubs;

  /// No description provided for @runSkipScoring.
  ///
  /// In en, this message translates to:
  /// **'Skip Scoring (Not Saved)'**
  String get runSkipScoring;

  /// No description provided for @runClubRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select a club to contribute points.'**
  String get runClubRequired;

  /// No description provided for @trainerSection.
  ///
  /// In en, this message translates to:
  /// **'Trainer'**
  String get trainerSection;

  /// No description provided for @trainerAcceptsClients.
  ///
  /// In en, this message translates to:
  /// **'Accept private clients'**
  String get trainerAcceptsClients;

  /// No description provided for @trainerAcceptsClientsHint.
  ///
  /// In en, this message translates to:
  /// **'Your profile will appear in trainer discovery'**
  String get trainerAcceptsClientsHint;

  /// No description provided for @trainerSetupProfile.
  ///
  /// In en, this message translates to:
  /// **'Configure trainer profile'**
  String get trainerSetupProfile;

  /// No description provided for @trainerPrivateBadge.
  ///
  /// In en, this message translates to:
  /// **'Private trainer'**
  String get trainerPrivateBadge;

  /// No description provided for @findTrainers.
  ///
  /// In en, this message translates to:
  /// **'Find Trainers'**
  String get findTrainers;

  /// No description provided for @trainersList.
  ///
  /// In en, this message translates to:
  /// **'Trainers'**
  String get trainersList;

  /// No description provided for @trainersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trainers found'**
  String get trainersEmpty;

  /// No description provided for @trainersLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load trainers'**
  String get trainersLoadError;
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
