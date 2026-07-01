import 'package:flutter/material.dart';

enum StaffPermission {
  dashboard,    // View dashboard overview & stats
  analytics,    // View analytics & reports
  inventory,    // Manage products / inventory
  orders,       // View & manage orders
  customers,    // View customer data
  finances,     // View financial data & payouts
  messages,     // Access chat / messages
  storeProfile, // Edit store profile
  settings,     // Access store settings
  staff,        // Manage staff (invite/remove/permissions)
}

class StaffPermissions {
  final Set<StaffPermission> _permissions;

  const StaffPermissions._(this._permissions);

  /// Owner / seller gets all permissions.
  factory StaffPermissions.all() =>
      StaffPermissions._(Set.from(StaffPermission.values));

  /// Empty permission set (no access).
  factory StaffPermissions.none() => const StaffPermissions._({});

  /// Parse from Firestore list of strings.
  factory StaffPermissions.fromList(List<dynamic> list) {
    final perms = <StaffPermission>{};
    for (final item in list) {
      final name = item.toString();
      try {
        perms.add(StaffPermission.values.byName(name));
      } catch (_) {
        // Skip unknown permission names for forward compatibility
      }
    }
    return StaffPermissions._(perms);
  }

  /// Default permissions for a given role string.
  factory StaffPermissions.defaultForRole(String role) {
    switch (role) {
      case 'storeManager':
        return StaffPermissions._(Set.from(StaffPermission.values));
      case 'storeEditor':
        return StaffPermissions._({
          StaffPermission.dashboard,
          StaffPermission.inventory,
          StaffPermission.orders,
          StaffPermission.customers,
          StaffPermission.messages,
        });
      case 'storeViewer':
        return StaffPermissions._({
          StaffPermission.dashboard,
          StaffPermission.analytics,
        });
      default:
        return StaffPermissions._({StaffPermission.dashboard});
    }
  }

  /// Serialize to a list of strings for Firestore.
  List<String> toList() =>
      _permissions.map((p) => p.name).toList()..sort();

  /// Check if a specific permission is granted.
  bool has(StaffPermission permission) => _permissions.contains(permission);

  /// Check if any of the given permissions are granted.
  bool hasAny(Set<StaffPermission> permissions) =>
      _permissions.intersection(permissions).isNotEmpty;

  /// Total number of permissions granted.
  int get count => _permissions.length;

  /// Whether all permissions are granted.
  bool get isAll => _permissions.length == StaffPermission.values.length;

  /// The raw set (unmodifiable).
  Set<StaffPermission> get values => Set.unmodifiable(_permissions);

  /// Human-readable label for a permission.
  static String label(StaffPermission p) {
    switch (p) {
      case StaffPermission.dashboard:
        return 'Dashboard';
      case StaffPermission.analytics:
        return 'Analytics & Reports';
      case StaffPermission.inventory:
        return 'Inventory & Products';
      case StaffPermission.orders:
        return 'Orders Management';
      case StaffPermission.customers:
        return 'Customer Data';
      case StaffPermission.finances:
        return 'Finances & Payouts';
      case StaffPermission.messages:
        return 'Messages & Chat';
      case StaffPermission.storeProfile:
        return 'Store Profile';
      case StaffPermission.settings:
        return 'Store Settings';
      case StaffPermission.staff:
        return 'Staff Management';
    }
  }

  /// Short description for a permission.
  static String description(StaffPermission p) {
    switch (p) {
      case StaffPermission.dashboard:
        return 'View store overview, stats, and key metrics';
      case StaffPermission.analytics:
        return 'Access detailed analytics and performance reports';
      case StaffPermission.inventory:
        return 'Add, edit, and manage products and stock';
      case StaffPermission.orders:
        return 'View, process, and manage customer orders';
      case StaffPermission.customers:
        return 'View customer information and purchase history';
      case StaffPermission.finances:
        return 'Access revenue, payouts, and financial data';
      case StaffPermission.messages:
        return 'Read and respond to customer messages';
      case StaffPermission.storeProfile:
        return 'Edit store name, description, and branding';
      case StaffPermission.settings:
        return 'Configure store settings and preferences';
      case StaffPermission.staff:
        return 'Invite, remove, and manage staff permissions';
    }
  }

  /// Icon for a permission.
  static IconData icon(StaffPermission p) {
    switch (p) {
      case StaffPermission.dashboard:
        return Icons.dashboard_rounded;
      case StaffPermission.analytics:
        return Icons.analytics_rounded;
      case StaffPermission.inventory:
        return Icons.inventory_2_rounded;
      case StaffPermission.orders:
        return Icons.shopping_bag_rounded;
      case StaffPermission.customers:
        return Icons.people_rounded;
      case StaffPermission.finances:
        return Icons.account_balance_wallet_rounded;
      case StaffPermission.messages:
        return Icons.forum_rounded;
      case StaffPermission.storeProfile:
        return Icons.store_rounded;
      case StaffPermission.settings:
        return Icons.settings_rounded;
      case StaffPermission.staff:
        return Icons.people_alt_rounded;
    }
  }
}
