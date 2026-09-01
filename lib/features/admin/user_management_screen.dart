import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_profile.dart';
import '../../../providers/auth_providers.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/widgets/glass_card.dart';

/// Screen for managing users: view, change roles, etc.
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
      ),
      body: usersAsync.when(
        data: (users) {
          // Sort users: admins first, then drivers, then students
          users.sort((a, b) {
            const roleOrder = {'admin': 0, 'driver': 1, 'student': 2};
            final aOrder = roleOrder[a.role] ?? 3;
            final bOrder = roleOrder[b.role] ?? 3;
            return aOrder.compareTo(bOrder);
          });

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text(
                'User Management',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Manage user roles and view user information.',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Role statistics
              Row(
                children: [
                  _RoleStatCard(
                    role: 'admin',
                    count: users.where((u) => u.role == 'admin').length,
                    color: Colors.purple,
                  ),
                  const SizedBox(width: 12),
                  _RoleStatCard(
                    role: 'driver',
                    count: users.where((u) => u.role == 'driver').length,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  _RoleStatCard(
                    role: 'student',
                    count: users.where((u) => u.role == 'student').length,
                    color: Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // User list
              const Text(
                'All Users',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),

              if (users.isEmpty)
                GlassCard(
                  child: const Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.people_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No users yet',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Users will appear here after they sign in.',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...users.map((user) => _UserCard(
                      user: user,
                      currentUser: currentUser,
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
    );
  }
}

class _RoleStatCard extends StatelessWidget {
  final String role;
  final int count;
  final Color color;

  const _RoleStatCard({
    required this.role,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              role.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserCard extends StatefulWidget {
  final UserProfile user;
  final UserProfile? currentUser;

  const _UserCard({
    required this.user,
    required this.currentUser,
  });

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _isUpdating = false;

  Future<void> _updateUserRole(String newRole) async {
    if (_isUpdating || widget.user.uid == widget.currentUser?.uid) return;

    setState(() => _isUpdating = true);

    try {
      await FirestoreService.updateUserRole(widget.user.uid, newRole);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Changed ${widget.user.displayName} to $newRole'),
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
      setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = widget.user.uid == widget.currentUser?.uid;
    final roleColor = _getRoleColor(widget.user.role);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: widget.user.photoURL != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(widget.user.photoURL!),
                    )
                  : Text(
                      widget.user.displayName[0].toUpperCase(),
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 16),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      widget.user.displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    if (isCurrentUser)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  widget.user.email,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.user.role.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (widget.user.assignedBusId != null &&
                        widget.user.assignedBusId!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'DRIVER',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (widget.user.studentBusId != null &&
                        widget.user.studentBusId!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(left: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'TRACKING',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Role dropdown
          if (!isCurrentUser)
            Container(
              width: 120,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: widget.user.role,
                  isExpanded: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  items: const [
                    DropdownMenuItem(
                      value: 'admin',
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem(
                      value: 'driver',
                      child: Text('Driver'),
                    ),
                    DropdownMenuItem(
                      value: 'student',
                      child: Text('Student'),
                    ),
                  ],
                  onChanged: _isUpdating
                      ? null
                      : (value) {
                          if (value != null && value != widget.user.role) {
                            _updateUserRole(value);
                          }
                        },
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Current User',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'driver':
        return Colors.orange;
      case 'student':
      default:
        return Colors.blue;
    }
  }
}