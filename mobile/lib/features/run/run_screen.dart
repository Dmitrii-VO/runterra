import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/di/service_locator.dart';
import '../../shared/models/run_session.dart';
import 'run_tracking_screen.dart';
import 'run_history_screen.dart';

/// Run tab router.
///
/// Shows RunTrackingScreen when there is an active/completed session,
/// otherwise shows RunHistoryScreen (training journal).
class RunScreen extends StatefulWidget {
  final String? activityId;
  final String? scheduledItemId;
  final String? assignmentId;

  const RunScreen({super.key, this.activityId, this.scheduledItemId, this.assignmentId});

  @override
  State<RunScreen> createState() => _RunScreenState();
}

class _RunScreenState extends State<RunScreen> {
  bool _forceTracking = false;
  String? _selectedScheduledItemId;

  bool get _hasActiveSession {
    final session = ServiceLocator.runService.currentSession;
    return session != null &&
        (session.status == RunSessionStatus.running ||
         session.status == RunSessionStatus.completed);
  }

  void _openTracking([String? scheduledItemId]) {
    setState(() {
      _selectedScheduledItemId = scheduledItemId;
      _forceTracking = true;
    });
  }

  void _onRunCompleted() {
    setState(() {
      _selectedScheduledItemId = null;
      _forceTracking = false;
    });
    if (widget.assignmentId != null) {
      context.go('/run');
    }
  }

  @override
  Widget build(BuildContext context) {
    // If activityId is provided or there's an active session or user tapped "Start run" — show tracking
    if (widget.activityId != null || widget.scheduledItemId != null || widget.assignmentId != null || _hasActiveSession || _forceTracking) {
      return RunTrackingScreen(
        activityId: widget.activityId,
        scheduledItemId: widget.scheduledItemId ?? _selectedScheduledItemId,
        assignmentId: widget.assignmentId,
        onRunCompleted: _onRunCompleted,
      );
    }

    return RunHistoryScreen(onStartRun: _openTracking);
  }
}
