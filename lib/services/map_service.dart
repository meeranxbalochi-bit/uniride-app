import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Provides satellite map tile layer using USGS Satellite imagery via Flutter Map (Leaflet).
/// 
/// This replaces Google Maps with an open-source Leaflet-based satellite map solution.
class MapService {
  MapService._();

  /// Returns the satellite map tile layer for Flutter Map.
  /// 
  /// Uses USGS imagery which provides worldwide satellite/aerial coverage.
  static TileLayer getSatelliteTileLayer() {
    return TileLayer(
      urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
      userAgentPackageName: 'com.uniride.transit',
      // Fallback to OpenStreetMap if USGS is unavailable
      fallbackUrl: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      subdomains: const ['a', 'b', 'c'],
      maxNativeZoom: 19,
      maxZoom: 19,
    );
  }

  /// Returns the standard street map tile layer.
  static TileLayer getStreetTileLayer() {
    return TileLayer(
      urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.uniride.transit',
      subdomains: const ['a', 'b', 'c'],
      maxNativeZoom: 19,
      maxZoom: 19,
    );
  }

  /// Calculates distance between two coordinates in meters using Haversine formula.
  static double calculateDistance(LatLng from, LatLng to) {
    const earthRadiusM = 6371000; // Earth radius in meters
    final lat1Rad = _degreesToRadians(from.latitude);
    final lat2Rad = _degreesToRadians(to.latitude);
    final dLat = _degreesToRadians(to.latitude - from.latitude);
    final dLng = _degreesToRadians(to.longitude - from.longitude);

    final a = (1 - (2 * dLat / (2 * 3.14159265359)).cos()) / 2 +
        (2 * lat1Rad / (2 * 3.14159265359)).cos() *
            (2 * lat2Rad / (2 * 3.14159265359)).cos() *
            (1 - (2 * dLng / (2 * 3.14159265359)).cos()) /
            2;

    return earthRadiusM * 2 * (a.isNaN ? 0 : a.asin().abs());
  }

  static double _degreesToRadians(double degrees) => degrees * (3.14159265359 / 180);
}
