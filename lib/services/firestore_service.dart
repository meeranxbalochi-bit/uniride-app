import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/constants/app_constants.dart';

// ignore_for_file: avoid_catches_without_on_clauses

/// Centralized Firestore access.
///
/// This project uses a CUSTOM Firestore Database ID (not the default one).
/// All Firestore operations MUST go through [FirestoreService.db] to ensure
/// they target the correct database instance.
class FirestoreService {
  FirestoreService._();

  static FirebaseFirestore? _instance;

  /// Returns the Firestore instance targeting the custom database ID.
  static FirebaseFirestore get db {
    _instance ??= FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: AppConstants.firestoreDatabaseId,
    );
    return _instance!;
  }

  /// Users collection reference.
  static CollectionReference<Map<String, dynamic>> get usersRef =>
      db.collection(AppConstants.usersCollection);

  /// Buses collection reference.
  static CollectionReference<Map<String, dynamic>> get busesRef =>
      db.collection(AppConstants.busesCollection);

  /// Routes collection reference.
  static CollectionReference<Map<String, dynamic>> get routesRef =>
      db.collection(AppConstants.routesCollection);

  // ─── Bus Write Methods ─────────────────────────────────────────────────────

  /// Add a new bus document (auto-generates ID).
  static Future<void> addBus(Map<String, dynamic> data) =>
      busesRef.add(data);

  /// Update specific fields of a bus document.
  static Future<void> updateBus(String id, Map<String, dynamic> data) =>
      busesRef.doc(id).update(data);

  /// Delete a bus document.
  static Future<void> deleteBus(String id) => busesRef.doc(id).delete();

  /// Update bus status string (e.g. 'online', 'idle', 'in_transit').
  static Future<void> updateBusStatus(String busId, String status) =>
      busesRef.doc(busId).update({'status': status});

  /// Update passenger count on a bus.
  static Future<void> updateBusPassengers(String busId, int newCount) =>
      busesRef.doc(busId).update({'currentPassengers': newCount});

  /// Update last/next stop indices when a driver marks a stop as passed.
  static Future<void> updateBusNextStop(
          String busId, int lastStopIndex, int nextStopIndex) =>
      busesRef.doc(busId).update({
        'lastStopIndex': lastStopIndex,
        'nextStopIndex': nextStopIndex,
      });

  /// Post an announcement visible to students.
  static Future<void> postAnnouncement(
          String busId, String text, String type) =>
      busesRef.doc(busId).update({
        'announcement': text,
        'announcementType': type,
      });

  /// Clear the active announcement on a bus.
  static Future<void> clearAnnouncement(String busId) =>
      busesRef.doc(busId).update({
        'announcement': '',
        'announcementType': '',
      });

  /// Assign a driver to a bus.
  static Future<void> assignDriver(
    String busId,
    String driverId,
    String driverName,
    String driverPhone,
  ) =>
      busesRef.doc(busId).update({
        'driverId': driverId,
        'driverName': driverName,
        'driverPhone': driverPhone,
      });

  /// Remove driver assignment from a bus.
  static Future<void> unassignDriver(String busId) =>
      busesRef.doc(busId).update({
        'driverId': '',
        'driverName': '',
        'driverPhone': '',
      });

  // ─── Route Write Methods ───────────────────────────────────────────────────

  /// Add a new route preset (auto-generates ID).
  static Future<void> addRoute(Map<String, dynamic> data) =>
      routesRef.add(data);

  /// Update specific fields of a route preset.
  static Future<void> updateRoute(String id, Map<String, dynamic> data) =>
      routesRef.doc(id).update(data);

  /// Delete a route preset.
  static Future<void> deleteRoute(String id) => routesRef.doc(id).delete();

  // ─── User Write Methods ────────────────────────────────────────────────────

  /// Change the role of a user ('student' | 'driver' | 'admin').
  static Future<void> updateUserRole(String uid, String newRole) =>
      usersRef.doc(uid).update({'role': newRole});
}

