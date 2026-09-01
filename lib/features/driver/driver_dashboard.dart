import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_providers.dart';
import '../../providers/bus_providers.dart';
import '../../shared/widgets/glass_card.dart';

/// Driver Dashboard — Phase 3 will add full foreground GPS service
/// controls, passenger counter, and announcements.
class DriverDashboardScreen extends ConsumerWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final profile = authService.profile;
    final busesAsync = ref.watch(busesStreamProvider);

    // Find the driver's assigned bus
    final assignedBus = busesAsync.valueOrNull?.cast().firstWhere(
          (b) => b.driverId == profile?.uid || b.id == profile?.assignedBusId,
          orElse: () => null,
        );

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
              child: const Icon(Icons.local_shipping_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text('Driver Cockpit'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => authService.signOut(),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome
            Text(
              'Hello, ${profile?.displayName ?? 'Driver'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              assignedBus != null
                  ? 'Assigned to ${assignedBus.busName}'
                  : 'No bus assigned yet',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),

            // Assigned bus card
            if (assignedBus != null)
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.directions_bus,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                assignedBus.busName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${assignedBus.busNumber} • ${assignedBus.plateNumber}',
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.busStatusColor(assignedBus.status)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            assignedBus.status.toUpperCase(),
                            style: TextStyle(
                              color:
                                  AppColors.busStatusColor(assignedBus.status),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.divider),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoTile(
                          icon: Icons.route,
                          label: 'Route',
                          value: assignedBus.routeName.isNotEmpty
                              ? assignedBus.routeName
                              : 'N/A',
                        ),
                        _InfoTile(
                          icon: Icons.people,
                          label: 'Passengers',
                          value:
                              '${assignedBus.currentPassengers}/${assignedBus.capacity}',
                        ),
                        _InfoTile(
                          icon: Icons.speed,
                          label: 'Speed',
                          value:
                              '${assignedBus.currentLocation?.speed.toStringAsFixed(0) ?? '0'} km/h',
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Online toggle placeholder (Phase 3)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: AppColors.borderLight),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.gps_fixed,
                                color: AppColors.textMuted, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'GPS Broadcast Controls — Phase 3',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              GlassCard(
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Column(
                      children: [
                        Icon(Icons.bus_alert,
                            color: AppColors.textMuted, size: 56),
                        SizedBox(height: 16),
                        Text(
                          'No Bus Assigned',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Contact your fleet admin to get assigned.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accent, size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
