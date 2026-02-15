import 'package:flutter/material.dart';
import '../models/territory_league_models.dart';

/// Color palette for zone difficulty tiers
class TierColors {
  TierColors._();

  static const green = Color(0xFF4CAF50);
  static const blue = Color(0xFF2196F3);
  static const red = Color(0xFFF44336);
  static const black = Color(0xFF212121);

  /// Returns the primary color for a given tier
  static Color forTier(ZoneTier tier) {
    switch (tier) {
      case ZoneTier.green:
        return green;
      case ZoneTier.blue:
        return blue;
      case ZoneTier.red:
        return red;
      case ZoneTier.black:
        return black;
    }
  }

  /// Returns a gradient color list for a given tier (for header backgrounds)
  static List<Color> gradientForTier(ZoneTier tier) {
    switch (tier) {
      case ZoneTier.green:
        return [const Color(0xFF66BB6A), const Color(0xFF388E3C)];
      case ZoneTier.blue:
        return [const Color(0xFF42A5F5), const Color(0xFF1565C0)];
      case ZoneTier.red:
        return [const Color(0xFFEF5350), const Color(0xFFC62828)];
      case ZoneTier.black:
        return [const Color(0xFF424242), const Color(0xFF000000)];
    }
  }
}
