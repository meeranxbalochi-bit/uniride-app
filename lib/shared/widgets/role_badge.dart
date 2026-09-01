import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

/// A small colored chip that displays a user's role with semantic coloring.
class RoleBadge extends StatelessWidget {
  final String role;

  const RoleBadge({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;
    final IconData icon;

    switch (role) {
      case 'admin':
        color = AppColors.primary;
        label = 'Admin';
        icon = Icons.admin_panel_settings;
        break;
      case 'driver':
        color = AppColors.warning;
        label = 'Driver';
        icon = Icons.local_shipping_rounded;
        break;
      case 'student':
        color = AppColors.info;
        label = 'Student';
        icon = Icons.school_rounded;
        break;
      default:
        color = AppColors.textMuted;
        label = 'Pending';
        icon = Icons.hourglass_empty_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
