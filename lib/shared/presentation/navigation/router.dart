import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:google_fonts/google_fonts.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/screens/admin_category_requests_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_moderation_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_products_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_sellers_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_store_approvals_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_stores_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_audit_logs_screen.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/admin/domain/entities/platform_config.dart';
import 'package:ecom/features/admin/presentation/controllers/admin_controller.dart';
import 'package:ecom/shared/presentation/widgets/maintenance_screen.dart';
import 'package:ecom/features/auth/presentation/screens/address_screen.dart';
import 'package:ecom/features/auth/presentation/screens/landing_screen.dart';
import 'package:ecom/features/auth/presentation/screens/login_screen.dart';
import 'package:ecom/features/auth/presentation/screens/signup_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/about_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/account_settings_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/buyer_orders_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/cart_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/checkout_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/help_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/privacy_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/product_detail_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/products_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/profile_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/wishlist_screen.dart';

import 'package:ecom/features/marketplace/presentation/screens/chat_screen.dart';
import 'package:ecom/features/marketplace/presentation/screens/notification_screen.dart';
import 'package:ecom/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:ecom/features/seller/presentation/screens/add_product_screen.dart';
import 'package:ecom/features/seller/presentation/screens/edit_product_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_analytics_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_dashboard_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_inventory_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_orders_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_settings_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_store_profile_screen.dart';
import 'package:ecom/features/seller/presentation/widgets/seller_navigation.dart';
import 'package:ecom/features/seller_application/presentation/screens/seller_application_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/domain/entities/app_user.dart';
import '../../../features/seller/presentation/screens/seller_customers_screen.dart';
import '../../../features/seller/presentation/screens/seller_finances_screen.dart';
import '../../../features/seller/presentation/screens/seller_returns_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNav',
);

abstract class AppRoutes {
  // Auth
  static const root = '/';
  static const landing = '/landing';
  static const login = '/login';
  static const signup = '/signup';

  // Buyer shell tabs
  static const buyerHome = '/buyer/home';
  static const buyerProducts = '/buyer/products';
  static const buyerProfile = '/buyer/profile';
  static const buyerMenu = '/buyer/menu';

  // Buyer push screens
  static const buyerWishlist = '/buyer/wishlist';
  static const buyerCart = '/buyer/cart';
  static const buyerCheckout = '/buyer/checkout';
  static const buyerOrders = '/buyer/orders';
  static const buyerOrderDetail = '/buyer/orders/:orderId';
  static const buyerAddresses = '/buyer/addresses';
  static const buyerNotifications = '/buyer/notifications';
  static const notificationPreferences = '/buyer/notification-preferences';
  static const buyerAccountSettings = '/buyer/account-settings';
  static const buyerHelp = '/buyer/help';
  static const buyerPrivacy = '/buyer/privacy';
  static const buyerAbout = '/buyer/about';
  static const productDetail = '/buyer/home/product/:productId';
  static const chat = '/chat/:chatId';

  // Seller shell tabs
  static const sellerDashboard = '/seller/dashboard';
  static const sellerInventory = '/seller/inventory';
  static const sellerOrders = '/seller/orders';
  static const sellerOrderDetail = '/seller/orders/:orderId';
  static const sellerAnalytics = '/seller/analytics';
  static const sellerStoreProfile = '/seller/store-profile';
  static const sellerCustomers = '/seller/customers';
  static const sellerSettings = '/seller/settings';
  static const sellerFinances = '/seller/finances';

  // Seller push screens
  static const addProduct = '/seller/inventory/add';
  static const editProduct = '/seller/inventory/edit/:productId';
  static const sellerNotifications = '/seller/notifications';
  static const sellerReturns = '/seller/returns';

  // Seller application
  static const sellerApply = '/seller/apply';

  // Admin
  static const adminNotifications = '/admin/notifications';
  static const adminPanel = '/admin/control-panel';
  static const adminUsers = '/admin/users';
  static const adminStoreApprovals = '/admin/store-approvals';
  static const adminStores = '/admin/stores';
  static const adminSellers = '/admin/sellers';
  static const adminProducts = '/admin/products';
  static const adminOrders = '/admin/orders';
  static const adminReports = '/admin/reports';
  static const adminSettings = '/admin/settings';
  static const adminAuditLogs = '/admin/audit-logs';
  static const adminCategoryRequests = '/admin/category-requests';
}

/// Returns the canonical landing route for a signed-in user, based on role.
/// Admin/superAdmin > seller > buyer, mirroring the priority used
/// throughout the redirect logic below.
String _homeFor(AppUser user) {
  if (user.roles.contains(UserRole.superAdmin) ||
      user.roles.contains(UserRole.admin)) {
    return AppRoutes.adminPanel;
  }
  if (user.roles.contains(UserRole.seller)) {
    return AppRoutes.sellerDashboard;
  }
  return AppRoutes.buyerHome;
}

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRedirectNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,

    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.watch(currentUserProfileProvider);
      final loc = state.matchedLocation;

      final isAuthRoute =
          loc == AppRoutes.landing ||
          loc == AppRoutes.login ||
          loc == AppRoutes.signup;

      // ── 1. Auth state still resolving ─────────────────────────────────
      // Firebase Auth + the Firestore role lookup can take a beat to
      // resolve (especially on a cold web load / typed-in deep link).
      // NEVER let the originally-requested route render during that
      // window — that's what causes a protected screen to flash before
      // snapping to the correct one. Funnel everything through the root
      // route (a loading screen) instead, remembering where the user was
      // actually headed so we can send them there once we know who they
      // are.
      if (authState.isLoading) {
        if (loc == AppRoutes.root) return null;
        final target = Uri.encodeComponent(state.uri.toString());
        return '${AppRoutes.root}?redirect=$target';
      }

      // ── 2. Auth stream errored ──────────────────────────────────────────
      // Treat an error the same as "signed out" rather than rendering
      // whatever was requested.
      if (authState.hasError) {
        return isAuthRoute ? null : AppRoutes.login;
      }

      final user = authState.value;

      // ── Maintenance Mode Check ──────────────────────────────────────
      final configAsync = ref.watch(platformConfigProvider);
      final platformConfig = configAsync.value;
      if (platformConfig != null && platformConfig.maintenanceModeActive) {
        final isAdmin = user != null && (
            user.roles.contains(UserRole.admin) ||
            user.roles.contains(UserRole.superAdmin)
        );
        if (!isAdmin && loc != '/maintenance' && loc != AppRoutes.login) {
          return '/maintenance';
        }
      } else {
        if (loc == '/maintenance') {
          return user == null ? AppRoutes.landing : _homeFor(user);
        }
      }

      // ── 3. Resolve the pending deep link now that auth is known ────────
      if (loc == AppRoutes.root) {
        final redirectTo = state.uri.queryParameters['redirect'];
        if (redirectTo != null && redirectTo.isNotEmpty) return redirectTo;
        if (user == null) return AppRoutes.landing;
        return _homeFor(user);
      }

      final isProtectedPath =
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
      final isSeller = user.roles.contains(UserRole.seller);

      // ── 6. Seller application flow ───────────────────────────────────────
      if (loc == AppRoutes.sellerApply) {
        if (isSeller) return AppRoutes.sellerDashboard;
        if (isAdmin) return AppRoutes.adminPanel;
        return null; // plain buyers may apply to become a seller
      }

      // ── 7. Shared, role-agnostic feature ─────────────────────────────────
      // Chat is used by both buyers and sellers to talk to each other, so
      // it's intentionally exempt from panel isolation.
      if (loc.startsWith('/chat')) return null;
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
      } else if (isAdminPath || isSellerPath) {
        return AppRoutes.buyerHome;
      }

      // ── 9. Already-authenticated user hitting an auth screen ─────────────
      if (isAuthRoute) return _homeFor(user);

      return null;
    },

    routes: [
      GoRoute(
        path: '/maintenance',
        builder: (context, state) => const MaintenanceScreen(),
      ),
      // ── Auth ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const _AuthGateScreen(),
      ),
      GoRoute(
        path: AppRoutes.landing,
        builder: (context, state) => const LandingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),

      // ── Seller Application ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.sellerApply,
        builder: (context, state) => const SellerApplicationScreen(),
      ),

      // ── Buyer push routes ─────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.buyerWishlist,
        builder: (context, state) => const WishlistScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerCart,
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerCheckout,
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerOrders,
        builder: (context, state) => const BuyerOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerOrderDetail,
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRoutes.buyerAddresses,
        builder: (context, state) => const AddressScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerNotifications,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerNotifications,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminNotifications,
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerAccountSettings,
        builder: (context, state) => const AccountSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerHelp,
        builder: (context, state) => const HelpScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerPrivacy,
        builder: (context, state) => const PrivacyScreen(),
      ),
      GoRoute(
        path: AppRoutes.buyerAbout,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.productDetail,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['productId']!),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) =>
            ChatScreen(chatId: state.pathParameters['chatId']!),
      ),

      // ── Buyer shell ───────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _BuyerShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.buyerHome,
                builder: (context, state) => const BuyerHomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.buyerProducts,
                builder: (context, state) {
                  final search = state.uri.queryParameters['search'];
                  return ProductsScreen(initialSearch: search);
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.buyerProfile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Seller push routes ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.sellerStoreProfile,
        builder: (context, state) => const SellerStoreProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerCustomers,
        builder: (context, state) => const SellerCustomersScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerFinances,
        builder: (context, state) => const SellerFinancesScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerReturns,
        builder: (context, state) => const SellerReturnsScreen(),
      ),
      GoRoute(
        path: AppRoutes.sellerOrderDetail,
        builder: (context, state) =>
            OrderDetailScreen(orderId: state.pathParameters['orderId']!),
      ),
      GoRoute(
        path: AppRoutes.sellerSettings,
        builder: (context, state) => const SellerSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.addProduct,
        builder: (context, state) => const AddProductScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProduct,
        builder: (context, state) =>
            EditProductScreen(productId: state.pathParameters['productId']!),
      ),

      // ── Seller shell ──────────────────────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _SellerShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sellerDashboard,
                builder: (context, state) => const SellerDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sellerInventory,
                builder: (context, state) => const SellerInventoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sellerOrders,
                builder: (context, state) => const SellerOrdersScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.sellerAnalytics,
                builder: (context, state) => const SellerAnalyticsScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Admin ─────────────────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.adminPanel,
        builder: (context, state) => const AdminModerationScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminUsers,
        builder: (context, state) => const AdminUsersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStoreApprovals,
        builder: (context, state) => const AdminStoreApprovalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminStores,
        builder: (context, state) => const AdminStoresScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSellers,
        builder: (context, state) => const AdminSellersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminProducts,
        builder: (context, state) => const AdminProductsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminOrders,
        builder: (context, state) => const AdminOrdersScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminAuditLogs,
        builder: (context, state) => const AdminAuditLogsScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminCategoryRequests,
        builder: (context, state) => const AdminCategoryRequestsScreen(),
      ),
    ],
  );
});

class _BuyerShell extends ConsumerStatefulWidget {
  const _BuyerShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<_BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends ConsumerState<_BuyerShell> {
  DateTime? _lastBackPress;
  static const _homeIndex = 0;

  Future<bool> _onWillPop() async {
    final shell = widget.navigationShell;

    if (shell.currentIndex != _homeIndex) {
      shell.goBranch(_homeIndex);
      return false;
    }

    final navigator = rootNavigatorKey.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;

    final navItems = [
      _NavItemData(
        icon: Icons.home_rounded,
        label: 'Home',
      ),
      _NavItemData(
        icon: Icons.grid_view_rounded,
        label: 'Products',
      ),
      _NavItemData(
        icon: Icons.person_rounded,
        label: 'Profile',
      ),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        extendBody: true,
        body: widget.navigationShell,
        bottomNavigationBar: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.80),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.6),
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                    blurRadius: 24,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                bottom: true,
                child: SizedBox(
                  height: 68,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(navItems.length, (index) {
                      final item = navItems[index];
                      final isSelected = currentIndex == index;
                      final unselectedColor =
                          isDark ? Colors.white54 : Colors.black45;

                      return GestureDetector(
                        onTap: () {
                          widget.navigationShell.goBranch(
                            index,
                            initialLocation: index == currentIndex,
                          );
                        },
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: EdgeInsets.symmetric(
                            horizontal: isSelected ? 16 : 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? const LinearGradient(
                                    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                                  )
                                : null,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? Colors.white
                                    : unselectedColor,
                                size: 24,
                              ),
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Text(
                                  item.label,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  _NavItemData({
    required this.icon,
    required this.label,
  });
}

class _SellerShell extends StatelessWidget {
  const _SellerShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1024;

    return Scaffold(
      key: sellerShellScaffoldKey,
      drawer: isDesktop ? null : const SellerDrawer(),
      body: Row(
        children: [
          if (isDesktop) const SellerSidebar(),
          Expanded(child: ClipRect(child: navigationShell)),
        ],
      ),
    );
  }
}

class _AuthRedirectNotifier extends ChangeNotifier {
  _AuthRedirectNotifier(Ref ref) {
    ref.listen<AsyncValue<AppUser?>>(currentUserProfileProvider, (
      previous,
      next,
    ) {
      notifyListeners();
    });
    ref.listen<AsyncValue<PlatformConfig>>(platformConfigProvider, (
      previous,
      next,
    ) {
      notifyListeners();
    });
  }
}

/// Shown at the root route ('/') while Firebase Auth and the Firestore
/// role document are still resolving, and very briefly while the
/// redirect logic figures out where an already-known user belongs. No
/// protected screen ever renders during this window — see the
/// `redirect` callback above.
///
/// On a real device with no network of its own (e.g. it was only online
/// because it was tethered to a dev machine during `flutter run`, and
/// got disconnected), [currentUserProfileProvider] can sit in
/// `AsyncLoading` indefinitely — Firebase Auth's local session restore
/// is fast, but the chained Firestore `.snapshots()` listener for the
/// user's role document has no cached copy to fall back to and no
/// network to fetch one from. Rather than spinning forever, this screen
/// surfaces a retry affordance after a short grace period.
class _AuthGateScreen extends ConsumerStatefulWidget {
  const _AuthGateScreen();

  @override
  ConsumerState<_AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends ConsumerState<_AuthGateScreen> {
  static const _slowThreshold = Duration(seconds: 7);
  Timer? _slowTimer;
  bool _isSlow = false;

  @override
  void initState() {
    super.initState();
    _armSlowTimer();
  }

  void _armSlowTimer() {
    _slowTimer?.cancel();
    _slowTimer = Timer(_slowThreshold, () {
      if (mounted) setState(() => _isSlow = true);
    });
  }

  void _retry() {
    setState(() => _isSlow = false);
    // Force both the auth-state stream and the chained Firestore listener
    // to re-subscribe from scratch instead of sitting on a dead stream.
    ref.invalidate(firebaseAuthStateProvider);
    ref.invalidate(currentUserProfileProvider);
    _armSlowTimer();
  }

  @override
  void dispose() {
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ecom',
              style: TextStyle(
                color: AppColors.darkAccentViolet,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.darkAccentViolet,
                ),
              ),
            ),
            if (_isSlow) ...[
              const SizedBox(height: 28),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "This is taking longer than usual.\nCheck your internet connection.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.darkTextSecond,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: _retry,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkAccentViolet,
                  side: const BorderSide(color: AppColors.darkAccentViolet),
                ),
                child: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
