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
  String get navRun => 'Тренировка';

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
  String get personalChatsEmpty => 'Личные чаты — в разработке';

  @override
  String get coachMessagesEmpty => 'Сообщения тренера — в разработке';

  @override
  String get noClubChats =>
      'Нет чатов клубов\n\nВы пока не состоите ни в одном клубе';

  @override
  String get messagesBackToClubs => 'К списку клубов';

  @override
  String get messagesSelectClub => 'Выберите клуб для переписки';

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
  String get roleTrainer => 'Тренер';

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
  String get profileMyClubsButton => 'Клубы';

  @override
  String get profileMyClubsTitle => 'Мои клубы';

  @override
  String get profileMyClubsEmpty => 'Вы пока не состоите ни в одном клубе';

  @override
  String profileMyClubsLoadError(String error) {
    return 'Не удалось загрузить клубы: $error';
  }

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
  String get deleteAccountTitle => 'Удалить аккаунт';

  @override
  String get deleteAccountConfirm =>
      'Удалить аккаунт безвозвратно? Это действие нельзя отменить. Все ваши данные будут удалены.';

  @override
  String get deleteAccountConfirmButton => 'Удалить';

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
  String get filterParticipantOnly => 'Участвую';

  @override
  String get filterAll => 'Все';

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
  String get eventSwipeToRunTitle => 'Свайп — начать пробежку';

  @override
  String get eventSwipeToRunHint =>
      'Свайпните влево, чтобы отметиться и начать пробежку';

  @override
  String get eventSwipeToRunSuccess => 'Отметка принята! Пробежка начата.';

  @override
  String eventSwipeToRunError(String error) {
    return 'Ошибка: $error';
  }

  @override
  String get eventSwipeToRunAlreadyCheckedIn => 'Вы уже отметились';

  @override
  String get eventSwipeToRunTooEarly =>
      'Check-in открывается за 30 минут до события';

  @override
  String get eventSwipeToRunTooLate => 'Окно check-in закрыто';

  @override
  String get eventSwipeToRunTooFar =>
      'Подойдите ближе к точке старта (в пределах 500 м)';

  @override
  String get eventSwipeToRunLocationError =>
      'Не удалось определить местоположение';

  @override
  String get eventSwipeToRunCheckingLocation => 'Проверяем местоположение...';

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
  String territoryLeading(String km) {
    return 'Оспаривается (Вы лидируете: $km км)';
  }

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
  String get runStart => 'Старт';

  @override
  String get runPause => 'Пауза';

  @override
  String get runResume => 'Продолжить';

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
  String get runFindMe => 'Найти себя';

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
  String get clubRequestJoin => 'Подать заявку';

  @override
  String get clubRequestPending => 'Заявка отправлена';

  @override
  String get clubRequestApprove => 'Одобрено';

  @override
  String get clubRequestReject => 'Отклонено';

  @override
  String get clubMembershipRequests => 'Заявки на вступление';

  @override
  String get clubJoin => 'Присоединиться';

  @override
  String get clubJoinSuccess => 'Вы вступили в клуб';

  @override
  String clubJoinError(String message) {
    return 'Не удалось вступить: $message';
  }

  @override
  String get clubYouAreMember => 'Вы в клубе';

  @override
  String get clubLeave => 'Выйти из клуба';

  @override
  String get clubLeaveSuccess => 'Вы вышли из клуба';

  @override
  String clubLeaveError(String message) {
    return 'Не удалось выйти: $message';
  }

  @override
  String get clubChatButton => 'Чат клуба';

  @override
  String get clubMembersLabel => 'Участники';

  @override
  String get clubTerritoriesLabel => 'Территории';

  @override
  String get clubCityRankLabel => 'Рейтинг в городе';

  @override
  String get clubMetricPlaceholder => '—';

  @override
  String clubLeaderboardSubtitle(int members, int territories) {
    return 'Участников: $members, Территорий: $territories';
  }

  @override
  String clubLeaderboardPoints(int points) {
    return '$points очков';
  }

  @override
  String get clubActivationHint =>
      'Наберите ещё 1 участника, чтобы активировать клуб и участвовать в захвате территорий.';

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

  @override
  String get editClubTitle => 'Редактировать клуб';

  @override
  String get editClubName => 'Название клуба';

  @override
  String get editClubDescription => 'Описание';

  @override
  String get editClubNameHelperText => 'символов';

  @override
  String get editClubDescriptionHelperText => 'Необязательно, до 500 символов';

  @override
  String get editClubNameError => 'Название должно быть от 3 до 50 символов';

  @override
  String get editClubSave => 'Сохранить';

  @override
  String get editClubError => 'Не удалось обновить клуб';

  @override
  String get clubEditButton => 'Редактировать клуб';

  @override
  String get clubManagementTitle => 'Управление тренера';

  @override
  String get clubManageSchedule => 'Расписание (шаблоны)';

  @override
  String get clubManageRoster => 'Состав и планы';

  @override
  String get clubMembersTitle => 'Участники';

  @override
  String get clubMembersEmpty => 'Пока нет участников';

  @override
  String get clubMembersLoadError => 'Не удалось загрузить участников';

  @override
  String get clubMemberRoleChange => 'Изменить роль';

  @override
  String get clubMemberRoleChangeSuccess => 'Роль обновлена';

  @override
  String clubMemberRoleChangeError(String message) {
    return 'Не удалось обновить роль: $message';
  }

  @override
  String get rosterTitle => 'Состав клуба';

  @override
  String get scheduleTitle => 'Шаблон расписания';

  @override
  String get planTypeClub => 'Клубный';

  @override
  String get planTypePersonal => 'Личный';

  @override
  String get eventOpenOnMap => 'Открыть на карте';

  @override
  String get eventCreateSelectCity => 'Выберите город';

  @override
  String get clubFounder => 'Основатель';

  @override
  String get clubsListTitle => 'Клубы города';

  @override
  String get clubsListEmpty => 'Клубов пока нет';

  @override
  String get clubsListAllClubs => 'Все клубы города';

  @override
  String get clubEventsTitle => 'Ближайшие события';

  @override
  String get clubEventsEmpty => 'Нет предстоящих событий';

  @override
  String get clubEventsError => 'Не удалось загрузить';

  @override
  String get clubEventsViewAll => 'Все события клуба';

  @override
  String get eventCreatePickLocation => 'Выбрать на карте';

  @override
  String get eventCreateLocationSelected => 'Точка выбрана';

  @override
  String get eventCreateLocationRequired => 'Выберите точку старта';

  @override
  String get eventCreateLocationOutOfCity =>
      'Выбранная точка находится за пределами города. Выберите место ближе к городу.';

  @override
  String get locationPickerTitle => 'Выбор точки';

  @override
  String get locationPickerConfirm => 'Подтвердить';

  @override
  String get locationPickerSearchHint => 'Поиск адреса...';

  @override
  String get leaderCannotLeave => 'Сначала передайте лидерство';

  @override
  String get transferLeadership => 'Передать лидерство';

  @override
  String get disbandClub => 'Распустить клуб';

  @override
  String get disbandConfirm => 'Вы уверены? Это действие нельзя отменить.';

  @override
  String get selectNewLeader => 'Выберите нового лидера';

  @override
  String get transferSuccess => 'Лидерство передано';

  @override
  String get disbandSuccess => 'Клуб распущен';

  @override
  String get runHistoryTitle => 'Журнал тренировок';

  @override
  String get runHistoryEmpty => 'Пробежек пока нет';

  @override
  String get runHistoryEmptyHint =>
      'Начните первую пробежку, и она появится здесь';

  @override
  String get runHistoryToday => 'Сегодня';

  @override
  String get runHistoryYesterday => 'Вчера';

  @override
  String get runStatsTitle => 'Статистика';

  @override
  String get runStatsTotalRuns => 'Пробежки';

  @override
  String get runStatsTotalDistance => 'Общая дистанция';

  @override
  String get runStatsAvgPace => 'Ср. темп';

  @override
  String get runDetailTitle => 'Детали пробежки';

  @override
  String get runDetailLoadError => 'Не удалось загрузить данные пробежки';

  @override
  String get runGpsPoints => 'GPS точки';

  @override
  String get tierGreen => 'Зелёная зона';

  @override
  String get tierBlue => 'Синяя зона';

  @override
  String get tierRed => 'Красная зона';

  @override
  String get tierBlack => 'Чёрная зона';

  @override
  String get tierLabelNovice => 'Новички';

  @override
  String get tierLabelAdvanced => 'Продвинутые';

  @override
  String get tierLabelSpecialist => 'Специалисты';

  @override
  String get tierLabelElite => 'Элита';

  @override
  String zoneCaptured(String clubName) {
    return 'Захвачена: $clubName';
  }

  @override
  String get zoneOpenSeason => 'Открытый сезон';

  @override
  String get zoneContested => 'Оспаривается';

  @override
  String paceBonus(String pace, String multiplier) {
    return 'Темп < $pace → x$multiplier';
  }

  @override
  String zoneBountyLabel(String bounty) {
    return 'x$bounty очков';
  }

  @override
  String seasonResetIn(int days) {
    return 'Сброс через $daysд';
  }

  @override
  String runForZone(String bounty) {
    return 'БЕЖАТЬ ЗА ЗОНУ (+${bounty}x)';
  }

  @override
  String leaderboardTitle(String zoneName) {
    return '$zoneName — Лидерборд';
  }

  @override
  String get yourClub => 'Ваш клуб';

  @override
  String gapToLeader(String km) {
    return '$km км до лидера';
  }

  @override
  String get joinClubCta => 'Вступи в клуб, чтобы соревноваться';

  @override
  String get findClub => 'НАЙТИ КЛУБ';

  @override
  String get seasonStarted =>
      'Новый сезон начался, данных пока нет. Стань первым!';

  @override
  String get loadError => 'Не удалось загрузить данные';

  @override
  String leaderKm(String km) {
    return '$km км';
  }

  @override
  String clubLeading(String km) {
    return 'Ваш клуб лидирует! +$km км отрыв';
  }

  @override
  String clubPosition(String km, String position) {
    return 'Ваш клуб: $km км ($position-е место)';
  }

  @override
  String get trainerProfile => 'Профиль тренера';

  @override
  String get trainerEditProfile => 'Редактировать профиль';

  @override
  String get trainerBio => 'О себе';

  @override
  String get trainerBioHint => 'Опишите ваш подход к тренировкам...';

  @override
  String get trainerSpecialization => 'Специализация';

  @override
  String get trainerExperience => 'Стаж (лет)';

  @override
  String get trainerCertificates => 'Сертификаты';

  @override
  String get trainerCertificateName => 'Название сертификата';

  @override
  String get trainerCertificateDate => 'Дата';

  @override
  String get trainerCertificateOrg => 'Организация';

  @override
  String get trainerAddCertificate => 'Добавить сертификат';

  @override
  String get trainerProfileSaved => 'Профиль сохранён';

  @override
  String get trainerProfileNotAvailable => 'Профиль тренера недоступен';

  @override
  String get trainerRoleRequired =>
      'Для редактирования профиля нужна роль тренера в клубе';

  @override
  String get trainerSpecializationRequired =>
      'Выберите хотя бы одну специализацию';

  @override
  String get trainerExperienceRange => 'Значение должно быть от 0 до 50';

  @override
  String get specMarathon => 'Марафон';

  @override
  String get specSprint => 'Спринт';

  @override
  String get specTrail => 'Трейл';

  @override
  String get specRecovery => 'Восстановление';

  @override
  String get specGeneral => 'Общая подготовка';

  @override
  String get workouts => 'Тренировки';

  @override
  String get myWorkouts => 'Мои тренировки';

  @override
  String get createWorkout => 'Создать тренировку';

  @override
  String get editWorkout => 'Редактировать тренировку';

  @override
  String get workoutName => 'Название';

  @override
  String get workoutDescription => 'Описание';

  @override
  String get workoutDescriptionHint => 'Опишите план тренировки...';

  @override
  String get workoutType => 'Тип';

  @override
  String get workoutDifficulty => 'Сложность';

  @override
  String get workoutTargetMetric => 'Целевая метрика';

  @override
  String get workoutClub => 'Клуб (опционально)';

  @override
  String get workoutPersonal => 'Личная';

  @override
  String get workoutSaved => 'Тренировка сохранена';

  @override
  String get workoutDeleted => 'Тренировка удалена';

  @override
  String get workoutDeleteConfirm => 'Удалить тренировку?';

  @override
  String get workoutDeleteAction => 'Удалить';

  @override
  String get workoutInUse => 'Нельзя удалить: привязана к будущим событиям';

  @override
  String get workoutEmpty => 'Тренировок пока нет';

  @override
  String get typeRecovery => 'Восстановительная';

  @override
  String get typeTempo => 'Темповая';

  @override
  String get typeInterval => 'Интервальная';

  @override
  String get typeFartlek => 'Фартлек';

  @override
  String get typeLongRun => 'Длительная';

  @override
  String get diffBeginner => 'Начинающий';

  @override
  String get diffIntermediate => 'Средний';

  @override
  String get diffAdvanced => 'Продвинутый';

  @override
  String get diffPro => 'Профи';

  @override
  String get metricDistance => 'Дистанция';

  @override
  String get metricTime => 'Время';

  @override
  String get metricPace => 'Темп';

  @override
  String get workoutTargetValueDistance => 'Дистанция (метры)';

  @override
  String get workoutTargetValueTime => 'Длительность (минуты)';

  @override
  String get workoutTargetValuePace => 'Темп (сек/км)';

  @override
  String get workoutTargetZone => 'Пульсовая зона';

  @override
  String get zoneNone => 'Не указана';

  @override
  String get zoneZ1 => 'Z1 Восстановление';

  @override
  String get zoneZ2 => 'Z2 Легкая';

  @override
  String get zoneZ3 => 'Z3 Аэробная';

  @override
  String get zoneZ4 => 'Z4 Порог';

  @override
  String get zoneZ5 => 'Z5 Максимум';

  @override
  String get eventWorkout => 'Тренировка';

  @override
  String get eventSelectWorkout => 'Выбрать тренировку';

  @override
  String get eventTrainer => 'Тренер';

  @override
  String get eventSelectTrainer => 'Выбрать тренера';

  @override
  String get eventNoWorkout => 'Тренировка не назначена';

  @override
  String get eventEditTitle => 'Редактирование события';

  @override
  String get eventEditSave => 'Сохранить изменения';

  @override
  String get eventEditSuccess => 'Событие обновлено';

  @override
  String eventEditError(String error) {
    return 'Ошибка обновления: $error';
  }

  @override
  String get captureButton => 'Захватить';

  @override
  String get captureSuccess => 'Вклад в захват территории отправлен!';

  @override
  String captureError(String message) {
    return 'Не удалось захватить: $message';
  }

  @override
  String get eventCreatePrivate => 'Приватное событие';

  @override
  String get eventCreatePrivateDescription => 'Видно только приглашенным';

  @override
  String get runSelectClubTitle => 'Выберите клуб для зачета';

  @override
  String get runNoClubs => 'Нет активных клубов';

  @override
  String get runSkipScoring => 'Пропустить (не сохранять)';

  @override
  String get runClubRequired => 'Выберите клуб, чтобы начислить баллы.';

  @override
  String get trainerSection => 'Тренер';

  @override
  String get trainerAcceptsClients => 'Принимаю частных клиентов';

  @override
  String get trainerAcceptsClientsHint =>
      'Ваш профиль появится в каталоге тренеров';

  @override
  String get trainerSetupProfile => 'Настроить тренерский профиль';

  @override
  String get trainerPrivateBadge => 'Приватный тренер';

  @override
  String get findTrainers => 'Найти тренера';

  @override
  String get trainersList => 'Тренеры';

  @override
  String get trainersEmpty => 'Тренеры не найдены';

  @override
  String get trainersLoadError => 'Не удалось загрузить тренеров';

  @override
  String get watchNotPaired => 'Часы не подключены';

  @override
  String mapActiveClub(String name) {
    return 'Клуб: $name';
  }

  @override
  String get mapNoActiveClub => 'Нет клуба';

  @override
  String mapCurrentTerritory(String name) {
    return 'Территория: $name';
  }

  @override
  String get mapNoTerritory => 'Нет территории';

  @override
  String get selectClub => 'Выбрать клуб';

  @override
  String get messagesScrollToBottom => 'В конец';

  @override
  String get trainerGroupsTab => 'Группы';

  @override
  String get trainerPersonalTab => 'Личные';

  @override
  String get trainerBadge => 'Тренер';

  @override
  String get trainerNoPrivateClients => 'Нет личных клиентов';

  @override
  String get trainerNoPersonalTrainer => 'Нет персонального тренера';

  @override
  String get memberActionWriteAsTrainer => 'Написать как тренер';

  @override
  String get memberActionChangeRole => 'Изменить роль';

  @override
  String get memberActionPrivateMessages => 'Личные сообщения';

  @override
  String get memberActionPrivateMessagesHint => 'В разработке';

  @override
  String get directChatWaitForTrainer => 'Тренер напишет вам первым';

  @override
  String get trainerGroupsTitle => 'Группы';

  @override
  String get trainerCreateGroup => 'Создать группу';

  @override
  String get trainerGroupName => 'Название группы';

  @override
  String get trainerGroupNameHint => 'Введите название группы';

  @override
  String get trainerSelectMembers => 'Выберите участников';

  @override
  String get trainerNoGroups => 'Групп пока нет';

  @override
  String get trainerGroupCreated => 'Группа успешно создана';

  @override
  String trainerCreateGroupError(String error) {
    return 'Не удалось создать группу: $error';
  }
}
