import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_constants.dart';
import '../../../models/bus.dart';
import '../../../providers/bus_providers.dart';
import '../../../shared/widgets/glass_card.dart';

/// Screen for generating and displaying QR codes for buses.
class QrGenerationScreen extends ConsumerWidget {
  const QrGenerationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busesAsync = ref.watch(busesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bus QR Codes'),
      ),
      body: busesAsync.when(
        data: (buses) {
          if (buses.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.qr_code_scanner,
                      size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No buses available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add buses first to generate QR codes',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'Bus QR Codes',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Display these QR codes on buses for students to scan and join.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ...buses.map((bus) => _BusQrCard(bus: bus)),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, _) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}

class _BusQrCard extends StatelessWidget {
  final Bus bus;

  const _BusQrCard({required this.bus});

  @override
  Widget build(BuildContext context) {
    final qrData = '${AppConstants.qrDeepLinkPrefix}${bus.fleetCode}';
    final qrSize = MediaQuery.of(context).size.width * 0.35;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bus header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.directions_bus, color: Colors.blue),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bus.busName.isNotEmpty ? bus.busName : bus.busNumber,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${bus.busNumber} • ${bus.routeName}',
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
                  color: _getStatusColor(bus.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bus.status.toUpperCase(),
                  style: TextStyle(
                    color: _getStatusColor(bus.status),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),

          // QR Code and info
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // QR Code
              Container(
                width: qrSize,
                height: qrSize,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.all(12),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: qrSize - 24,
                ),
              ),
              const SizedBox(width: 20),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fleet Code:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      bus.fleetCode,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'QR Data:',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SelectableText(
                      qrData,
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'Monospace',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Students scan this to join ${bus.busName.isNotEmpty ? bus.busName : bus.busNumber}',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _shareQrCode(context, bus, qrData),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Share QR'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _downloadQrCode(context, bus),
                  icon: const Icon(Icons.download, size: 18),
                  label: const Text('Download'),
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

  void _shareQrCode(BuildContext context, Bus bus, String qrData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Share QR Code'),
        content: const Text(
            'QR code sharing functionality would be implemented here to share via email, messaging apps, etc.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _downloadQrCode(BuildContext context, Bus bus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Download QR Code'),
        content: const Text(
            'QR code download functionality would save the QR code as an image file for printing.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
