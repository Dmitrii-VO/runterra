import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Tab "Личные" — личные переписки.
///
/// Stub: empty state. Personal chats are not in MVP.
class PersonalChatsTab extends StatelessWidget {
  const PersonalChatsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          AppLocalizations.of(context)!.personalChatsEmpty,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
