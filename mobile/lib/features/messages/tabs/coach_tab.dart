import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Tab "Тренер" — сообщения тренера.
///
/// Stub: empty state. Coach messages are not in MVP.
class CoachTab extends StatelessWidget {
  const CoachTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          AppLocalizations.of(context)!.coachMessagesEmpty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
