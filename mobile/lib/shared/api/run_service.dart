import 'dart:async';
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';
import '../location/location_service.dart';
import '../models/run_model.dart';
import '../models/run_history_item.dart';
import '../models/run_stats.dart';
import '../models/run_session.dart';
import 'api_client.dart';
import 'users_service.dart' show ApiException;

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../di/service_locator.dart';
import '../models/workout.dart';

/// Сервис для работы с пробежками
///
/// Предоставляет методы для сценария: начать → трекинг → завершить → отправить.
/// Управляет GPS-трекингом и отправкой данных на backend.
class RunService {
  late LocationService _locationService;
  final bool _ownLocationService;
  final ApiClient _apiClient;
  final FlutterTts _tts = FlutterTts();

  RunSession? _currentSession;
  StreamSubscription<Position>? _positionSubscription;
  final List<Position> _gpsPoints = [];
  DateTime? _startTime;

  // Segment tracking
  DateTime? _currentSegmentStartedAt;
  double _currentSegmentStartDistance = 0.0;

  RunService({
    LocationService? locationService,
    ApiClient? apiClient,
  })  : _ownLocationService = locationService == null,
        _apiClient = apiClient ?? ApiClient.getInstance(baseUrl: ApiConfig.getBaseUrl()) {
    _locationService = locationService ?? LocationService();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("ru-RU");
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
  }

  /// Начать пробежку.
  Future<RunSession> startRun({String? activityId, String? scheduledItemId, String? scoringClubId}) async {
    // Auto-clear completed sessions (failed submissions, etc.)
    if (_currentSession != null &&
        _currentSession!.status == RunSessionStatus.completed) {
      clearCompletedSession();
    }

    // Still running session - this is the real error case
    if (_currentSession != null) {
      throw Exception('Run already started');
    }

    // Fetch workout if activityId is provided
    Workout? workout;
    if (activityId != null) {
      try {
        final event = await ServiceLocator.eventsService.getEventById(activityId);
        if (event.workoutId != null) {
          workout = await ServiceLocator.workoutsService.getWorkout(event.workoutId!);
        }
      } catch (e) {
        debugPrint('Error fetching workout for run: $e');
      }
    }

    _startTime = DateTime.now();
    _gpsPoints.clear();
    _currentSegmentStartedAt = _startTime;
    _currentSegmentStartDistance = 0.0;

    // Start GPS tracking (background so run continues when app is in background)
    await _locationService.startTracking(distanceFilter: 5, background: true);

    // Seed the route with the current GPS position
    GpsStatus initialGpsStatus = GpsStatus.searching;
    try {
      final initialPosition = await _locationService.getCurrentPosition();
      _gpsPoints.add(initialPosition);
      initialGpsStatus = GpsStatus.recording;
    } catch (_) {}

    // Listen to position updates
    _positionSubscription = _locationService.positionStream.listen(
      (position) {
        _gpsPoints.add(position);

        double newDistance = _currentSession?.distance ?? 0.0;
        if (_gpsPoints.length > 1) {
          final lastIndex = _gpsPoints.length - 1;
          final prev = _gpsPoints[lastIndex - 1];
          final curr = _gpsPoints[lastIndex];
          final increment = Geolocator.distanceBetween(
            prev.latitude,
            prev.longitude,
            curr.latitude,
            curr.longitude,
          );
          newDistance += increment;
        }

        if (_currentSession != null) {
          _currentSession = _currentSession!.copyWith(
            distance: newDistance,
            gpsStatus: GpsStatus.recording,
            gpsPoints: List.from(_gpsPoints),
          );
          _checkSegmentCompletion();
        }
      },
      onError: (error) {
        if (_currentSession != null) {
          _currentSession = _currentSession!.copyWith(gpsStatus: GpsStatus.error);
        }
      },
    );

    // Create session
    _currentSession = RunSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      activityId: activityId,
      scheduledItemId: scheduledItemId,
      scoringClubId: scoringClubId,
      startedAt: _startTime!,
      status: RunSessionStatus.running,
      gpsStatus: initialGpsStatus,
      gpsPoints: List.from(_gpsPoints),
      lastResumedAt: _startTime!,
      workout: workout,
    );

    return _currentSession!;
  }

  void _checkSegmentCompletion() {
    final session = _currentSession;
    if (session == null || session.workout == null || session.workout!.blocks == null) return;
    if (session.currentBlockIndex >= session.workout!.blocks!.length) return;

    final block = session.workout!.blocks![session.currentBlockIndex];
    if (session.currentSegmentIndex >= block.segments.length) return;

    final segment = block.segments[session.currentSegmentIndex];
    bool completed = false;

    if (segment.durationType == DurationType.time) {
      final elapsed = DateTime.now().difference(_currentSegmentStartedAt!);
      if (elapsed.inSeconds >= segment.durationValue) {
        completed = true;
      }
    } else if (segment.durationType == DurationType.distance) {
      final distanceInSegment = session.distance - _currentSegmentStartDistance;
      if (distanceInSegment >= segment.durationValue) {
        completed = true;
      }
    }

    if (completed) {
      nextSegment();
    }
  }

  void nextSegment() {
    final session = _currentSession;
    if (session == null || session.workout == null || session.workout!.blocks == null) return;

    int nextSegmentIdx = session.currentSegmentIndex + 1;
    int nextBlockIdx = session.currentBlockIndex;

    final currentBlock = session.workout!.blocks![nextBlockIdx];

    if (nextSegmentIdx >= currentBlock.segments.length) {
      // End of block
      nextSegmentIdx = 0;
      nextBlockIdx++;
    }

    if (nextBlockIdx >= session.workout!.blocks!.length) {
      // Workout finished
      _tts.speak("Тренировка завершена. Отличная работа!");
      return;
    }

    _currentSegmentStartedAt = DateTime.now();
    _currentSegmentStartDistance = session.distance;

    _currentSession = session.copyWith(
      currentBlockIndex: nextBlockIdx,
      currentSegmentIndex: nextSegmentIdx,
    );
    
    final nextSeg = session.workout!.blocks![nextBlockIdx].segments[nextSegmentIdx];
    String text = "Следующий сегмент: ";
    switch (nextSeg.type) {
      case SegmentType.warmup: text += "Разминка. "; break;
      case SegmentType.run: text += "Бег. "; break;
      case SegmentType.rest: text += "Отдых. "; break;
      case SegmentType.cooldown: text += "Заминка. "; break;
    }
    
    if (nextSeg.targetZone != null) {
      text += "Цель: ${nextSeg.targetZone}. ";
    } else if (nextSeg.targetValue != null) {
      text += "Цель: ${nextSeg.targetValue}. ";
    }
    
    _tts.speak(text);
  }

  /// Pause the current run: stop GPS, freeze accumulated duration.
  void pauseRun() {
    if (_currentSession == null ||
        _currentSession!.status != RunSessionStatus.running) {
      throw Exception('No running session to pause');
    }

    _locationService.stopTracking();
    _positionSubscription?.cancel();
    _positionSubscription = null;

    final now = DateTime.now();
    final lastResumed = _currentSession!.lastResumedAt ?? _currentSession!.startedAt;
    final activeSinceResume = now.difference(lastResumed);
    final totalAccumulated = _currentSession!.accumulatedDuration + activeSinceResume;

    _currentSession = _currentSession!.copyWith(
      status: RunSessionStatus.paused,
      duration: totalAccumulated,
      accumulatedDuration: totalAccumulated,
      lastResumedAt: null,
    );
  }

  /// Resume a paused run: restart GPS tracking.
  Future<void> resumeRun() async {
    if (_currentSession == null ||
        _currentSession!.status != RunSessionStatus.paused) {
      throw Exception('No paused session to resume');
    }

    await _locationService.startTracking(distanceFilter: 5, background: true);

    _positionSubscription = _locationService.positionStream.listen(
      (position) {
        _gpsPoints.add(position);

        double newDistance = _currentSession?.distance ?? 0.0;
        if (_gpsPoints.length > 1) {
          final lastIndex = _gpsPoints.length - 1;
          final prev = _gpsPoints[lastIndex - 1];
          final curr = _gpsPoints[lastIndex];
          final increment = Geolocator.distanceBetween(
            prev.latitude,
            prev.longitude,
            curr.latitude,
            curr.longitude,
          );
          newDistance += increment;
        }

        if (_currentSession != null) {
          _currentSession = _currentSession!.copyWith(
            distance: newDistance,
            gpsStatus: GpsStatus.recording,
            gpsPoints: List.from(_gpsPoints),
          );
          _checkSegmentCompletion();
        }
      },
      onError: (error) {
        if (_currentSession != null) {
          _currentSession = _currentSession!.copyWith(gpsStatus: GpsStatus.error);
        }
      },
    );

    final now = DateTime.now();
    _currentSession = _currentSession!.copyWith(
      status: RunSessionStatus.running,
      gpsStatus: GpsStatus.recording,
      lastResumedAt: now,
    );
  }

  /// Обновляет статус GPS в текущей сессии
  void updateGpsStatus(GpsStatus status) {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(gpsStatus: status);
    }
  }

  /// Обновляет длительность и расстояние в текущей сессии
  void updateSessionMetrics({
    Duration? duration,
    double? distance,
  }) {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        duration: duration,
        distance: distance,
      );
      _checkSegmentCompletion();
    }
  }

  /// Update heart rate from watch sensor.
  void updateHeartRate(int bpm) {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(heartRate: bpm);
    }
  }

  /// Получить текущую сессию
  RunSession? get currentSession => _currentSession;

  /// Clear a completed session without submitting.
  void clearCompletedSession() {
    if (_currentSession == null) return;
    if (_currentSession!.status == RunSessionStatus.running) {
      return;
    }
    _currentSession = null;
    _gpsPoints.clear();
    _startTime = null;
  }

  /// Завершить трекинг.
  Future<RunSession> stopRun() async {
    if (_currentSession == null) {
      throw Exception('No active run session');
    }

    // Stop GPS tracking
    _locationService.stopTracking();
    _positionSubscription?.cancel();
    _positionSubscription = null;

    // Calculate final active duration
    final Duration finalDuration;
    if (_currentSession!.status == RunSessionStatus.paused) {
      finalDuration = _currentSession!.accumulatedDuration;
    } else {
      final now = DateTime.now();
      final lastResumed = _currentSession!.lastResumedAt ?? _currentSession!.startedAt;
      finalDuration = _currentSession!.accumulatedDuration + now.difference(lastResumed);
    }

    // Update session with final data
    _currentSession = _currentSession!.copyWith(
      status: RunSessionStatus.completed,
      duration: finalDuration,
      accumulatedDuration: finalDuration,
    );

    return _currentSession!;
  }

  /// Отправить данные пробежки на backend.
  Future<void> submitRun({String? scoringClubId, int? rpe, String? notes}) async {
    if (_currentSession == null) {
      throw Exception('No run session to submit');
    }

    if (_currentSession!.status != RunSessionStatus.completed) {
      throw Exception('Run session is not completed');
    }

    final session = _currentSession!;
    final endTime = session.startedAt.add(session.duration);

    final requestBody = <String, dynamic>{
      'startedAt': session.startedAt.toUtc().toIso8601String(),
      'endedAt': endTime.toUtc().toIso8601String(),
      'duration': session.duration.inSeconds,
      'distance': session.distance,
      'gpsPoints': session.gpsPoints.map((p) => <String, dynamic>{
          'latitude': p.latitude,
          'longitude': p.longitude,
          'timestamp': p.timestamp.toUtc().toIso8601String(),
        }).toList(),
    };
    if (session.activityId != null) {
      requestBody['activityId'] = session.activityId;
    }
    if (session.scheduledItemId != null) {
      requestBody['scheduledItemId'] = session.scheduledItemId;
    }
    final finalScoringClubId = scoringClubId ?? session.scoringClubId;
    if (finalScoringClubId != null) {
      requestBody['scoringClubId'] = finalScoringClubId;
    }
    if (rpe != null) {
      requestBody['rpe'] = rpe;
    }
    if (notes != null && notes.trim().isNotEmpty) {
      requestBody['notes'] = notes.trim();
    }

    final response = await _apiClient.post(
      '/api/runs',
      body: requestBody,
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      String errorMessage = 'Failed to submit run (${response.statusCode})';
      String errorCode = 'submit_error';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>?;
        if (decoded != null) {
          errorCode = (decoded['code'] as String?) ?? errorCode;
          errorMessage = (decoded['message'] as String?) ?? errorMessage;
        }
      } on FormatException {
        // ignore format exception
      }
      throw ApiException(errorCode, errorMessage);
    }

    _currentSession = null;
    _gpsPoints.clear();
    _startTime = null;
  }

  /// Отменить текущую пробежку без отправки на backend
  void cancelRun() {
    _locationService.stopTracking();
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _currentSession = null;
    _gpsPoints.clear();
    _startTime = null;
    if (_ownLocationService) {
      _locationService.dispose();
      _locationService = LocationService();
    }
  }

  /// Fetch paginated run history.
  Future<List<RunHistoryItem>> getRunHistory({int limit = 20, int offset = 0}) async {
    final response = await _apiClient.get('/api/runs?limit=$limit&offset=$offset');
    if (response.statusCode != 200) {
      throw ApiException('fetch_error', 'Failed to load run history');
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => RunHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Fetch user statistics.
  Future<RunStats> getRunStats() async {
    final response = await _apiClient.get('/api/runs/stats');
    if (response.statusCode != 200) {
      throw ApiException('fetch_error', 'Failed to load run stats');
    }
    return RunStats.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Fetch a single run.
  Future<RunDetailModel> getRunDetail(String runId) async {
    final response = await _apiClient.get('/api/runs/$runId');
    if (response.statusCode != 200) {
      throw ApiException('fetch_error', 'Failed to load run detail');
    }
    return RunDetailModel.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  void dispose() {
    if (_ownLocationService) {
      _locationService.stopTracking();
      _locationService.dispose();
    }
  }

  Stream<Position> get gpsPositionStream => _locationService.positionStream;
}
