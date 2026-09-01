import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bus.dart';
import '../models/route_preset.dart';
import '../services/firestore_service.dart';

/// Real-time stream of all buses from Firestore.
final busesStreamProvider = StreamProvider<List<Bus>>((ref) {
  return FirestoreService.busesRef.snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => Bus.fromFirestore(doc.id, doc.data()))
        .toList();
  });
});

/// Real-time stream of a single bus by its document ID.
final busByIdProvider =
    StreamProvider.family<Bus?, String>((ref, busId) {
  return FirestoreService.busesRef.doc(busId).snapshots().map((doc) {
    if (!doc.exists || doc.data() == null) return null;
    return Bus.fromFirestore(doc.id, doc.data()!);
  });
});

/// Real-time stream of route presets.
final routePresetsProvider =
    StreamProvider<List<RoutePreset>>((ref) {
  return FirestoreService.routesRef.snapshots().map((snapshot) {
    return snapshot.docs
        .map((doc) => RoutePreset.fromMap(doc.id, doc.data()))
        .toList();
  });
});

/// Provides only online/in-transit buses.
final activeBusesProvider = Provider<AsyncValue<List<Bus>>>((ref) {
  final busesAsync = ref.watch(busesStreamProvider);
  return busesAsync.whenData(
    (buses) => buses.where((b) => b.isLive).toList(),
  );
});

/// Count of total buses.
final busCountProvider = Provider<int>((ref) {
  return ref.watch(busesStreamProvider).valueOrNull?.length ?? 0;
});
