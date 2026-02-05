import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../models/profile_model.dart';

/// Секция личных данных профиля (имя, дата рождения, страна, пол, город).
class ProfilePersonalInfoSection extends StatelessWidget {
  final ProfileUserData user;

  const ProfilePersonalInfoSection({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('d.MM.yyyy');
    final birthDate = user.birthDate != null ? dateFormat.format(user.birthDate!) : null;
    final city = user.cityName ?? user.cityId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.profilePersonalInfoTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildRow(context, l10n.profileFirstNameLabel, user.firstName ?? user.name),
            _buildRow(context, l10n.profileLastNameLabel, user.lastName),
            _buildRow(context, l10n.profileBirthDateLabel, birthDate),
            _buildRow(context, l10n.profileCountryLabel, user.country),
            _buildRow(context, l10n.profileGenderLabel, _getGenderText(context, user.gender)),
            _buildRow(context, l10n.profileCityLabel, city),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final displayValue = (value == null || value.isEmpty) ? l10n.profileNotSpecified : value;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[700],
                  ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              displayValue,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String? _getGenderText(BuildContext context, String? gender) {
    final l10n = AppLocalizations.of(context)!;
    switch (gender) {
      case 'male':
        return l10n.genderMale;
      case 'female':
        return l10n.genderFemale;
      case 'other':
        return l10n.genderOther;
      case 'unknown':
        return l10n.genderUnknown;
      default:
        return null;
    }
  }
}
