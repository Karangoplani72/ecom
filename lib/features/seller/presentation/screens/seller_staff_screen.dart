import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/app_text_field.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';
import 'package:ecom/features/seller/domain/entities/staff_permission.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_controller.dart';
import 'package:ecom/features/seller/presentation/controllers/seller_staff_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class SellerStaffScreen extends ConsumerStatefulWidget {
  const SellerStaffScreen({super.key});

  @override
  ConsumerState<SellerStaffScreen> createState() => _SellerStaffScreenState();
}

class _SellerStaffScreenState extends ConsumerState<SellerStaffScreen> {
  final _emailController = TextEditingController();
  String _selectedRole = 'Manager';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _showInviteBottomSheet(BuildContext context) {
    _emailController.clear();
    _selectedRole = 'Manager';
    Set<StaffPermission> customPermissions = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Invite Staff Member',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter the email address of the team member you want to add to your storefront operations.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'name@example.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Access Role',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderLG,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Manager',
                        child: Text('Manager (Full access)'),
                      ),
                      DropdownMenuItem(
                        value: 'Editor',
                        child: Text('Editor (Manage inventory & orders)'),
                      ),
                      DropdownMenuItem(
                        value: 'Viewer',
                        child: Text('Viewer (Read-only access)'),
                      ),
                      DropdownMenuItem(
                        value: 'Custom',
                        child: Text('Custom (Select permissions)'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setModalState(() => _selectedRole = val);
                      }
                    },
                  ),
                  if (_selectedRole == 'Custom') ...[
                    const SizedBox(height: 16),
                    Text(
                      'Select Permissions',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: isDark ? Colors.white24 : AppColors.border),
                        borderRadius: AppRadius.borderLG,
                      ),
                      child: SingleChildScrollView(
                        child: Column(
                          children: StaffPermission.values.map((perm) {
                            final isSelected = customPermissions.contains(perm);
                            return CheckboxListTile(
                              title: Text(perm.name),
                              value: isSelected,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setModalState(() {
                                  if (val == true) {
                                    customPermissions.add(perm);
                                  } else {
                                    customPermissions.remove(perm);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  AppPrimaryButton(
                    text: 'Send Invitation',
                    onPressed: () async {
                      final email = _emailController.text.trim();
                      if (email.isEmpty) return;

                      StaffPermissions? customPerms;
                      if (_selectedRole == 'Custom') {
                        if (customPermissions.isEmpty) {
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Please select at least one custom permission.'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        customPerms = StaffPermissions.fromList(customPermissions.map((e) => e.name).toList());
                      }

                      // Close bottom sheet first
                      Navigator.pop(context);

                      final result = await ref
                          .read(sellerStaffControllerProvider.notifier)
                          .inviteStaff(email, _selectedRole, customPerms);

                      if (mounted) {
                        result.fold(
                          (err) =>
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                SnackBar(
                                  content: Text(err),
                                  backgroundColor: AppColors.error,
                                ),
                              ),
                          (_) {
                            ref.invalidate(sellerStaffControllerProvider);
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Staff member invited successfully!',
                                ),
                              ),
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(sellerStaffControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: TextButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Invite Staff'),
              onPressed: () => _showInviteBottomSheet(context),
            ),
          ),
        ],
      ),
      body: staffState.when(
        loading: () => const AppLoadingView(),
        error: (err, _) => AppErrorView(
          message: 'Failed to load staff list: $err',
          onRetry: () => ref.invalidate(sellerStaffControllerProvider),
        ),
        data: (data) {
          final active = data.activeStaff;
          final pending = data.pendingInvitations;

          if (active.isEmpty && pending.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.people_outline_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No Team Members Yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite managers, editors, or viewers to help handle your store operations.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Invite First Staff Member'),
                    onPressed: () => _showInviteBottomSheet(context),
                  ),
                ],
              ),
            );
          }

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  labelColor: AppColors.primary,
                  unselectedLabelColor: isDark
                      ? Colors.white54
                      : AppColors.lightTextSecondary,
                  indicatorColor: AppColors.primary,
                  tabs: [
                    Tab(text: 'Active Staff (${active.length})'),
                    Tab(text: 'Pending Invites (${pending.length})'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildActiveStaffList(active, isDark),
                      _buildPendingInvitesList(pending, isDark),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveStaffList(List<AppUser> staff, bool isDark) {
    if (staff.isEmpty) {
      return const Center(child: Text('No active staff members.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: staff.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final member = staff[index];
        final dateStr = DateFormat('MMM d, yyyy').format(member.createdAt);

        return Card(
          elevation: 0,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? Colors.white12 : AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(
                    member.displayName.isNotEmpty
                        ? member.displayName[0].toUpperCase()
                        : 'S',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.displayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Manager',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        member.email,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Joined $dateStr',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.tune_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () =>
                      _showManagePermissionsSheet(context, ref, member),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  onPressed: () => _confirmRemoveStaff(member),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingInvitesList(List<StaffInvitation> invites, bool isDark) {
    if (invites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mark_email_read_outlined,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No Pending Invitations',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white54 : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All sent invitations have been accepted or revoked.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: invites.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final invite = invites[index];
        final dateStr = DateFormat(
          'MMM d, yyyy · h:mm a',
        ).format(invite.createdAt);

        final timeAgo = _formatTimeAgo(invite.createdAt);
        final roleConfig = _getRoleConfig(invite.role);

        return Card(
          elevation: 0,
          color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? Colors.white12 : AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: avatar + email + role badge
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.withValues(alpha: 0.15),
                            Colors.deepOrange.withValues(alpha: 0.08),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          invite.email.isNotEmpty
                              ? invite.email[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            invite.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.orange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Pending · $timeAgo',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: roleConfig.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: roleConfig.color.withValues(alpha: 0.3),
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            roleConfig.icon,
                            size: 12,
                            color: roleConfig.color,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            invite.role,
                            style: TextStyle(
                              color: roleConfig.color,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Detail rows
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.04)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (invite.storeName.isNotEmpty)
                        _buildDetailRow(
                          icon: Icons.storefront_rounded,
                          label: 'Store',
                          value: invite.storeName,
                          isDark: isDark,
                        ),
                      if (invite.invitedBy.isNotEmpty) ...[
                        if (invite.storeName.isNotEmpty)
                          Divider(
                            height: 16,
                            color: isDark
                                ? Colors.white10
                                : Colors.grey.shade200,
                          ),
                        _buildDetailRow(
                          icon: Icons.person_outline_rounded,
                          label: 'Invited by',
                          value: invite.invitedBy,
                          isDark: isDark,
                        ),
                      ],
                      Divider(
                        height: 16,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      _buildDetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Sent on',
                        value: dateStr,
                        isDark: isDark,
                      ),
                      Divider(
                        height: 16,
                        color: isDark ? Colors.white10 : Colors.grey.shade200,
                      ),
                      _buildDetailRow(
                        icon: Icons.security_rounded,
                        label: 'Access level',
                        value: roleConfig.description,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action buttons row
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Resend'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Invitation reminder sent to ${invite.email}',
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Revoke'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () => _confirmRevokeInvite(invite),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isDark ? Colors.white38 : Colors.grey.shade500,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.grey.shade500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()} month${(diff.inDays / 30).floor() > 1 ? 's' : ''} ago';
    } else if (diff.inDays > 0) {
      return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes} min ago';
    } else {
      return 'Just now';
    }
  }

  ({Color color, IconData icon, String description}) _getRoleConfig(
    String role,
  ) {
    switch (role) {
      case 'Manager':
        return (
          color: AppColors.primary,
          icon: Icons.admin_panel_settings_rounded,
          description: 'Full access to manage store, orders, products & staff',
        );
      case 'Editor':
        return (
          color: Colors.teal,
          icon: Icons.edit_rounded,
          description: 'Can manage inventory, orders & product listings',
        );
      case 'Viewer':
        return (
          color: Colors.blueGrey,
          icon: Icons.visibility_rounded,
          description: 'Read-only access to view store data & analytics',
        );
      default:
        return (
          color: Colors.orange,
          icon: Icons.person_rounded,
          description: 'Store team member',
        );
    }
  }

  void _confirmRemoveStaff(AppUser member) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Staff Member'),
          content: Text(
            'Are you sure you want to remove ${member.displayName} (${member.email}) from your storefront? They will lose all access immediately.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await ref
                    .read(sellerStaffControllerProvider.notifier)
                    .removeStaff(member.uid);

                if (mounted) {
                  result.fold(
                    (err) => ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: AppColors.error,
                      ),
                    ),
                    (_) => ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Staff member removed.')),
                    ),
                  );
                }
              },
              child: const Text(
                'Remove',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  void _confirmRevokeInvite(StaffInvitation invite) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Revoke Invitation'),
          content: Text(
            'Are you sure you want to revoke the invitation for ${invite.email}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final result = await ref
                    .read(sellerStaffControllerProvider.notifier)
                    .revokeInvitation(invite.id);

                if (mounted) {
                  result.fold(
                    (err) => ScaffoldMessenger.of(this.context).showSnackBar(
                      SnackBar(
                        content: Text(err),
                        backgroundColor: AppColors.error,
                      ),
                    ),
                    (_) => ScaffoldMessenger.of(this.context).showSnackBar(
                      const SnackBar(content: Text('Invitation revoked.')),
                    ),
                  );
                }
              },
              child: const Text(
                'Revoke',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

void _showManagePermissionsSheet(
  BuildContext context,
  WidgetRef ref,
  AppUser staff,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ManagePermissionsSheet(staff: staff),
  );
}

class _ManagePermissionsSheet extends ConsumerStatefulWidget {
  final AppUser staff;

  const _ManagePermissionsSheet({required this.staff});

  @override
  ConsumerState<_ManagePermissionsSheet> createState() =>
      _ManagePermissionsSheetState();
}

class _ManagePermissionsSheetState
    extends ConsumerState<_ManagePermissionsSheet> {
  late Set<StaffPermission> _selectedPermissions;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPermissions();
  }

  Future<void> _loadPermissions() async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final store = ref.read(sellerControllerProvider).value;

    if (store == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await firestore
          .collection('stores')
          .doc(store.id)
          .collection('staff')
          .doc(widget.staff.uid)
          .get();

      if (doc.exists) {
        final data = doc.data();
        final permList = data?['permissions'] as List<dynamic>? ?? [];
        if (mounted) {
          setState(() {
            _selectedPermissions = Set.from(
              StaffPermissions.fromList(permList).values,
            );
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _selectedPermissions = Set.from(StaffPermissions.all().values);
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _selectedPermissions = {};
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _savePermissions() async {
    final perms = StaffPermissions.fromList(
      _selectedPermissions.map((e) => e.name).toList(),
    );

    final result = await ref
        .read(sellerStaffControllerProvider.notifier)
        .updateStaffPermissions(widget.staff.uid, perms);

    if (mounted) {
      result.fold(
        (error) => ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppColors.error),
        ),
        (_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permissions updated successfully'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Manage Permissions',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          widget.staff.displayName,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Access Rights',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.lightTextSecondary,
                                    ),
                              ),
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    if (_selectedPermissions.length ==
                                        StaffPermission.values.length) {
                                      _selectedPermissions.clear();
                                      _selectedPermissions.add(
                                        StaffPermission.dashboard,
                                      ); // Keep dashboard at least
                                    } else {
                                      _selectedPermissions = Set.from(
                                        StaffPermission.values,
                                      );
                                    }
                                  });
                                },
                                child: Text(
                                  _selectedPermissions.length ==
                                          StaffPermission.values.length
                                      ? 'Deselect All'
                                      : 'Select All',
                                ),
                              ),
                            ],
                          ),
                        ),
                        ...StaffPermission.values.map((permission) {
                          final isDashboard =
                              permission == StaffPermission.dashboard;
                          final isSelected = _selectedPermissions.contains(
                            permission,
                          );

                          return CheckboxListTile(
                            value: isSelected,
                            onChanged: isDashboard
                                ? null // Dashboard is always required
                                : (value) {
                                    setState(() {
                                      if (value == true) {
                                        _selectedPermissions.add(permission);
                                      } else {
                                        _selectedPermissions.remove(permission);
                                      }
                                    });
                                  },
                            title: Row(
                              children: [
                                Icon(
                                  StaffPermissions.icon(permission),
                                  size: 20,
                                  color: isSelected || isDashboard
                                      ? (isDark ? Colors.white : Colors.black)
                                      : AppColors.lightTextSecondary,
                                ),
                                const SizedBox(width: 12),
                                Text(StaffPermissions.label(permission)),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(left: 32, top: 4),
                              child: Text(
                                StaffPermissions.description(permission),
                              ),
                            ),
                            activeColor: AppColors.primary,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                          );
                        }),
                      ],
                    ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : AppColors.border,
                  ),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _savePermissions,
                    child: const Text('Save Permissions'),
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
