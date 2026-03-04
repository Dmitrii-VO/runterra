import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../config/api_config.dart';

/// Result of an update check when a newer version is available.
class UpdateInfo {
  final String currentVersion;
  final String latestVersion;
  const UpdateInfo({required this.currentVersion, required this.latestVersion});
}

/// Checks whether a newer app version is available from the backend.
///
/// Call [checkForUpdate] once at app start. Returns [UpdateInfo] if an update
/// is available, or null if up-to-date / check failed. Subsequent calls within
/// the same session return null immediately (checked once per session).
class VersionService {
  static bool _checked = false;

  /// Compares the running app version against [GET /api/version].
  /// Returns null when the app is up-to-date or if the check fails silently.
  static Future<UpdateInfo?> checkForUpdate() async {
    if (_checked) return null;
    _checked = true;

    try {
      final info = await PackageInfo.fromPlatform();
      final current = info.version; // e.g. "1.0.0"

      final baseUrl = ApiConfig.getBaseUrl();
      final response = await http
          .get(Uri.parse('$baseUrl/api/version'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final latest = data['latestVersion'] as String?;
      if (latest == null) return null;

      if (!_isNewer(latest, current)) return null;

      return UpdateInfo(currentVersion: current, latestVersion: latest);
    } catch (_) {
      // Never crash the app due to a version check failure.
      return null;
    }
  }

  /// Returns true if [candidate] is a strictly newer semver than [current].
  static bool _isNewer(String candidate, String current) {
    final c = _parseSemver(candidate);
    final cur = _parseSemver(current);
    for (var i = 0; i < 3; i++) {
      if (c[i] > cur[i]) return true;
      if (c[i] < cur[i]) return false;
    }
    return false;
  }

  static List<int> _parseSemver(String v) {
    final parts = v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) { parts.add(0); }
    return parts;
  }
}
