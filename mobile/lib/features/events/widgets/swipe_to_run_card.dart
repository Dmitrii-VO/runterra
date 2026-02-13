import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/di/service_locator.dart';
import '../../../shared/models/event_details_model.dart';
import '../../../shared/api/users_service.dart' show ApiException;

/// Swipe-to-run card for event check-in (Z8 decisions 2026-02-13).
///
/// Shown to participants when in check-in window (30 min before — 1 h after).
/// Swipe triggers check-in + run start. When conditions not met, shows disabled with reason.
class SwipeToRunCard extends StatefulWidget {
  final EventDetailsModel event;
  final VoidCallback onRefresh;

  const SwipeToRunCard({
    super.key,
    required this.event,
    required this.onRefresh,
  });

  @override
  State<SwipeToRunCard> createState() => _SwipeToRunCardState();
}

class _SwipeToRunCardState extends State<SwipeToRunCard> {
  static const double _geozoneRadiusMeters = 500;
  static const int _windowMinutesBefore = 30;
  static const int _windowMinutesAfter = 60;

  bool? _inGeozone;
  bool _isLoading = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _checkGeozone();
  }

  bool _inTimeWindow() {
    final now = DateTime.now();
    final start = widget.event.startDateTime;
    final windowStart = start.subtract(const Duration(minutes: _windowMinutesBefore));
    final windowEnd = start.add(const Duration(minutes: _windowMinutesAfter));
    return !now.isBefore(windowStart) && !now.isAfter(windowEnd);
  }

  Future<void> _checkGeozone() async {
    setState(() {
      _inGeozone = null;
      _loadError = null;
    });
    try {
      final loc = ServiceLocator.locationService;
      final pos = await loc.getCurrentPosition();
      final dist = Geolocator.distanceBetween(
        widget.event.startLocation.latitude,
        widget.event.startLocation.longitude,
        pos.latitude,
        pos.longitude,
      );
      if (!mounted) return;
      setState(() => _inGeozone = dist <= _geozoneRadiusMeters);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _inGeozone = false;
        _loadError = e.toString();
      });
    }
  }

  bool get _canSwipe {
    if (widget.event.participantStatus == 'checked_in') return false;
    return _inTimeWindow() && (_inGeozone == true);
  }

  String? _disabledReason(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (widget.event.participantStatus == 'checked_in') {
      return l10n.eventSwipeToRunAlreadyCheckedIn;
    }
    if (!_inTimeWindow()) {
      final now = DateTime.now();
      final start = widget.event.startDateTime;
      if (now.isBefore(start.subtract(const Duration(minutes: _windowMinutesBefore)))) {
        return l10n.eventSwipeToRunTooEarly;
      }
      return l10n.eventSwipeToRunTooLate;
    }
    if (_loadError != null) {
      return l10n.eventSwipeToRunLocationError;
    }
    if (_inGeozone == false) {
      return l10n.eventSwipeToRunTooFar;
    }
    if (_inGeozone == null) {
      return l10n.eventSwipeToRunCheckingLocation;
    }
    return null;
  }

  Future<void> _onSwipe() async {
    if (_isLoading || !_canSwipe) return;
    setState(() => _isLoading = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      final loc = ServiceLocator.locationService;
      final pos = await loc.getCurrentPosition();
      await ServiceLocator.eventsService.checkInEvent(
        widget.event.id,
        longitude: pos.longitude,
        latitude: pos.latitude,
      );
      if (!mounted) return;
      await ServiceLocator.runService.startRun(activityId: widget.event.id);
      if (!mounted) return;
      widget.onRefresh();
      context.go('/run');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventSwipeToRunSuccess)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventCheckInError(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.eventSwipeToRunError(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disabledReason = _disabledReason(context);
    final canSwipe = _canSwipe;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: canSwipe
          ? Dismissible(
               key: ValueKey('swipe-run-${widget.event.id}'),
               direction:
                   _isLoading ? DismissDirection.none : DismissDirection.endToStart,
               confirmDismiss: (_) async {
                 await _onSwipe();
                 return false; // Do not remove from the tree (Dismissible expects removal).
               },
               background: Container(
                 color: Colors.green,
                 alignment: Alignment.centerRight,
                 padding: const EdgeInsets.only(right: 24),
                 child: const Icon(Icons.directions_run, color: Colors.white, size: 32),
               ),
               child: ListTile(
                 leading: const Icon(Icons.directions_run, color: Colors.green),
                 title: Text(l10n.eventSwipeToRunTitle),
                 subtitle: Text(l10n.eventSwipeToRunHint),
                 trailing: _isLoading
                     ? const SizedBox(
                         width: 24,
                         height: 24,
                         child: CircularProgressIndicator(strokeWidth: 2),
                       )
                     : const Icon(Icons.chevron_right),
                 onTap: _isLoading ? null : () => _onSwipe(),
               ),
             )
          : Opacity(
               opacity: 0.7,
               child: ListTile(
                leading: Icon(Icons.directions_run, color: Colors.grey[600]),
                title: Text(l10n.eventSwipeToRunTitle),
                subtitle: Text(disabledReason ?? l10n.eventSwipeToRunHint),
                trailing: Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                onTap: _inGeozone == null ? null : _checkGeozone,
              ),
            ),
    );
  }
}
