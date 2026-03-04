import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../l10n/app_localizations.dart';

/// Dialog shown when a newer app version is available.
///
/// "Update" button tries to open the Gmail app; falls back to web Gmail.
/// "Close" dismisses without action.
class UpdateDialog extends StatelessWidget {
  final String currentVersion;
  final String latestVersion;

  const UpdateDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
  });

  Future<void> _openGmail(BuildContext context) async {
    final gmailUri = Uri.parse('googlegmail://');
    if (await canLaunchUrl(gmailUri)) {
      await launchUrl(gmailUri);
    } else {
      await launchUrl(
        Uri.parse('https://mail.google.com'),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.updateAvailableTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.updateDescription),
          const SizedBox(height: 16),
          _VersionRow(
            label: l10n.updateCurrentVersionLabel,
            version: currentVersion,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 4),
          _VersionRow(
            label: l10n.updateLatestVersionLabel,
            version: latestVersion,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.updateClose),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _openGmail(context);
          },
          child: Text(l10n.updateInstall),
        ),
      ],
    );
  }
}

class _VersionRow extends StatelessWidget {
  final String label;
  final String version;
  final Color color;

  const _VersionRow({
    required this.label,
    required this.version,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          version,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
