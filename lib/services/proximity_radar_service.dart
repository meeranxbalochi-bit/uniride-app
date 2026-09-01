import 'dart:math';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';

/// Monitors bus-to-stop distance and fires a local push notification
/// + vibration when the bus is within [AppConstants.proximityAlertMeters].
class ProximityRadarService {
  static final ProximityRadarService _instance =
      ProximityRadarService._internal();
  factory ProximityRadarService() => _instance;
  ProximityRadarService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _hasTriggeredProximityAlert = false;

  /// Initialize the notification plugin and channels.
  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _notifications.initialize(initSettings);
  }

  /// Haversine distance in meters.
  double calculateDistanceMeters(
      double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // pi / 180
    final double a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000;
  }

  /// Checks whether the bus is within proximity of the student's stop.
  /// Sends a one-shot notification if within threshold, resets when far enough.
  void checkProximity({
    required double busLat,
    required double busLng,
    required double stopLat,
    required double stopLng,
    required String busNumber,
    required String stopName,
    required int etaMinutes,
  }) {
    final distanceMeters =
        calculateDistanceMeters(busLat, busLng, stopLat, stopLng);

    if (distanceMeters <= AppConstants.proximityAlertMeters &&
        !_hasTriggeredProximityAlert) {
      _hasTriggeredProximityAlert = true;
      _sendProximityNotification(
        title: '🚍 Shuttle Approaching Your Stop!',
        body:
            '$busNumber is within ${distanceMeters.toStringAsFixed(0)}m of $stopName '
            '(ETA: ~$etaMinutes min). Prepare to board!',
      );
    } else if (distanceMeters > AppConstants.proximityResetMeters) {
      _hasTriggeredProximityAlert = false;
    }
  }

  Future<void> _sendProximityNotification(
      {required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'uniride_proximity_channel',
      'Transit Proximity Alerts',
      channelDescription:
          'High-priority 450m proximity alerts for campus shuttles',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );

    const details = NotificationDetails(android: androidDetails);
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
    );
  }
}
