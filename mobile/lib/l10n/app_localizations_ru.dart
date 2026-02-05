// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Runterra';

  @override
  String get navMap => 'Карта';

  @override
  String get navRun => 'Пробежка';

  @override
  String get navMessages => 'Сообщения';

  @override
  String get navEvents => 'События';

  @override
  String get navProfile => 'Профиль';

  @override
  String get errorLoadTitle => 'Ошибка загрузки';

  @override
  String get retry => 'Повторить';

  @override
  String get errorTimeoutMessage =>
      'Превышен таймаут подключения.\n\nУбедитесь, что:\n1. Backend сервер запущен (npm run dev в папке backend)\n2. Сервер слушает на всех интерфейсах (0.0.0.0)\n3. Нет проблем с сетью или файрволом';

  @override
  String get errorConnectionMessage =>
      'Не удалось подключиться к серверу.\n\nУбедитесь, что backend сервер запущен и доступен.';

  @override
  String errorGeneric(String message) {
    return 'Ошибка: $message';
  }

  @override
  String get profileCityRequired =>
      'Укажите город в профиле, чтобы участвовать в чате';

  @override
  String get messageHint => 'Сообщение...';

  @override
  String messagesLoadError(String error) {
    return 'Ошибка загрузки сообщений: $error';
  }

  @override
  String get messagesTitle => 'Сообщения';

  @override
  String get cityLabel => 'Город';

  @override
  String get tabPersonal => 'Личные';

  @override
  String get tabClub => 'Клуб';

  @override
  String get tabCoach => 'Тренер';

  @override
  String get personalChatsEmpty => 'Пока нет личных сообщений';

  @override
  String get coachMessagesEmpty => 'Пока нет сообщений от тренера';

  @override
  String get noClubChats =>
      'Нет чатов клубов\n\nВы пока не состоите ни в одном клубе';

  @override
  String get noNotifications => 'Нет уведомлений';

  @override
  String clubChatsLoadError(String error) {
    return 'Ошибка загрузки чатов клубов: $error';
  }

  @override
  String notificationsLoadError(String error) {
    return 'Ошибка загрузки уведомлений: $error';
  }

  @override
  String get profileTitle => 'Личный кабинет';

  @override
  String get profileNotFound => 'Данные профиля не найдены';

  @override
  String get profileConnectionError =>
      'Не удалось подключиться к серверу.\n\nУбедитесь, что:\n1. Backend сервер запущен (npm run dev в папке backend)\n2. Для Android эмулятора используется адрес 10.0.2.2:3000\n3. Для физического устройства используйте IP адрес компьютера';

  @override
  String get logoutTitle => 'Выход';

  @override
  String get logoutConfirm => 'Вы уверены, что хотите выйти из аккаунта?';

  @override
  String get cancel => 'Отмена';

  @override
  String get logout => 'Выйти';

  @override
  String get headerMercenary => 'Меркатель';

  @override
  String get headerNoClub => 'Без клуба';

  @override
  String get roleMember => 'Участник';

  @override
  String get roleModerator => 'Модератор';

  @override
  String get roleLeader => 'Лидер';

  @override
  String get quickOpenMap => 'Открыть карту';

  @override
  String get quickFindTraining => 'Найти тренировку';

  @override
  String get quickStartRun => 'Начать пробежку';

  @override
  String get quickFindClub => 'Найти клуб';

  @override
  String get quickCreateClub => 'Создать клуб';

  @override
  String get activityNext => 'Ближайшая тренировка';

  @override
  String get activityLast => 'Последняя активность';

  @override
  String get activityDefaultName => 'Тренировка';

  @override
  String get activityDefaultActivity => 'Активность';

  @override
  String get openOnMap => 'Открыть на карте';

  @override
  String get activityStatusPlanned => 'Записан';

  @override
  String get activityStatusInProgress => 'В процессе';

  @override
  String get activityStatusCompleted => 'Завершено';

  @override
  String get activityStatusCancelled => 'Отменено';

  @override
  String get activityResultCounted => 'Засчитано';

  @override
  String get activityResultNotCounted => 'Не засчитано';

  @override
  String get settingsLocation => 'Геолокация';

  @override
  String get settingsLocationAllowed => 'Разрешено';

  @override
  String get settingsLocationDenied => 'Не разрешено';

  @override
  String get settingsVisibility => 'Видимость профиля';

  @override
  String get settingsVisible => 'Видимый';

  @override
  String get settingsHidden => 'Скрытый';

  @override
  String get settingsLogout => 'Выйти из аккаунта';

  @override
  String get settingsDeleteAccount => 'Удалить аккаунт';

  @override
  String get statsTrainings => 'Тренировки';

  @override
  String get statsTerritories => 'Территории';

  @override
  String get statsPoints => 'Баллы';

  @override
  String get notificationsSectionTitle => 'Уведомления';

  @override
  String get eventsTitle => 'События';

  @override
  String get eventsLoadError => 'Ошибка загрузки событий';

  @override
  String get eventsEmpty => 'События не найдены';

  @override
  String get eventsEmptyHint => 'Попробуйте изменить фильтры';

  @override
  String get eventsCreateTodo => 'Создание события - TODO';

  @override
  String get eventsCreateTooltip => 'Создать событие';

  @override
  String get eventCreateTitle => 'Создать событие';

  @override
  String get eventCreateName => 'Название события';

  @override
  String get eventCreateNameRequired => 'Укажите название события';

  @override
  String get eventCreateType => 'Тип события';

  @override
  String get eventCreateDate => 'Дата';

  @override
  String get eventCreateTime => 'Время';

  @override
  String get eventCreateCity => 'Город';

  @override
  String get eventCreateCityRequired => 'Сначала выберите город в профиле';

  @override
  String get eventCreateOrganizerId => 'ID организатора';

  @override
  String get eventCreateOrganizerRequired => 'Укажите организатора';

  @override
  String get eventCreateOrganizerType => 'Тип организатора';

  @override
  String get eventCreateOrganizerClub => 'Клуб';

  @override
  String get eventCreateOrganizerTrainer => 'Тренер';

  @override
  String get eventCreateLocationName => 'Название локации';

  @override
  String get eventCreateLatitude => 'Широта';

  @override
  String get eventCreateLongitude => 'Долгота';

  @override
  String get eventCreateCoordinatesRequired => 'Укажите координаты';

  @override
  String get eventCreateCoordinatesInvalid => 'Некорректные координаты';

  @override
  String get eventCreateParticipantLimit => 'Лимит участников';

  @override
  String get eventCreateLimitInvalid => 'Некорректный лимит';

  @override
  String get eventCreateDescription => 'Описание';

  @override
  String get eventCreateSave => 'Создать';

  @override
  String get eventCreateSuccess => 'Событие создано';

  @override
  String eventCreateError(String message) {
    return 'Не удалось создать событие: $message';
  }

  @override
  String get filterToday => 'Сегодня';

  @override
  String get filterTomorrow => 'Завтра';

  @override
  String get filter7days => '7 дней';

  @override
  String get filterOnlyOpen => 'Только открытые';

  @override
  String get eventTypeTraining => 'Тренировка';

  @override
  String get eventTypeGroupRun => 'Совместный бег';

  @override
  String get eventTypeClubEvent => 'Клубное событие';

  @override
  String get eventTypeOpenEvent => 'Открытое событие';

  @override
  String get eventStatusOpen => 'Открыто';

  @override
  String get eventStatusFull => 'Нет мест';

  @override
  String get eventStatusCancelled => 'Отменено';

  @override
  String get eventStatusCompleted => 'Завершено';

  @override
  String get eventDifficultyBeginner => 'Новичок';

  @override
  String get eventDifficultyIntermediate => 'Любитель';

  @override
  String get eventDifficultyAdvanced => 'Опытный';

  @override
  String get eventDetailsTitle => 'Событие';

  @override
  String get eventDescription => 'Описание';

  @override
  String get eventInfo => 'Информация';

  @override
  String get eventType => 'Тип';

  @override
  String get eventDateTime => 'Дата и время';

  @override
  String get eventLocation => 'Локация';

  @override
  String get eventOrganizer => 'Организатор';

  @override
  String get eventDifficulty => 'Уровень подготовки';

  @override
  String get eventTerritory => 'Территория';

  @override
  String get eventTerritoryLinked => 'Привязано к территории';

  @override
  String get eventStartPoint => 'Точка старта';

  @override
  String get eventMapTodo => 'Карта (TODO)';

  @override
  String get eventParticipation => 'Участие';

  @override
  String get eventJoin => 'Присоединиться';

  @override
  String get eventJoinTodo => 'Записываем...';

  @override
  String get eventJoinInProgress => 'Записываем...';

  @override
  String get eventJoinSuccess => 'Вы записаны';

  @override
  String eventJoinError(String message) {
    return 'Не удалось записаться: $message';
  }

  @override
  String get eventYouAreRegistered => 'Вы записаны';

  @override
  String get eventYouParticipate => 'Вы участвуете';

  @override
  String get eventLeave => 'Отменить участие';

  @override
  String get eventLeaveSuccess => 'Участие отменено';

  @override
  String eventLeaveError(String message) {
    return 'Не удалось отменить участие: $message';
  }

  @override
  String get eventCheckInSuccess => 'Отметка о прибытии принята';

  @override
  String eventCheckInError(String message) {
    return 'Не удалось отметиться: $message';
  }

  @override
  String get eventNoPlaces => 'Нет свободных мест';

  @override
  String get eventCancelled => 'Событие отменено';

  @override
  String eventOrganizerLabel(String id) {
    return 'Организатор: $id';
  }

  @override
  String participantsTitle(int count) {
    return 'Участники ($count)';
  }

  @override
  String get participantsNone => 'Пока нет участников';

  @override
  String participantsMore(int count) {
    return 'И ещё $count участников';
  }

  @override
  String participantN(int n) {
    return 'Участник $n';
  }

  @override
  String get mapTitle => 'Карта';

  @override
  String get mapFiltersTooltip => 'Фильтры';

  @override
  String get mapClubsSheetTitle => 'Клубы';

  @override
  String get mapClubsEmpty => 'В этом городе пока нет клубов';

  @override
  String get mapMyLocationTooltip => 'Моё местоположение';

  @override
  String get mapLocationDeniedSnackbar =>
      'Доступ к геолокации не предоставлен. Используется позиция по умолчанию.';

  @override
  String mapLoadErrorSnackbar(String error) {
    return 'Ошибка загрузки данных: $error';
  }

  @override
  String get mapNoLocationSnackbar => 'Нет доступа к геолокации';

  @override
  String mapLocationErrorSnackbar(String error) {
    return 'Ошибка геолокации: $error';
  }

  @override
  String get filtersTitle => 'Фильтры';

  @override
  String get filtersDate => '📅 Дата';

  @override
  String get filtersToday => 'Сегодня';

  @override
  String get filtersWeek => 'Неделя';

  @override
  String get filtersMyClub => '🏃 Мой клуб';

  @override
  String get filtersActiveTerritories => '🔥 Только активные территории';

  @override
  String get territoryCaptured => 'Захвачена клубом';

  @override
  String get territoryFree => 'Нейтральная';

  @override
  String get territoryContested => 'Оспариваемая';

  @override
  String get territoryLocked => 'Заблокирована';

  @override
  String get territoryUnknown => 'Неизвестно';

  @override
  String territoryOwnerLabel(String id) {
    return 'Клуб-владелец: $id';
  }

  @override
  String get territoryHoldTodo => 'До удержания: TODO';

  @override
  String get territoryViewTrainings => 'Посмотреть тренировки';

  @override
  String get territoryHelpCapture => 'Помочь захватить';

  @override
  String get territoryMore => 'Подробнее';

  @override
  String get runTitle => 'Пробежка';

  @override
  String get runStart => 'Начать пробежку';

  @override
  String get runFinish => 'Завершить';

  @override
  String get runFinishing => 'Завершение...';

  @override
  String get runDone => 'Готово 🎉';

  @override
  String get runGpsSearching => 'Поиск сигнала';

  @override
  String get runGpsRecording => 'Запись';

  @override
  String get runGpsError => 'Ошибка GPS';

  @override
  String runForActivity(String activityId) {
    return 'Пробежка будет засчитана для тренировки \"$activityId\"';
  }

  @override
  String get runCountedTraining => 'Участие в тренировке засчитано';

  @override
  String get runCountedTerritory => 'Вклад в территорию';

  @override
  String get runReady => 'Готово';

  @override
  String get runStartError => 'Ошибка при запуске пробежки';

  @override
  String get runStartPermissionDenied =>
      'Разрешение на геолокацию не предоставлено.\n\nДля Windows: откройте Настройки → Конфиденциальность → Расположение → Разрешения приложений и включите доступ для Runterra.\n\nДля Android: разрешите доступ к геолокации при запросе.';

  @override
  String get runStartPermanentlyDenied =>
      'Доступ к геолокации заблокирован.\n\nПожалуйста, включите разрешение в настройках устройства:\nWindows: Настройки → Конфиденциальность → Расположение\nAndroid: Настройки → Приложения → Runterra → Разрешения';

  @override
  String get runStartServiceDisabled =>
      'Служба геолокации отключена.\n\nПожалуйста, включите геолокацию в настройках устройства.';

  @override
  String runStartErrorGeneric(String error) {
    return 'Ошибка при запуске пробежки:\n$error';
  }

  @override
  String runFinishError(String error) {
    return 'Ошибка при завершении пробежки: $error';
  }

  @override
  String get runDuration => 'Длительность';

  @override
  String get runDistance => 'Дистанция';

  @override
  String get runPace => 'Темп';

  @override
  String runPaceValue(String pace) {
    return '$pace /км';
  }

  @override
  String get runAvgSpeed => 'Ср. скорость';

  @override
  String runAvgSpeedValue(String speed) {
    return '$speed км/ч';
  }

  @override
  String get runCalories => 'Калории';

  @override
  String runCaloriesValue(int calories) {
    return '~$calories ккал';
  }

  @override
  String get runHeartRate => 'Пульс';

  @override
  String runHeartRateValue(int bpm) {
    return '$bpm уд/мин';
  }

  @override
  String get runNoData => '—';

  @override
  String distanceMeters(String value) {
    return '$value м';
  }

  @override
  String distanceKm(String value) {
    return '$value км';
  }

  @override
  String get loginTitle => 'Runterra';

  @override
  String get loginSubtitle => 'Беговое приложение для захвата территорий';

  @override
  String get loginButton => 'Войти через Google';

  @override
  String get loginLoading => 'Вход...';

  @override
  String loginError(String error) {
    return 'Ошибка входа: $error';
  }

  @override
  String get noData => 'Нет данных';

  @override
  String get activityDetailsTitle => 'Активность';

  @override
  String get cityDetailsTitle => 'Город';

  @override
  String get clubDetailsTitle => 'Клуб';

  @override
  String get clubJoin => 'Присоединиться';

  @override
  String get clubLeave => 'Выйти из клуба';

  @override
  String get clubJoinSuccess => 'Вы вступили в клуб';

  @override
  String get clubLeaveSuccess => 'Вы вышли из клуба';

  @override
  String clubJoinError(String message) {
    return 'Не удалось вступить: $message';
  }

  @override
  String clubLeaveError(String message) {
    return 'Не удалось выйти: $message';
  }

  @override
  String get clubYouAreMember => 'Вы в клубе';

  @override
  String get territoryDetailsTitle => 'Территория';

  @override
  String get detailType => 'Тип';

  @override
  String get detailStatus => 'Статус';

  @override
  String get detailDescription => 'Описание';

  @override
  String get detailCoordinates => 'Координаты';

  @override
  String detailLatLng(String lat, String lng) {
    return 'Широта: $lat\nДолгота: $lng';
  }

  @override
  String get detailCoordinatesCenter => 'Координаты центра';

  @override
  String get detailCity => 'Город';

  @override
  String get detailCapturedBy => 'Захвачена игроком';

  @override
  String get eventTerritoryLabel => 'Территория';

  @override
  String clubLabel(String id) {
    return 'Клуб: $id';
  }

  @override
  String trainerLabel(String id) {
    return 'Тренер: $id';
  }

  @override
  String get cityPickerTitle => 'Выбор города';

  @override
  String cityPickerLoadError(String error) {
    return 'Не удалось загрузить города:\n$error';
  }

  @override
  String get cityPickerEmpty => 'Список городов пуст';

  @override
  String get cityNotSelected => 'Не выбран';

  @override
  String get editProfileTitle => 'Редактирование профиля';

  @override
  String get editProfileName => 'Имя';

  @override
  String get editProfileFirstName => 'Имя';

  @override
  String get editProfileLastName => 'Фамилия';

  @override
  String get editProfileBirthDate => 'Дата рождения';

  @override
  String get editProfileCountry => 'Страна';

  @override
  String get editProfileGender => 'Пол';

  @override
  String get editProfileCity => 'Город';

  @override
  String get editProfilePhotoUrl => 'URL фото';

  @override
  String get editProfileSave => 'Сохранить';

  @override
  String get editProfileNameRequired => 'Укажите имя';

  @override
  String get editProfileEditAction => 'Редактировать';

  @override
  String get profilePersonalInfoTitle => 'Личные данные';

  @override
  String get profileFirstNameLabel => 'Имя';

  @override
  String get profileLastNameLabel => 'Фамилия';

  @override
  String get profileBirthDateLabel => 'Дата рождения';

  @override
  String get profileCountryLabel => 'Страна';

  @override
  String get profileGenderLabel => 'Пол';

  @override
  String get profileCityLabel => 'Город';

  @override
  String get profileNotSpecified => 'Не указано';

  @override
  String get genderMale => 'Мужской';

  @override
  String get genderFemale => 'Женский';

  @override
  String get genderOther => 'Другое';

  @override
  String get genderUnknown => 'Не указано';

  @override
  String get createClubTitle => 'Создать клуб';

  @override
  String get createClubNameHint => 'Название клуба';

  @override
  String get createClubDescriptionHint => 'Описание (необязательно)';

  @override
  String get createClubSave => 'Создать';

  @override
  String get createClubNameRequired => 'Укажите название клуба';

  @override
  String get createClubCityRequired => 'Сначала выберите город в профиле';

  @override
  String createClubError(String message) {
    return 'Не удалось создать клуб: $message';
  }

  @override
  String get runStuckSessionTitle => 'Пробежка в процессе';

  @override
  String get runStuckSessionMessage =>
      'У вас есть незавершённая пробежка. Хотите продолжить её или начать заново?';

  @override
  String get runStuckSessionResume => 'Продолжить';

  @override
  String get runStuckSessionCancel => 'Отменить и начать заново';
}
