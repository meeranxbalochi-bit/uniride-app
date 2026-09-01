import 'dart:math';

/// Geographic utility functions for distance, bearing, and ETA calculations.
class GeoUtils {
  GeoUtils._();

  /// Haversine formula: calculates distance in meters between two coordinates.
  static double distanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // pi / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * asin(...) in meters
  }

  /// Calculates the bearing (0-360°) from point A to point B.
  static double calculateBearing(
      double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295;
    final double dLon = (lon2 - lon1) * p;
    final double y = sin(dLon) * cos(lat2 * p);
    final double x =
        cos(lat1 * p) * sin(lat2 * p) - sin(lat1 * p) * cos(lat2 * p) * cos(dLon);
    final double bearing = atan2(y, x) * (180.0 / pi);
    return (bearing + 360) % 360;
  }

  /// Estimates travel time in minutes given distance in meters and average speed in km/h.
  static int estimateEtaMinutes(double distanceMeters,
      {double avgSpeedKmh = 30.0}) {
    if (avgSpeedKmh <= 0) return 0;
    final double distanceKm = distanceMeters / 1000;
    final double hours = distanceKm / avgSpeedKmh;
    return (hours * 60).ceil();
  }
}
