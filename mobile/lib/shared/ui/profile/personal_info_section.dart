import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../l10n/app_localizations.dart';
import '../../models/profile_model.dart';

/// Personal info section (name, birth date, country, gender, city).
/// Collapsed by default — tap title to expand.
class ProfilePersonalInfoSection extends StatefulWidget {
  final ProfileUserData user;

  const ProfilePersonalInfoSection({
    super.key,
    required this.user,
  });

  @override
  State<ProfilePersonalInfoSection> createState() =>
      _ProfilePersonalInfoSectionState();
}

class _ProfilePersonalInfoSectionState
    extends State<ProfilePersonalInfoSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('d.MM.yyyy');
    final birthDate =
        widget.user.birthDate != null ? dateFormat.format(widget.user.birthDate!) : null;
    final city = widget.user.cityName ?? widget.user.cityId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.profilePersonalInfoTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRow(context, l10n.profileFirstNameLabel,
                      widget.user.firstName ?? widget.user.name),
                  _buildRow(
                      context, l10n.profileLastNameLabel, widget.user.lastName),
                  _buildRow(
                      context, l10n.profileBirthDateLabel, birthDate),
                  _buildRow(
                      context, l10n.profileCountryLabel, widget.user.country),
                  _buildRow(context, l10n.profileGenderLabel,
                      _getGenderText(context, widget.user.gender)),
                  _buildRow(context, l10n.profileCityLabel, city),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, String label, String? value) {
    final l10n = AppLocalizations.of(context)!;
    final displayValue =
        (value == null || value.isEmpty) ? l10n.profileNotSpecified : value;
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
