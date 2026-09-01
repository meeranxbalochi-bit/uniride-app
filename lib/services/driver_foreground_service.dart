import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/app_constants.dart';

/// Entry point for the foreground task isolate.
@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(DriverLocationTaskHandler());
}

/// Background task handler that continuously streams the driver's GPS
/// coordinates to Firestore, even when the app is minimized.
class DriverLocationTaskHandler extends TaskHandler {
  String? _busId;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _busId = await FlutterForegroundTask.getData<String>(key: 'busId');
  }

  @override
  Future<void> onRepeatEvent(DateTime timestamp) async {
    if (_busId == null) return;

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      // Use the custom Firestore database ID
      final db = FirebaseFirestore.instanceFor(
        app: Firebase.app(),
        databaseId: AppConstants.firestoreDatabaseId,
      );

      await db.collection(AppConstants.busesCollection).doc(_busId).update({
        'currentLocation': {
          'lat': pos.latitude,
          'lng': pos.longitude,
          'speed': (pos.speed * 3.6).roundToDouble(), // m/s → km/h
          'heading': pos.heading,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        'status': 'in_transit',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      FlutterForegroundTask.updateService(
        notificationTitle: '🚌 UniRide Live Broadcast Active',
        notificationText:
            'Speed: ${(pos.speed * 3.6).toStringAsFixed(1)} km/h • GPS Streaming',
      );
    } catch (e) {
      // Silently handle background location errors
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    if (_busId != null) {
      try {
        final db = FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: AppConstants.firestoreDatabaseId,
        );
        await db
            .collection(AppConstants.busesCollection)
            .doc(_busId)
            .update({'status': 'idle'});
      } catch (_) {}
    }
  }
}

/// Helper class to initialize and control the foreground GPS service.
class DriverForegroundService {
  DriverForegroundService._();

  /// Initialize foreground task configuration.
  static Future<void> init() async {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'uniride_driver_gps',
        channelName: 'UniRide Driver GPS',
        channelDescription: 'Broadcasts driver location to students in real-time',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000), // every 5 seconds
        autoRunOnBoot: false,
        autoRunOnMyPackageReplaced: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  /// Start broadcasting GPS for the given [busId].
  static Future<bool> startBroadcast(String busId) async {
    await FlutterForegroundTask.saveData(key: 'busId', value: busId);
    await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: '🚌 UniRide Live Broadcast',
      notificationText: 'Starting GPS stream...',
      callback: startCallback,
    );
    return true;
  }

  /// Stop broadcasting GPS.
  static Future<bool> stopBroadcast() async {
    await FlutterForegroundTask.stopService();
    return true;
  }
}
