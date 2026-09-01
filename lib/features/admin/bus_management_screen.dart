import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/bus.dart';
import '../../../services/firestore_service.dart';

/// Screen for managing buses: add, edit, delete.
class BusManagementScreen extends ConsumerStatefulWidget {
  const BusManagementScreen({super.key});

  @override
  ConsumerState<BusManagementScreen> createState() =>
      _BusManagementScreenState();
}

class _BusManagementScreenState extends ConsumerState<BusManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _busNumberController = TextEditingController();
  final _busNameController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _fleetCodeController = TextEditingController();
  final _capacityController = TextEditingController(text: '40');
  final _routeNameController = TextEditingController();
  final _routeColorController = TextEditingController(text: '#3b82f6');

  String _selectedStatus = 'offline';
  final List<String> _statusOptions = [
    'offline',
    'online',
    'in_transit',
    'idle',
    'maintenance'
  ];

  Bus? _editingBus;
  bool _isSubmitting = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Bus && _editingBus == null) {
      _startEditingBus(args);
    }
  }

  @override
  void dispose() {
    _busNumberController.dispose();
    _busNameController.dispose();
    _plateNumberController.dispose();
    _fleetCodeController.dispose();
    _capacityController.dispose();
    _routeNameController.dispose();
    _routeColorController.dispose();
    super.dispose();
  }

  void _startEditingBus(Bus bus) {
    setState(() {
      _editingBus = bus;
      _busNumberController.text = bus.busNumber;
      _busNameController.text = bus.busName;
      _plateNumberController.text = bus.plateNumber;
      _fleetCodeController.text = bus.fleetCode;
      _capacityController.text = bus.capacity.toString();
      _routeNameController.text = bus.routeName;
      _routeColorController.text = bus.routeColor;
      _selectedStatus = bus.status;
    });
  }

  void _clearForm() {
    setState(() {
      _editingBus = null;
      _busNumberController.clear();
      _busNameController.clear();
      _plateNumberController.clear();
      _fleetCodeController.clear();
      _capacityController.text = '40';
      _routeNameController.clear();
      _routeColorController.text = '#3b82f6';
      _selectedStatus = 'offline';
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final busData = {
        'busNumber': _busNumberController.text.trim(),
        'busName': _busNameController.text.trim(),
        'plateNumber': _plateNumberController.text.trim(),
        'fleetCode': _fleetCodeController.text.trim().toUpperCase(),
        'capacity': int.parse(_capacityController.text),
        'routeName': _routeNameController.text.trim(),
        'routeColor': _routeColorController.text.trim(),
        'status': _selectedStatus,
        'driverName': 'Unassigned',
        'currentPassengers': 0,
        'stops': [],
        'createdAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      if (_editingBus != null) {
        await FirestoreService.updateBus(_editingBus!.id, busData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated ${_busNameController.text}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await FirestoreService.addBus(busData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${_busNameController.text} to fleet'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      if (mounted) {
        _clearForm();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _deleteBus(Bus bus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Bus?'),
        content: Text(
            'Are you sure you want to delete "${bus.busName}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await FirestoreService.deleteBus(bus.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted ${bus.busName}'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back after successful deletion
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting bus: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editingBus != null ? 'Edit Bus' : 'Add New Bus'),
        actions: [
          if (_editingBus != null) ...[
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _deleteBus(_editingBus!),
              tooltip: 'Delete Bus',
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearForm,
              tooltip: 'Clear',
            ),
          ],
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Bus Number
              TextFormField(
                controller: _busNumberController,
                decoration: const InputDecoration(
                  labelText: 'Bus Number *',
                  hintText: 'e.g. BUS-001',
                  prefixIcon: Icon(Icons.numbers),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a bus number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bus Name
              TextFormField(
                controller: _busNameController,
                decoration: const InputDecoration(
                  labelText: 'Bus Name',
                  hintText: 'e.g. Campus Express',
                  prefixIcon: Icon(Icons.directions_bus),
                ),
              ),
              const SizedBox(height: 16),

              // Plate Number
              TextFormField(
                controller: _plateNumberController,
                decoration: const InputDecoration(
                  labelText: 'Plate Number *',
                  hintText: 'e.g. ABC-123',
                  prefixIcon: Icon(Icons.car_rental),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a plate number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fleet Code
              TextFormField(
                controller: _fleetCodeController,
                decoration: const InputDecoration(
                  labelText: 'Fleet Code *',
                  hintText: 'e.g. BUS-A1B2',
                  prefixIcon: Icon(Icons.tag),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a fleet code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Capacity
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity *',
                  hintText: 'e.g. 40',
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter capacity';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Please enter a valid capacity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Route Name
              TextFormField(
                controller: _routeNameController,
                decoration: const InputDecoration(
                  labelText: 'Route Name',
                  hintText: 'e.g. Main Campus Loop',
                  prefixIcon: Icon(Icons.route),
                ),
              ),
              const SizedBox(height: 16),

              // Route Color
              TextFormField(
                controller: _routeColorController,
                decoration: const InputDecoration(
                  labelText: 'Route Color (Hex)',
                  hintText: '#3b82f6',
                  prefixIcon: Icon(Icons.color_lens),
                ),
              ),
              const SizedBox(height: 16),

              // Status Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.circle),
                ),
                items: _statusOptions.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(
                      status.replaceAll('_', ' ').toUpperCase(),
                      style: TextStyle(
                        color: _getStatusColor(status),
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedStatus = value);
                  }
                },
              ),
              const SizedBox(height: 32),

              // Submit Button
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator()
                    : Text(
                        _editingBus != null ? 'Update Bus' : 'Add Bus',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
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
