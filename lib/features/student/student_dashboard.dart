import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/bus.dart';
import '../../providers/auth_providers.dart';
import '../../providers/bus_providers.dart';
import '../../services/proximity_radar_service.dart';
import '../../services/firestore_service.dart';
import '../../services/map_service.dart';
import '../../shared/widgets/glass_card.dart';

/// Student live tracking dashboard with Leaflet Satellite Map and QR scanner.
class StudentDashboardScreen extends ConsumerStatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  ConsumerState<StudentDashboardScreen> createState() =>
      _StudentDashboardScreenState();
}

class _StudentDashboardScreenState
    extends ConsumerState<StudentDashboardScreen> {
  late MapController _mapController;
  final ProximityRadarService _radar = ProximityRadarService();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final profile = authService.profile;
    final busesAsync = ref.watch(busesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffold,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: AppColors.accentGradient,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.gps_fixed, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Live Tracker'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded),
            onPressed: () => _openQrScanner(context),
            tooltip: 'Scan Bus QR',
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => authService.signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: busesAsync.when(
        data: (buses) {
          // Find the student's tracked bus
          Bus? trackedBus;
          if (profile?.studentBusId != null) {
            trackedBus = buses.cast<Bus?>().firstWhere(
                  (b) => b!.id == profile!.studentBusId,
                  orElse: () => null,
                );
          }

          // Run proximity radar
          if (trackedBus != null &&
              trackedBus.currentLocation != null &&
              trackedBus.stops.isNotEmpty) {
            // Use student's designated stop, or first stop as fallback
            BusStop targetStop;
            if (profile?.studentStopId != null) {
              targetStop = trackedBus.stops.firstWhere(
                (s) => s.id == profile!.studentStopId,
                orElse: () => trackedBus!.stops.first,
              );
            } else {
              targetStop = trackedBus.stops.first;
            }

            _radar.checkProximity(
              busLat: trackedBus.currentLocation!.lat,
              busLng: trackedBus.currentLocation!.lng,
              stopLat: targetStop.lat,
              stopLng: targetStop.lng,
              busNumber: trackedBus.busNumber,
              stopName: targetStop.name,
              etaMinutes: trackedBus.nextStopEtaMinutes,
            );
          }

          if (trackedBus == null) {
            return _buildNoTrackedBus(context);
          }

          return Stack(
            children: [
              // Leaflet Satellite Map
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: LatLng(
                    trackedBus.currentLocation?.lat ?? AppConstants.defaultLat,
                    trackedBus.currentLocation?.lng ?? AppConstants.defaultLng,
                  ),
                  initialZoom: 15.5,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all,
                  ),
                ),
                children: [
                  // Satellite tile layer (USGS imagery)
                  MapService.getSatelliteTileLayer(),
                  // Bus marker
                  if (trackedBus.currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(
                            trackedBus.currentLocation!.lat,
                            trackedBus.currentLocation!.lng,
                          ),
                          width: 50,
                          height: 50,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(8),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  trackedBus.busNumber,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  // Stop markers
                  MarkerLayer(
                    markers: trackedBus.stops.map((stop) {
                      return Marker(
                        point: LatLng(stop.lat, stop.lng),
                        width: 40,
                        height: 40,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(5),
                              child: const Icon(
                                Icons.location_on_outlined,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade900,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                stop.name.length > 12
                                    ? '${stop.name.substring(0, 12)}...'
                                    : stop.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),

              // Recenter FAB
              if (trackedBus.currentLocation != null)
                Positioned(
                  right: 16,
                  bottom: 180,
                  child: FloatingActionButton.small(
                    onPressed: () {
                      _mapController.move(
                        LatLng(
                          trackedBus!.currentLocation!.lat,
                          trackedBus.currentLocation!.lng,
                        ),
                        15.5,
                      );
                    },
                    backgroundColor: AppColors.surface,
                    child:
                        const Icon(Icons.my_location, color: AppColors.primary),
                  ),
                ),

              // Bottom info card
              Positioned(
                bottom: 20,
                left: 16,
                right: 16,
                child: GlassCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.busStatusColor(trackedBus.status)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              Icons.directions_bus,
                              color:
                                  AppColors.busStatusColor(trackedBus.status),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  trackedBus.busName.isNotEmpty
                                      ? trackedBus.busName
                                      : trackedBus.busNumber,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  trackedBus.stops.isNotEmpty
                                      ? 'Next: ${trackedBus.stops[trackedBus.nextStopIndex < trackedBus.stops.length ? trackedBus.nextStopIndex : 0].name}'
                                      : trackedBus.routeName,
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '~${trackedBus.nextStopEtaMinutes} MIN',
                              style: const TextStyle(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (trackedBus.currentLocation != null) ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _MiniStat(
                              icon: Icons.speed,
                              value:
                                  '${trackedBus.currentLocation!.speed.toStringAsFixed(0)} km/h',
                            ),
                            _MiniStat(
                              icon: Icons.people,
                              value:
                                  '${trackedBus.currentPassengers}/${trackedBus.capacity}',
                            ),
                            _MiniStat(
                              icon: Icons.circle,
                              value: trackedBus.status
                                  .replaceAll('_', ' ')
                                  .toUpperCase(),
                              color:
                                  AppColors.busStatusColor(trackedBus.status),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error',
              style: const TextStyle(color: AppColors.error)),
        ),
      ),
    );
  }

  Widget _buildNoTrackedBus(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(Icons.qr_code_scanner,
                  color: Colors.white, size: 48),
            ),
            const SizedBox(height: 28),
            const Text(
              'No Bus Tracked',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Scan a bus QR code or enter a fleet code\nto start tracking.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => _openQrScanner(context),
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Scan QR Code'),
            ),
          ],
        ),
      ),
    );
  }

  void _openQrScanner(BuildContext context) {
    final fleetCodeController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceMedium,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan Bus QR Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: MobileScanner(
                  onDetect: (capture) => _handleQrDetected(capture, context),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'OR enter fleet code manually',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 13,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: fleetCodeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'e.g. BUS-A1B2',
                        prefixIcon: Icon(Icons.tag),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () =>
                        _joinByFleetCode(fleetCodeController.text, context),
                    child: const Text('Join'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleQrDetected(
      BarcodeCapture capture, BuildContext context) async {
    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        final raw = barcode.rawValue!;
        final code = raw.replaceAll(AppConstants.qrDeepLinkPrefix, '');
        await _joinByFleetCode(code, context);
        break;
      }
    }
  }

  Future<void> _joinByFleetCode(String code, BuildContext context) async {
    if (code.trim().isEmpty) return;

    final query = await FirestoreService.busesRef
        .where('fleetCode', isEqualTo: code.trim().toUpperCase())
        .limit(1)
        .get();

    if (!context.mounted) return;

    if (query.docs.isNotEmpty) {
      final busName = query.docs.first.data()['busName'] as String? ?? 'Bus';
      final busId = query.docs.first.id;
      await ref.read(authServiceProvider).updateStudentBus(busId);
      if (!context.mounted) return;
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Joined bus: $busName'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bus not found. Check the fleet code.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color? color;

  const _MiniStat({
    required this.icon,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color ?? AppColors.textMuted),
        const SizedBox(width: 6),
        Text(
          value,
          style: TextStyle(
            color: color ?? AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
