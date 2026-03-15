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
  /// **'Training'**
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

  /// No description provided for @tabClubs.
  ///
  /// In en, this message translates to:
  /// **'Clubs'**
  String get tabClubs;

  /// No description provided for @personalChatsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet. Write to someone!'**
  String get personalChatsEmpty;

  /// No description provided for @personalChatsNewChat.
  ///
  /// In en, this message translates to:
  /// **'New conversation'**
  String get personalChatsNewChat;

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

  /// No description provided for @profileMyClub.
  ///
  /// In en, this message translates to:
  /// **'My club'**
  String get profileMyClub;

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

  /// No description provided for @activityNoActivities.
  ///
  /// In en, this message translates to:
  /// **'No upcoming workouts. Find an event on the map!'**
  String get activityNoActivities;

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

  /// No description provided for @statsKm.
  ///
  /// In en, this message translates to:
  /// **'Km'**
  String get statsKm;

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

  /// No description provided for @eventsNoCitySelected.
  ///
  /// In en, this message translates to:
  /// **'Select a city in your profile to see events'**
  String get eventsNoCitySelected;

  /// No description provided for @eventsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry loading'**
  String get eventsRetry;

  /// No description provided for @eventsShowAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get eventsShowAll;

  /// No description provided for @eventsSortRelevance.
  ///
  /// In en, this message translates to:
  /// **'By relevance'**
  String get eventsSortRelevance;

  /// No description provided for @eventsSortDateAsc.
  ///
  /// In en, this message translates to:
  /// **'Date ⬆'**
  String get eventsSortDateAsc;

  /// No description provided for @eventsSortDateDesc.
  ///
  /// In en, this message translates to:
  /// **'Date ⬇'**
  String get eventsSortDateDesc;

  /// No description provided for @eventsSortPriceAsc.
  ///
  /// In en, this message translates to:
  /// **'Price ⬆'**
  String get eventsSortPriceAsc;

  /// No description provided for @eventsSortPriceDesc.
  ///
  /// In en, this message translates to:
  /// **'Price ⬇'**
  String get eventsSortPriceDesc;

  /// No description provided for @eventCategoryRaces.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get eventCategoryRaces;

  /// No description provided for @eventCategoryCompetitions.
  ///
  /// In en, this message translates to:
  /// **'Competitions'**
  String get eventCategoryCompetitions;

  /// No description provided for @eventCategoryTrainingOpen.
  ///
  /// In en, this message translates to:
  /// **'Open training'**
  String get eventCategoryTrainingOpen;

  /// No description provided for @eventCategoryClub.
  ///
  /// In en, this message translates to:
  /// **'Club'**
  String get eventCategoryClub;

  /// No description provided for @eventPriceFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get eventPriceFree;

  /// No description provided for @eventPriceRub.
  ///
  /// In en, this message translates to:
  /// **'{price} ₽'**
  String eventPriceRub(int price);

  /// No description provided for @eventCreatePrice.
  ///
  /// In en, this message translates to:
  /// **'Price (0 = free)'**
  String get eventCreatePrice;

  /// No description provided for @eventCreatePriceHint.
  ///
  /// In en, this message translates to:
  /// **'Participation fee in rubles'**
  String get eventCreatePriceHint;

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

  /// No description provided for @clubLeaderboardSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Members: {members}, Territories: {territories}'**
  String clubLeaderboardSubtitle(int members, int territories);

  /// No description provided for @clubLeaderboardPoints.
  ///
  /// In en, this message translates to:
  /// **'{points} pts'**
  String clubLeaderboardPoints(int points);

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

  /// No description provided for @rosterNoTrainer.
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get rosterNoTrainer;

  /// No description provided for @rosterPersonalClient.
  ///
  /// In en, this message translates to:
  /// **'Personal client'**
  String get rosterPersonalClient;

  /// No description provided for @rosterAssignTrainer.
  ///
  /// In en, this message translates to:
  /// **'Assign trainer'**
  String get rosterAssignTrainer;

  /// No description provided for @rosterRemoveTrainer.
  ///
  /// In en, this message translates to:
  /// **'Remove trainer'**
  String get rosterRemoveTrainer;

  /// No description provided for @rosterAddToGroup.
  ///
  /// In en, this message translates to:
  /// **'Add to group'**
  String get rosterAddToGroup;

  /// No description provided for @rosterRemoveFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get rosterRemoveFromGroup;

  /// No description provided for @rosterSelectTrainer.
  ///
  /// In en, this message translates to:
  /// **'Select trainer'**
  String get rosterSelectTrainer;

  /// No description provided for @rosterSelectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select group'**
  String get rosterSelectGroup;

  /// No description provided for @rosterAssignmentUpdated.
  ///
  /// In en, this message translates to:
  /// **'Assignment updated'**
  String get rosterAssignmentUpdated;

  /// No description provided for @scheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule Template'**
  String get scheduleTitle;

  /// No description provided for @scheduleConduct.
  ///
  /// In en, this message translates to:
  /// **'Conduct'**
  String get scheduleConduct;

  /// No description provided for @scheduleEmptyDay.
  ///
  /// In en, this message translates to:
  /// **'No trainings this day'**
  String get scheduleEmptyDay;

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

  /// No description provided for @runCadence.
  ///
  /// In en, this message translates to:
  /// **'Cadence'**
  String get runCadence;

  /// No description provided for @runCadenceValue.
  ///
  /// In en, this message translates to:
  /// **'{spm} spm'**
  String runCadenceValue(int spm);

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

  /// No description provided for @workoutDeleteAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get workoutDeleteAction;

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

  /// No description provided for @workoutFromTrainer.
  ///
  /// In en, this message translates to:
  /// **'From Trainer'**
  String get workoutFromTrainer;

  /// No description provided for @workoutAssignedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No workouts assigned by trainer yet'**
  String get workoutAssignedEmpty;

  /// No description provided for @workoutAssignedBy.
  ///
  /// In en, this message translates to:
  /// **'Trainer: {name}'**
  String workoutAssignedBy(String name);

  /// No description provided for @workoutAssignToClient.
  ///
  /// In en, this message translates to:
  /// **'Assign to client'**
  String get workoutAssignToClient;

  /// No description provided for @workoutAssignSelectClient.
  ///
  /// In en, this message translates to:
  /// **'Select client'**
  String get workoutAssignSelectClient;

  /// No description provided for @workoutAssigned.
  ///
  /// In en, this message translates to:
  /// **'Workout assigned'**
  String get workoutAssigned;

  /// No description provided for @workoutAssignError.
  ///
  /// In en, this message translates to:
  /// **'Failed to assign workout'**
  String get workoutAssignError;

  /// No description provided for @workoutStartRun.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get workoutStartRun;

  /// No description provided for @workoutEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get workoutEdit;

  /// No description provided for @workoutBlocks.
  ///
  /// In en, this message translates to:
  /// **'Workout phases'**
  String get workoutBlocks;

  /// No description provided for @workoutBlockWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get workoutBlockWarmup;

  /// No description provided for @workoutBlockWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workoutBlockWork;

  /// No description provided for @workoutBlockRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get workoutBlockRest;

  /// No description provided for @workoutBlockCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cool-down'**
  String get workoutBlockCooldown;

  /// No description provided for @workoutTodayPlan.
  ///
  /// In en, this message translates to:
  /// **'Today\'s workout'**
  String get workoutTodayPlan;

  /// No description provided for @workoutAddBlock.
  ///
  /// In en, this message translates to:
  /// **'Add phase'**
  String get workoutAddBlock;

  /// No description provided for @workoutBlockDurationMin.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get workoutBlockDurationMin;

  /// No description provided for @workoutBlockNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get workoutBlockNote;

  /// No description provided for @difficultyBeginner.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get difficultyBeginner;

  /// No description provided for @difficultyIntermediate.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get difficultyIntermediate;

  /// No description provided for @difficultyAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get difficultyAdvanced;

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

  /// No description provided for @typeFunctional.
  ///
  /// In en, this message translates to:
  /// **'Functional'**
  String get typeFunctional;

  /// No description provided for @typeAccelerations.
  ///
  /// In en, this message translates to:
  /// **'Accelerations'**
  String get typeAccelerations;

  /// No description provided for @workoutDistanceM.
  ///
  /// In en, this message translates to:
  /// **'Distance (m)'**
  String get workoutDistanceM;

  /// No description provided for @workoutHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Target HR (bpm)'**
  String get workoutHeartRate;

  /// No description provided for @workoutPaceTarget.
  ///
  /// In en, this message translates to:
  /// **'Target Pace (min/km)'**
  String get workoutPaceTarget;

  /// No description provided for @workoutRepCount.
  ///
  /// In en, this message translates to:
  /// **'Repetitions'**
  String get workoutRepCount;

  /// No description provided for @workoutRepDistance.
  ///
  /// In en, this message translates to:
  /// **'Rep Distance (m)'**
  String get workoutRepDistance;

  /// No description provided for @workoutExercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get workoutExercise;

  /// No description provided for @workoutInstructions.
  ///
  /// In en, this message translates to:
  /// **'Instructions (how to)'**
  String get workoutInstructions;

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

  /// No description provided for @workoutTargetValueDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance (meters)'**
  String get workoutTargetValueDistance;

  /// No description provided for @workoutTargetValueTime.
  ///
  /// In en, this message translates to:
  /// **'Duration (minutes)'**
  String get workoutTargetValueTime;

  /// No description provided for @workoutTargetValuePace.
  ///
  /// In en, this message translates to:
  /// **'Pace (sec/km)'**
  String get workoutTargetValuePace;

  /// No description provided for @workoutTargetZone.
  ///
  /// In en, this message translates to:
  /// **'Target Zone'**
  String get workoutTargetZone;

  /// No description provided for @zoneNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get zoneNone;

  /// No description provided for @zoneZ1.
  ///
  /// In en, this message translates to:
  /// **'Z1 Recovery'**
  String get zoneZ1;

  /// No description provided for @zoneZ2.
  ///
  /// In en, this message translates to:
  /// **'Z2 Easy'**
  String get zoneZ2;

  /// No description provided for @zoneZ3.
  ///
  /// In en, this message translates to:
  /// **'Z3 Aerobic'**
  String get zoneZ3;

  /// No description provided for @zoneZ4.
  ///
  /// In en, this message translates to:
  /// **'Z4 Threshold'**
  String get zoneZ4;

  /// No description provided for @zoneZ5.
  ///
  /// In en, this message translates to:
  /// **'Z5 Maximum'**
  String get zoneZ5;

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

  /// No description provided for @watchNotPaired.
  ///
  /// In en, this message translates to:
  /// **'Watch not connected'**
  String get watchNotPaired;

  /// No description provided for @mapActiveClub.
  ///
  /// In en, this message translates to:
  /// **'Club: {name}'**
  String mapActiveClub(String name);

  /// No description provided for @mapNoActiveClub.
  ///
  /// In en, this message translates to:
  /// **'No club'**
  String get mapNoActiveClub;

  /// No description provided for @mapCurrentTerritory.
  ///
  /// In en, this message translates to:
  /// **'Territory: {name}'**
  String mapCurrentTerritory(String name);

  /// No description provided for @mapNoTerritory.
  ///
  /// In en, this message translates to:
  /// **'No territory'**
  String get mapNoTerritory;

  /// No description provided for @selectClub.
  ///
  /// In en, this message translates to:
  /// **'Select club'**
  String get selectClub;

  /// No description provided for @messagesScrollToBottom.
  ///
  /// In en, this message translates to:
  /// **'Scroll to bottom'**
  String get messagesScrollToBottom;

  /// No description provided for @trainerGroupsTab.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get trainerGroupsTab;

  /// No description provided for @trainerPersonalTab.
  ///
  /// In en, this message translates to:
  /// **'Personal'**
  String get trainerPersonalTab;

  /// No description provided for @trainerBadge.
  ///
  /// In en, this message translates to:
  /// **'Trainer'**
  String get trainerBadge;

  /// No description provided for @trainerNoPrivateClients.
  ///
  /// In en, this message translates to:
  /// **'No private clients'**
  String get trainerNoPrivateClients;

  /// No description provided for @trainerNoPersonalTrainer.
  ///
  /// In en, this message translates to:
  /// **'No personal trainer'**
  String get trainerNoPersonalTrainer;

  /// No description provided for @memberActionWriteAsTrainer.
  ///
  /// In en, this message translates to:
  /// **'Write as trainer'**
  String get memberActionWriteAsTrainer;

  /// No description provided for @memberActionChangeRole.
  ///
  /// In en, this message translates to:
  /// **'Change role'**
  String get memberActionChangeRole;

  /// No description provided for @memberActionPrivateMessages.
  ///
  /// In en, this message translates to:
  /// **'Private messages'**
  String get memberActionPrivateMessages;

  /// No description provided for @memberActionPrivateMessagesHint.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get memberActionPrivateMessagesHint;

  /// No description provided for @directChatWaitForTrainer.
  ///
  /// In en, this message translates to:
  /// **'Your trainer will write you first'**
  String get directChatWaitForTrainer;

  /// No description provided for @trainerGroupsTitle.
  ///
  /// In en, this message translates to:
  /// **'Groups'**
  String get trainerGroupsTitle;

  /// No description provided for @trainerCreateGroup.
  ///
  /// In en, this message translates to:
  /// **'Create Group'**
  String get trainerCreateGroup;

  /// No description provided for @trainerGroupName.
  ///
  /// In en, this message translates to:
  /// **'Group Name'**
  String get trainerGroupName;

  /// No description provided for @trainerGroupNameHint.
  ///
  /// In en, this message translates to:
  /// **'Enter group name'**
  String get trainerGroupNameHint;

  /// No description provided for @trainerSelectMembers.
  ///
  /// In en, this message translates to:
  /// **'Select Members'**
  String get trainerSelectMembers;

  /// No description provided for @trainerNoGroups.
  ///
  /// In en, this message translates to:
  /// **'No groups yet'**
  String get trainerNoGroups;

  /// No description provided for @trainerGroupCreated.
  ///
  /// In en, this message translates to:
  /// **'Group created successfully'**
  String get trainerGroupCreated;

  /// No description provided for @trainerCreateGroupError.
  ///
  /// In en, this message translates to:
  /// **'Could not create group: {error}'**
  String trainerCreateGroupError(String error);

  /// No description provided for @errorUnauthorizedTitle.
  ///
  /// In en, this message translates to:
  /// **'Authorization error'**
  String get errorUnauthorizedTitle;

  /// No description provided for @errorUnauthorizedMessage.
  ///
  /// In en, this message translates to:
  /// **'Session expired or invalid. Please sign in again.'**
  String get errorUnauthorizedMessage;

  /// No description provided for @errorUnauthorizedAction.
  ///
  /// In en, this message translates to:
  /// **'Sign in again'**
  String get errorUnauthorizedAction;

  /// No description provided for @workoutIntensityZone.
  ///
  /// In en, this message translates to:
  /// **'Intensity Zone'**
  String get workoutIntensityZone;

  /// No description provided for @runRPE.
  ///
  /// In en, this message translates to:
  /// **'Effort (RPE)'**
  String get runRPE;

  /// No description provided for @notesForCoach.
  ///
  /// In en, this message translates to:
  /// **'Notes for coach'**
  String get notesForCoach;

  /// No description provided for @recoveryType.
  ///
  /// In en, this message translates to:
  /// **'Recovery Type'**
  String get recoveryType;

  /// No description provided for @mediaUrlInstruction.
  ///
  /// In en, this message translates to:
  /// **'Video Instruction'**
  String get mediaUrlInstruction;

  /// No description provided for @surfaceRoad.
  ///
  /// In en, this message translates to:
  /// **'Road'**
  String get surfaceRoad;

  /// No description provided for @surfaceTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get surfaceTrack;

  /// No description provided for @surfaceTrail.
  ///
  /// In en, this message translates to:
  /// **'Trail'**
  String get surfaceTrail;

  /// No description provided for @workoutSurface.
  ///
  /// In en, this message translates to:
  /// **'Surface'**
  String get workoutSurface;

  /// No description provided for @segmentTypeWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warmup'**
  String get segmentTypeWarmup;

  /// No description provided for @segmentTypeRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get segmentTypeRun;

  /// No description provided for @segmentTypeRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get segmentTypeRest;

  /// No description provided for @segmentTypeCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get segmentTypeCooldown;

  /// No description provided for @recoveryJog.
  ///
  /// In en, this message translates to:
  /// **'Jog'**
  String get recoveryJog;

  /// No description provided for @recoveryWalk.
  ///
  /// In en, this message translates to:
  /// **'Walk'**
  String get recoveryWalk;

  /// No description provided for @recoveryStand.
  ///
  /// In en, this message translates to:
  /// **'Stand'**
  String get recoveryStand;

  /// No description provided for @durationTime.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get durationTime;

  /// No description provided for @durationDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get durationDistance;

  /// No description provided for @durationManual.
  ///
  /// In en, this message translates to:
  /// **'Manual (Lap)'**
  String get durationManual;

  /// No description provided for @filtersEventType.
  ///
  /// In en, this message translates to:
  /// **'Event type'**
  String get filtersEventType;

  /// No description provided for @filtersDifficulty.
  ///
  /// In en, this message translates to:
  /// **'Difficulty'**
  String get filtersDifficulty;

  /// No description provided for @eventsEmptyFiltered.
  ///
  /// In en, this message translates to:
  /// **'No events match the selected filters'**
  String get eventsEmptyFiltered;

  /// No description provided for @eventsResetFilters.
  ///
  /// In en, this message translates to:
  /// **'Reset filters'**
  String get eventsResetFilters;

  /// No description provided for @eventTimeToday.
  ///
  /// In en, this message translates to:
  /// **'Today at {time}'**
  String eventTimeToday(String time);

  /// No description provided for @eventTimeTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow at {time}'**
  String eventTimeTomorrow(String time);

  /// No description provided for @eventTimeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'In {minutes} min'**
  String eventTimeInMinutes(int minutes);

  /// No description provided for @eventTimeInHoursMinutes.
  ///
  /// In en, this message translates to:
  /// **'In {hours} h {minutes} min'**
  String eventTimeInHoursMinutes(int hours, int minutes);

  /// No description provided for @runClubNotSelected.
  ///
  /// In en, this message translates to:
  /// **'Not selected'**
  String get runClubNotSelected;

  /// No description provided for @runSelectTaskTitle.
  ///
  /// In en, this message translates to:
  /// **'Select today\'s task'**
  String get runSelectTaskTitle;

  /// No description provided for @runNoTask.
  ///
  /// In en, this message translates to:
  /// **'Just a run (no task)'**
  String get runNoTask;

  /// No description provided for @runStatsTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Total time'**
  String get runStatsTotalTime;

  /// No description provided for @runCountedTerritoryForClub.
  ///
  /// In en, this message translates to:
  /// **'Territory points for {clubName}'**
  String runCountedTerritoryForClub(String clubName);

  /// No description provided for @loadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// No description provided for @findPeople.
  ///
  /// In en, this message translates to:
  /// **'Find people'**
  String get findPeople;

  /// No description provided for @peopleSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search by name...'**
  String get peopleSearchHint;

  /// No description provided for @peopleSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Enter at least 2 characters to search'**
  String get peopleSearchPlaceholder;

  /// No description provided for @peopleSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No users found'**
  String get peopleSearchEmpty;

  /// No description provided for @peopleMyCity.
  ///
  /// In en, this message translates to:
  /// **'My city'**
  String get peopleMyCity;

  /// No description provided for @messageComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Messaging — coming soon'**
  String get messageComingSoon;

  /// No description provided for @profileVisibilityToggle.
  ///
  /// In en, this message translates to:
  /// **'Public profile'**
  String get profileVisibilityToggle;

  /// No description provided for @profileVisibilityHint.
  ///
  /// In en, this message translates to:
  /// **'Other users can find you in search'**
  String get profileVisibilityHint;

  /// No description provided for @publicProfileRuns.
  ///
  /// In en, this message translates to:
  /// **'runs'**
  String get publicProfileRuns;

  /// No description provided for @publicProfileKm.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get publicProfileKm;

  /// No description provided for @publicProfilePoints.
  ///
  /// In en, this message translates to:
  /// **'points'**
  String get publicProfilePoints;

  /// No description provided for @publicProfileRecentRuns.
  ///
  /// In en, this message translates to:
  /// **'Recent runs'**
  String get publicProfileRecentRuns;

  /// No description provided for @publicProfileNoRuns.
  ///
  /// In en, this message translates to:
  /// **'No runs yet'**
  String get publicProfileNoRuns;

  /// No description provided for @clientRunsTitle.
  ///
  /// In en, this message translates to:
  /// **'Client runs'**
  String get clientRunsTitle;

  /// No description provided for @clientRunsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No completed runs yet'**
  String get clientRunsEmpty;

  /// No description provided for @clientRunsViewResults.
  ///
  /// In en, this message translates to:
  /// **'View runs'**
  String get clientRunsViewResults;

  /// No description provided for @clientRunsDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get clientRunsDistance;

  /// No description provided for @clientRunsRpe.
  ///
  /// In en, this message translates to:
  /// **'RPE'**
  String get clientRunsRpe;

  /// No description provided for @clientRunsAssignment.
  ///
  /// In en, this message translates to:
  /// **'Assignment'**
  String get clientRunsAssignment;

  /// No description provided for @workoutAssignSelectGroup.
  ///
  /// In en, this message translates to:
  /// **'Select group'**
  String get workoutAssignSelectGroup;

  /// No description provided for @workoutAssignedToGroup.
  ///
  /// In en, this message translates to:
  /// **'Assigned to group'**
  String get workoutAssignedToGroup;

  /// No description provided for @workoutAssignTabClient.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get workoutAssignTabClient;

  /// No description provided for @workoutAssignTabGroup.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get workoutAssignTabGroup;

  /// No description provided for @updateAvailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Update available'**
  String get updateAvailableTitle;

  /// No description provided for @updateDescription.
  ///
  /// In en, this message translates to:
  /// **'A new version is available. Check your email for the download link.'**
  String get updateDescription;

  /// No description provided for @updateCurrentVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'Current version'**
  String get updateCurrentVersionLabel;

  /// No description provided for @updateLatestVersionLabel.
  ///
  /// In en, this message translates to:
  /// **'New version'**
  String get updateLatestVersionLabel;

  /// No description provided for @updateClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get updateClose;

  /// No description provided for @updateInstall.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get updateInstall;

  /// No description provided for @calendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Training schedule'**
  String get calendarTitle;

  /// No description provided for @calendarRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get calendarRun;

  /// No description provided for @calendarEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get calendarEvent;

  /// No description provided for @calendarChoose.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get calendarChoose;

  /// No description provided for @mapLayerTerritories.
  ///
  /// In en, this message translates to:
  /// **'Territories'**
  String get mapLayerTerritories;

  /// No description provided for @mapLayerRaces.
  ///
  /// In en, this message translates to:
  /// **'Races'**
  String get mapLayerRaces;

  /// No description provided for @mapLayerLocal.
  ///
  /// In en, this message translates to:
  /// **'Local events'**
  String get mapLayerLocal;

  /// No description provided for @mapLayerVenues.
  ///
  /// In en, this message translates to:
  /// **'Where to run'**
  String get mapLayerVenues;

  /// No description provided for @mapLayerRoutes.
  ///
  /// In en, this message translates to:
  /// **'Routes'**
  String get mapLayerRoutes;

  /// No description provided for @mapLayerRoutesComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get mapLayerRoutesComingSoon;

  /// No description provided for @editProfileUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get editProfileUsername;

  /// No description provided for @editProfileUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'lowercase letters, digits, underscore • 3–30 chars'**
  String get editProfileUsernameHint;

  /// No description provided for @editProfileUsernameConflict.
  ///
  /// In en, this message translates to:
  /// **'This username is already taken'**
  String get editProfileUsernameConflict;

  /// No description provided for @editProfilePhotoChange.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get editProfilePhotoChange;

  /// No description provided for @editProfilePhotoSelected.
  ///
  /// In en, this message translates to:
  /// **'Photo selected'**
  String get editProfilePhotoSelected;

  /// No description provided for @editProfilePhotoUploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading photo...'**
  String get editProfilePhotoUploading;

  /// No description provided for @myClubsMySection.
  ///
  /// In en, this message translates to:
  /// **'My clubs'**
  String get myClubsMySection;

  /// No description provided for @myClubsFind.
  ///
  /// In en, this message translates to:
  /// **'Find a club'**
  String get myClubsFind;

  /// No description provided for @myClubsAsTrainer.
  ///
  /// In en, this message translates to:
  /// **'Clubs where I\'m a trainer'**
  String get myClubsAsTrainer;

  /// No description provided for @trainerBecomeStudent.
  ///
  /// In en, this message translates to:
  /// **'Become a student'**
  String get trainerBecomeStudent;

  /// No description provided for @trainerRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent'**
  String get trainerRequestSent;

  /// No description provided for @trainerCancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get trainerCancelRequest;

  /// No description provided for @trainerYouAreStudent.
  ///
  /// In en, this message translates to:
  /// **'You are a student'**
  String get trainerYouAreStudent;

  /// No description provided for @trainerReapply.
  ///
  /// In en, this message translates to:
  /// **'Re-apply'**
  String get trainerReapply;

  /// No description provided for @trainerRequestsScreen.
  ///
  /// In en, this message translates to:
  /// **'Client Requests'**
  String get trainerRequestsScreen;

  /// No description provided for @trainerIncomingRequests.
  ///
  /// In en, this message translates to:
  /// **'Incoming requests'**
  String get trainerIncomingRequests;

  /// No description provided for @trainerActiveClients.
  ///
  /// In en, this message translates to:
  /// **'Active clients'**
  String get trainerActiveClients;

  /// No description provided for @trainerAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get trainerAccept;

  /// No description provided for @trainerReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get trainerReject;

  /// No description provided for @trainerClientsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} clients'**
  String trainerClientsCount(int count);

  /// No description provided for @trainerNoRequests.
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get trainerNoRequests;

  /// No description provided for @trainerNoClientsYet.
  ///
  /// In en, this message translates to:
  /// **'No active clients yet'**
  String get trainerNoClientsYet;

  /// No description provided for @myTrainersScreen.
  ///
  /// In en, this message translates to:
  /// **'My Trainers'**
  String get myTrainersScreen;

  /// No description provided for @myTrainersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No trainers yet'**
  String get myTrainersEmpty;

  /// No description provided for @trainerRequestAccepted.
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get trainerRequestAccepted;

  /// No description provided for @trainerRequestRejectedMsg.
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get trainerRequestRejectedMsg;

  /// No description provided for @workoutCreationTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Workout'**
  String get workoutCreationTitle;

  /// No description provided for @workoutTypeSelectTitle.
  ///
  /// In en, this message translates to:
  /// **'Select workout type'**
  String get workoutTypeSelectTitle;

  /// No description provided for @workoutTypeEasyRun.
  ///
  /// In en, this message translates to:
  /// **'Easy Run'**
  String get workoutTypeEasyRun;

  /// No description provided for @workoutTypeLongRun.
  ///
  /// In en, this message translates to:
  /// **'Long Run'**
  String get workoutTypeLongRun;

  /// No description provided for @workoutTypeIntervals.
  ///
  /// In en, this message translates to:
  /// **'Intervals'**
  String get workoutTypeIntervals;

  /// No description provided for @workoutTypeProgression.
  ///
  /// In en, this message translates to:
  /// **'Progression Run'**
  String get workoutTypeProgression;

  /// No description provided for @workoutTypeRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery Run'**
  String get workoutTypeRecovery;

  /// No description provided for @workoutTypeHillRun.
  ///
  /// In en, this message translates to:
  /// **'Hill Run'**
  String get workoutTypeHillRun;

  /// No description provided for @workoutParamsDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get workoutParamsDuration;

  /// No description provided for @workoutParamsDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance (km)'**
  String get workoutParamsDistance;

  /// No description provided for @workoutParamsPace.
  ///
  /// In en, this message translates to:
  /// **'Pace (min/km)'**
  String get workoutParamsPace;

  /// No description provided for @workoutParamsHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate (bpm)'**
  String get workoutParamsHeartRate;

  /// No description provided for @workoutParamsReps.
  ///
  /// In en, this message translates to:
  /// **'Reps'**
  String get workoutParamsReps;

  /// No description provided for @workoutParamsRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get workoutParamsRest;

  /// No description provided for @workoutParamsRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get workoutParamsRecovery;

  /// No description provided for @workoutParamsRestMin.
  ///
  /// In en, this message translates to:
  /// **'Rest (min)'**
  String get workoutParamsRestMin;

  /// No description provided for @workoutParamsRestM.
  ///
  /// In en, this message translates to:
  /// **'Rest (m)'**
  String get workoutParamsRestM;

  /// No description provided for @workoutParamsWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up (km/m)'**
  String get workoutParamsWarmup;

  /// No description provided for @workoutParamsHillElevation.
  ///
  /// In en, this message translates to:
  /// **'Elevation (m)'**
  String get workoutParamsHillElevation;

  /// No description provided for @workoutParamsSegment.
  ///
  /// In en, this message translates to:
  /// **'Segment {n}'**
  String workoutParamsSegment(int n);

  /// No description provided for @workoutParamsAddSegment.
  ///
  /// In en, this message translates to:
  /// **'+ Add segment'**
  String get workoutParamsAddSegment;

  /// No description provided for @workoutCooldownNone.
  ///
  /// In en, this message translates to:
  /// **'Cooldown — none'**
  String get workoutCooldownNone;

  /// No description provided for @workoutCooldownSelect.
  ///
  /// In en, this message translates to:
  /// **'Cooldown'**
  String get workoutCooldownSelect;

  /// No description provided for @workoutCooldownMinutes.
  ///
  /// In en, this message translates to:
  /// **'Set minutes'**
  String get workoutCooldownMinutes;

  /// No description provided for @workoutCooldownMetres.
  ///
  /// In en, this message translates to:
  /// **'Set metres'**
  String get workoutCooldownMetres;

  /// No description provided for @workoutCooldownNo.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get workoutCooldownNo;

  /// No description provided for @workoutCooldownValueMin.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get workoutCooldownValueMin;

  /// No description provided for @workoutCooldownValueM.
  ///
  /// In en, this message translates to:
  /// **'Distance (m)'**
  String get workoutCooldownValueM;

  /// No description provided for @workoutScheduleTitle.
  ///
  /// In en, this message translates to:
  /// **'Schedule this workout?'**
  String get workoutScheduleTitle;

  /// No description provided for @workoutScheduleYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get workoutScheduleYes;

  /// No description provided for @workoutScheduleNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get workoutScheduleNo;

  /// No description provided for @workoutSavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Workout saved'**
  String get workoutSavedTitle;

  /// No description provided for @workoutSavedStart.
  ///
  /// In en, this message translates to:
  /// **'Start workout'**
  String get workoutSavedStart;

  /// No description provided for @workoutSavedSaveTemplate.
  ///
  /// In en, this message translates to:
  /// **'Save as template'**
  String get workoutSavedSaveTemplate;

  /// No description provided for @workoutTemplateSaved.
  ///
  /// In en, this message translates to:
  /// **'Template saved'**
  String get workoutTemplateSaved;

  /// No description provided for @workoutShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share workout'**
  String get workoutShareTitle;

  /// No description provided for @workoutShareAsTrainer.
  ///
  /// In en, this message translates to:
  /// **'As trainer'**
  String get workoutShareAsTrainer;

  /// No description provided for @workoutShareWithFriends.
  ///
  /// In en, this message translates to:
  /// **'With friends'**
  String get workoutShareWithFriends;

  /// No description provided for @workoutShareSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get workoutShareSend;

  /// No description provided for @workoutIncomingShares.
  ///
  /// In en, this message translates to:
  /// **'Incoming workouts'**
  String get workoutIncomingShares;

  /// No description provided for @workoutShareFrom.
  ///
  /// In en, this message translates to:
  /// **'From: {name}'**
  String workoutShareFrom(String name);

  /// No description provided for @workoutShareAccept.
  ///
  /// In en, this message translates to:
  /// **'Add to my workouts'**
  String get workoutShareAccept;

  /// No description provided for @workoutShareAccepted.
  ///
  /// In en, this message translates to:
  /// **'Workout added'**
  String get workoutShareAccepted;

  /// No description provided for @workoutFavoriteAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to saved'**
  String get workoutFavoriteAdded;

  /// No description provided for @workoutFavoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from saved'**
  String get workoutFavoriteRemoved;

  /// No description provided for @workoutTabMy.
  ///
  /// In en, this message translates to:
  /// **'My'**
  String get workoutTabMy;

  /// No description provided for @workoutTabSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get workoutTabSaved;

  /// No description provided for @workoutAddToPlan.
  ///
  /// In en, this message translates to:
  /// **'Add to plan'**
  String get workoutAddToPlan;

  /// No description provided for @workoutSaveAsNew.
  ///
  /// In en, this message translates to:
  /// **'Save as new'**
  String get workoutSaveAsNew;

  /// No description provided for @workoutMetricDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get workoutMetricDistance;

  /// No description provided for @workoutMetricPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get workoutMetricPace;

  /// No description provided for @workoutMetricDuration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get workoutMetricDuration;

  /// No description provided for @workoutMetricHR.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get workoutMetricHR;

  /// No description provided for @workoutFinish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get workoutFinish;

  /// No description provided for @workoutPhaseWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm-up'**
  String get workoutPhaseWarmup;

  /// No description provided for @workoutPhaseWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get workoutPhaseWork;

  /// No description provided for @workoutPhaseRest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get workoutPhaseRest;

  /// No description provided for @workoutSegment.
  ///
  /// In en, this message translates to:
  /// **'Segment'**
  String get workoutSegment;
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
