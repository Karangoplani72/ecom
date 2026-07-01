import re

with open('lib/shared/presentation/navigation/router.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add imports
imports = '''import 'package:ecom/features/staff/presentation/screens/staff_dashboard_screen.dart';
import 'package:ecom/features/staff/presentation/widgets/staff_navigation.dart';
'''
content = content.replace("import 'package:ecom/features/seller/presentation/screens/seller_dashboard_screen.dart';", imports + "import 'package:ecom/features/seller/presentation/screens/seller_dashboard_screen.dart';")

# 2. Add AppRoutes
app_routes = '''  // Staff shell tabs
  static const staffDashboard = '/staff/dashboard';
  static const staffInventory = '/staff/inventory';
  static const staffOrders = '/staff/orders';
  static const staffAnalytics = '/staff/analytics';
  static const staffStoreProfile = '/staff/store-profile';
  static const staffCustomers = '/staff/customers';
  static const staffSettings = '/staff/settings';
  static const staffFinances = '/staff/finances';
  static const staffStaff = '/staff/staff';

  // Seller push screens'''
content = content.replace('  // Seller push screens', app_routes)

# 3. Update _homeFor
home_for_old = '''String _homeFor(AppUser user) {
  if (user.roles.contains(UserRole.superAdmin) ||
      user.roles.contains(UserRole.admin)) {
    return AppRoutes.adminPanel;
  }
  if (user.roles.contains(UserRole.seller) ||
      user.roles.contains(UserRole.storeManager)) {
    return AppRoutes.sellerDashboard;
  }
  return AppRoutes.buyerHome;
}'''

home_for_new = '''String _homeFor(AppUser user) {
  if (user.roles.contains(UserRole.superAdmin) ||
      user.roles.contains(UserRole.admin)) {
    return AppRoutes.adminPanel;
  }
  if (user.roles.contains(UserRole.seller)) {
    return AppRoutes.sellerDashboard;
  }
  if (user.roles.contains(UserRole.storeManager)) {
    return AppRoutes.staffDashboard;
  }
  return AppRoutes.buyerHome;
}'''
content = content.replace(home_for_old, home_for_new)

# 4. Update redirect logic
redirect_old = '''      final isProtectedPath =
          loc.startsWith('/seller') ||
          loc.startsWith('/admin') ||
          loc == AppRoutes.buyerOrders ||
          loc == AppRoutes.buyerCheckout ||
          loc == AppRoutes.buyerNotifications ||
          loc == AppRoutes.notificationPreferences ||
          loc == AppRoutes.buyerAddresses;

      // ── 4. Signed out ────────────────────────────────────────────────────
      if (user == null) {
        if (isProtectedPath) return AppRoutes.login;
        return null; // public/guest browsing of the buyer storefront
      }

      // ── 5. Suspended account ─────────────────────────────────────────────
      if (!user.isActive) {
        return '${AppRoutes.login}?error=account_suspended';
      }

      final isAdmin =
          user.roles.contains(UserRole.admin) ||
          user.roles.contains(UserRole.superAdmin);
      final isSeller = user.roles.contains(UserRole.seller) ||
          user.roles.contains(UserRole.storeManager);

      // ── 6. Seller application flow ───────────────────────────────────────
      if (loc == AppRoutes.sellerApply) {
        if (isSeller) return AppRoutes.sellerDashboard;
        if (isAdmin) return AppRoutes.adminPanel;
        return null; // plain buyers may apply to become a seller
      }

      // ── 7. Shared, role-agnostic feature ─────────────────────────────────
      // Chat is used by both buyers and sellers to talk to each other, so
      // it's intentionally exempt from panel isolation.
      if (loc.startsWith('/chat')) {
        if (isSeller && !user.roles.contains(UserRole.seller) && user.roles.contains(UserRole.storeManager)) {
          final permsAsync = ref.read(staffPermissionsProvider);
          final perms = permsAsync.value;
          if (perms != null && !perms.has(StaffPermission.messages)) {
            return AppRoutes.sellerDashboard;
          }
        }
        return null;
      }
      if (loc == AppRoutes.buyerNotifications) return null;
      if (loc == AppRoutes.notificationPreferences) return null;

      // ── 8. Strict panel isolation ─────────────────────────────────────────
      // Every role is confined to its own panel — no cross-access, even
      // for admins/sellers wandering into the buyer storefront.
      final isAdminPath = loc.startsWith('/admin');
      final isSellerPath = loc.startsWith('/seller');

      if (isAdmin) {
        if (!isAdminPath) return AppRoutes.adminPanel;
      } else if (isSeller) {
        if (!isSellerPath) return AppRoutes.sellerDashboard;
        
        // Store Manager Permission Guards
        if (user.roles.contains(UserRole.storeManager) && !user.roles.contains(UserRole.seller)) {
          final permsAsync = ref.read(staffPermissionsProvider);
          final perms = permsAsync.value;
          
          if (perms != null) {
            if (loc.startsWith('/seller/inventory') && !perms.has(StaffPermission.inventory)) return AppRoutes.sellerDashboard;
            if (loc.startsWith('/seller/orders') && !perms.has(StaffPermission.orders)) return AppRoutes.sellerDashboard;
            if (loc.startsWith('/seller/analytics') && !perms.has(StaffPermission.analytics)) return AppRoutes.sellerDashboard;
            if (loc.startsWith('/seller/customers') && !perms.has(StaffPermission.customers)) return AppRoutes.sellerDashboard;
            if (loc.startsWith('/seller/finances') && !perms.has(StaffPermission.finances)) return AppRoutes.sellerDashboard;
            if (loc.startsWith('/seller/store-profile') && !perms.has(StaffPermission.storeProfile)) return AppRoutes.sellerDashboard;
            if (loc.startsWith('/seller/settings') && !perms.has(StaffPermission.settings)) return AppRoutes.sellerDashboard;
            if (loc.startsWith('/seller/staff') && !perms.has(StaffPermission.staff)) return AppRoutes.sellerDashboard;
            if (loc.startsWith('/seller/returns') && !perms.has(StaffPermission.orders)) return AppRoutes.sellerDashboard;
          }
        }
      } else if (isAdminPath || isSellerPath) {
        return AppRoutes.buyerHome;
      }'''

redirect_new = '''      final isProtectedPath =
          loc.startsWith('/seller') ||
          loc.startsWith('/admin') ||
          loc.startsWith('/staff') ||
          loc == AppRoutes.buyerOrders ||
          loc == AppRoutes.buyerCheckout ||
          loc == AppRoutes.buyerNotifications ||
          loc == AppRoutes.notificationPreferences ||
          loc == AppRoutes.buyerAddresses;

      // ── 4. Signed out ────────────────────────────────────────────────────
      if (user == null) {
        if (isProtectedPath) return AppRoutes.login;
        return null; // public/guest browsing of the buyer storefront
      }

      // ── 5. Suspended account ─────────────────────────────────────────────
      if (!user.isActive) {
        return '${AppRoutes.login}?error=account_suspended';
      }

      final isAdmin =
          user.roles.contains(UserRole.admin) ||
          user.roles.contains(UserRole.superAdmin);
      final isSeller = user.roles.contains(UserRole.seller);
      final isStaff = user.roles.contains(UserRole.storeManager) && !isSeller;

      // ── 6. Seller application flow ───────────────────────────────────────
      if (loc == AppRoutes.sellerApply) {
        if (isSeller) return AppRoutes.sellerDashboard;
        if (isStaff) return AppRoutes.staffDashboard;
        if (isAdmin) return AppRoutes.adminPanel;
        return null; // plain buyers may apply to become a seller
      }

      // ── 7. Shared, role-agnostic feature ─────────────────────────────────
      // Chat is used by both buyers and sellers to talk to each other, so
      // it's intentionally exempt from panel isolation.
      if (loc.startsWith('/chat')) {
        if (isStaff) {
          final permsAsync = ref.read(staffPermissionsProvider);
          final perms = permsAsync.value;
          if (perms != null && !perms.has(StaffPermission.messages)) {
            return AppRoutes.staffDashboard;
          }
        }
        return null;
      }
      if (loc == AppRoutes.buyerNotifications) return null;
      if (loc == AppRoutes.notificationPreferences) return null;

      // ── 8. Strict panel isolation ─────────────────────────────────────────
      // Every role is confined to its own panel — no cross-access, even
      // for admins/sellers wandering into the buyer storefront.
      final isAdminPath = loc.startsWith('/admin');
      final isSellerPath = loc.startsWith('/seller');
      final isStaffPath = loc.startsWith('/staff');

      if (isAdmin) {
        if (!isAdminPath) return AppRoutes.adminPanel;
      } else if (isSeller) {
        if (!isSellerPath) return AppRoutes.sellerDashboard;
      } else if (isStaff) {
        if (!isStaffPath) return AppRoutes.staffDashboard;
        
        // Store Manager Permission Guards
        final permsAsync = ref.read(staffPermissionsProvider);
        final perms = permsAsync.value;
        
        if (perms != null) {
          if (loc.startsWith('/staff/inventory') && !perms.has(StaffPermission.inventory)) return AppRoutes.staffDashboard;
          if (loc.startsWith('/staff/orders') && !perms.has(StaffPermission.orders)) return AppRoutes.staffDashboard;
          if (loc.startsWith('/staff/analytics') && !perms.has(StaffPermission.analytics)) return AppRoutes.staffDashboard;
          if (loc.startsWith('/staff/customers') && !perms.has(StaffPermission.customers)) return AppRoutes.staffDashboard;
          if (loc.startsWith('/staff/finances') && !perms.has(StaffPermission.finances)) return AppRoutes.staffDashboard;
          if (loc.startsWith('/staff/store-profile') && !perms.has(StaffPermission.storeProfile)) return AppRoutes.staffDashboard;
          if (loc.startsWith('/staff/settings') && !perms.has(StaffPermission.settings)) return AppRoutes.staffDashboard;
          if (loc.startsWith('/staff/staff') && !perms.has(StaffPermission.staff)) return AppRoutes.staffDashboard;
          if (loc.startsWith('/staff/returns') && !perms.has(StaffPermission.orders)) return AppRoutes.staffDashboard;
        }
      } else if (isAdminPath || isSellerPath || isStaffPath) {
        return AppRoutes.buyerHome;
      }'''
content = content.replace(redirect_old, redirect_new)

# 5. Add Staff Shell Routes
staff_shell = '''      // ── Staff shell ──────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StaffNavigation(child: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'staffDashboard'),
            routes: [
              GoRoute(
                path: AppRoutes.staffDashboard,
                builder: (context, state) => const StaffDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'staffInventory'),
            routes: [
              GoRoute(
                path: AppRoutes.staffInventory,
                builder: (context, state) => const SellerInventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'staffOrders'),
            routes: [
              GoRoute(
                path: AppRoutes.staffOrders,
                builder: (context, state) => const SellerOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: GlobalKey<NavigatorState>(debugLabel: 'staffAnalytics'),
            routes: [
              GoRoute(
                path: AppRoutes.staffAnalytics,
                builder: (context, state) => const SellerAnalyticsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.staffCustomers,
        builder: (context, state) => const SellerCustomersScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffStoreProfile,
        builder: (context, state) => const SellerStoreProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffSettings,
        builder: (context, state) => const SellerSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffFinances,
        builder: (context, state) => const SellerFinancesScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffStaff,
        builder: (context, state) => const SellerStaffScreen(),
      ),
      // ── Admin ─────────────────────────────────────────────────────────────'''
content = content.replace('      // ── Admin ─────────────────────────────────────────────────────────────', staff_shell)

with open('lib/shared/presentation/navigation/router.dart', 'w', encoding='utf-8') as f:
    f.write(content)
