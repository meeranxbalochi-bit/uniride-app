import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/bus.dart';
import '../../../models/user_profile.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/bus_providers.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/glass_card.dart';

/// Screen for assigning drivers to buses.
class DriverAssignmentScreen extends ConsumerWidget {
  const DriverAssignmentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busesAsync = ref.watch(busesStreamProvider);
    final usersAsync = ref.watch(allUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Assignment'),
      ),
      body: busesAsync.when(
        data: (buses) => usersAsync.when(
          data: (users) {
            final drivers = users.where((u) => u.role == 'driver').toList();

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Assign Drivers to Buses',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Assign available drivers to buses in your fleet.',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                if (drivers.isEmpty)
                  GlassCard(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(Icons.people_outline,
                              size: 64, color: Colors.grey),
                          const SizedBox(height: 16),
                          const Text(
                            'No drivers available',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Users must have "driver" role to appear here.',
                            style: TextStyle(color: Colors.grey),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Go to User Management'),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...buses.map((bus) => _BusDriverCard(
                        bus: bus,
                        drivers: drivers,
                        allBuses: buses,
                      )),
              ],
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => Center(
            child: Text('Error loading users: $error'),
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error loading buses: $error'),
        ),
      ),
    );
  }
}

class _BusDriverCard extends StatefulWidget {
  final Bus bus;
  final List<UserProfile> drivers;
  final List<Bus> allBuses;

  const _BusDriverCard({
    required this.bus,
    required this.drivers,
    required this.allBuses,
  });

  @override
  State<_BusDriverCard> createState() => _BusDriverCardState();
}

class _BusDriverCardState extends State<_BusDriverCard> {
  UserProfile? _selectedDriver;
  bool _isAssigning = false;

  @override
  void initState() {
    super.initState();
    // Find current driver if assigned
    if (widget.bus.driverId != null && widget.bus.driverId!.isNotEmpty) {
      try {
        _selectedDriver =
            widget.drivers.firstWhere((d) => d.uid == widget.bus.driverId);
      } catch (e) {
        _selectedDriver = null;
      }
    }
  }

  Future<void> _assignDriver() async {
    if (_selectedDriver == null || _isAssigning) return;

    setState(() => _isAssigning = true);

    try {
      await FirestoreService.assignDriver(
        widget.bus.id,
        _selectedDriver!.uid,
        _selectedDriver!.displayName,
        _selectedDriver!.phoneNumber ?? '',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Assigned ${_selectedDriver!.displayName} to ${widget.bus.busName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAssigning = false);
    }
  }

  Future<void> _unassignDriver() async {
    if (_isAssigning) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unassign Driver?'),
        content: Text(
            'Are you sure you want to unassign ${widget.bus.driverName} from ${widget.bus.busName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unassign', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isAssigning = true);

    try {
      await FirestoreService.unassignDriver(widget.bus.id);

      setState(() {
        _selectedDriver = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unassigned driver from ${widget.bus.busName}'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isAssigning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get buses already assigned to each driver
    final driverBusAssignments = <String, List<Bus>>{};
    for (final bus in widget.allBuses) {
      if (bus.driverId != null && bus.driverId!.isNotEmpty) {
        driverBusAssignments.putIfAbsent(bus.driverId!, () => []).add(bus);
      }
    }

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bus info
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.bus.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.directions_bus,
                    color: _getStatusColor(widget.bus.status)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.bus.busName.isNotEmpty
                          ? widget.bus.busName
                          : widget.bus.busNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.bus.routeName} • ${widget.bus.fleetCode}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getStatusColor(widget.bus.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.bus.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(widget.bus.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Current assignment
          if (widget.bus.driverId != null && widget.bus.driverId!.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Driver:',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: Colors.blue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.bus.driverName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (widget.bus.driverPhone != null &&
                                widget.bus.driverPhone!.isNotEmpty)
                              Text(
                                widget.bus.driverPhone!,
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: _unassignDriver,
                        tooltip: 'Unassign',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),

          // Driver selection
          const Text(
            'Assign Driver:',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserProfile>(
                value: _selectedDriver,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                hint: const Text('Select a driver'),
                items: widget.drivers.map((driver) {
                  final assignedBuses = driverBusAssignments[driver.uid] ?? [];
                  final isAssignedToThisBus = widget.bus.driverId == driver.uid;
                  final isAssignedToOtherBus =
                      assignedBuses.isNotEmpty && !isAssignedToThisBus;

                  return DropdownMenuItem(
                    value: driver,
                    enabled: !isAssignedToOtherBus || isAssignedToThisBus,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              driver.displayName[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  driver.displayName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isAssignedToOtherBus &&
                                            !isAssignedToThisBus
                                        ? Colors.grey
                                        : Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  driver.email,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isAssignedToOtherBus)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Assigned',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (driver) {
                  if (driver != null) {
                    setState(() => _selectedDriver = driver);
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.bus.driverId != null &&
                          widget.bus.driverId!.isNotEmpty
                      ? _unassignDriver
                      : null,
                  child: const Text('Unassign'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _selectedDriver != null &&
                          _selectedDriver!.uid != widget.bus.driverId &&
                          !_isAssigning
                      ? _assignDriver
                      : null,
                  child: _isAssigning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Assign'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return Colors.green;
      case 'in_transit':
        return Colors.blue;
      case 'idle':
        return Colors.orange;
      case 'maintenance':
        return Colors.red;
      case 'offline':
      default:
        return Colors.grey;
    }
  }
}
