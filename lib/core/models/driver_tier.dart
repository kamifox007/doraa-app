import 'package:flutter/material.dart';

enum DriverTier {
  bronze('برونزية', 'Bronze', 0, 50, 0.15, Color(0xFFCD7F32)),
  silver('فضية', 'Silver', 51, 200, 0.12, Color(0xFFC0C0C0)),
  gold('ذهبية', 'Gold', 201, 500, 0.10, Color(0xFFFFD700)),
  platinum('ماسية', 'Platinum', 501, 999999, 0.08, Color(0xFFE5E4E2));

  final String nameAr;
  final String nameEn;
  final int minRides;
  final int maxRides;
  final double commissionRate;
  final Color color;

  const DriverTier(this.nameAr, this.nameEn, this.minRides, this.maxRides, this.commissionRate, this.color);

  static DriverTier fromRides(int rides) {
    return DriverTier.values.firstWhere(
      (t) => rides >= t.minRides && rides <= t.maxRides,
      orElse: () => DriverTier.bronze,
    );
  }
}
