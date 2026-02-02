import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';

/// Секция настроек
/// 
/// Отображает минимальные настройки для MVP:
/// - Статус разрешения геолокации
/// - Видимость профиля
/// - Выйти из аккаунта
/// - Удалить аккаунт
/// 
/// ВАЖНО: На текущей стадии (skeleton) только UI без логики.
class ProfileSettingsSection extends StatelessWidget {
  final bool locationPermissionGranted;
  final bool profileVisible;
  final VoidCallback? onLogout;
  final VoidCallback? onDeleteAccount;

  const ProfileSettingsSection({
    super.key,
    this.locationPermissionGranted = false,
    this.profileVisible = true,
    this.onLogout,
    this.onDeleteAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.location_on),
            title: Text(AppLocalizations.of(context)!.settingsLocation),
            subtitle: Text(
              locationPermissionGranted
                  ? AppLocalizations.of(context)!.settingsLocationAllowed
                  : AppLocalizations.of(context)!.settingsLocationDenied,
            ),
            trailing: Icon(
              locationPermissionGranted ? Icons.check_circle : Icons.cancel,
              color: locationPermissionGranted ? Colors.green : Colors.red,
            ),
            // TODO: Реализовать открытие настроек разрешений
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.visibility),
            title: Text(AppLocalizations.of(context)!.settingsVisibility),
            subtitle: Text(
              profileVisible
                  ? AppLocalizations.of(context)!.settingsVisible
                  : AppLocalizations.of(context)!.settingsHidden,
            ),
            trailing: Switch(
              value: profileVisible,
              onChanged: (_) {
                // TODO: Реализовать изменение видимости профиля
                // Currently disabled as profile visibility toggle is not implemented
              },
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              AppLocalizations.of(context)!.settingsLogout,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: onLogout,
            // TODO: Реализовать выход из аккаунта
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: Text(
              AppLocalizations.of(context)!.settingsDeleteAccount,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: onDeleteAccount,
            // TODO: Реализовать удаление аккаунта
          ),
        ],
      ),
    );
  }
}
