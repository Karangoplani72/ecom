// lib/shared/presentation/navigation/router.dart
//
// Industry-standard GoRouter setup with:
//  1. Proper history stack (StatefulShellRoute with persistent navigation)
//  2. Android back button navigates history, never exits mid-app
//  3. Double-tap back to exit only from home screen
//  4. Web: URL reflects current page so browser refresh reloads that page

import 'dart:async';

import 'package:ecom/features/admin/presentation/screens/admin_moderation_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_reports_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_sellers_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_settings_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_store_approvals_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_stores_screen.dart';
import 'package:ecom/features/admin/presentation/screens/admin_users_screen.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/auth/presentation/screens/address_screen.dart';
import 'package:ecom/features/auth/presentation/screens/landing_screen.dart';
import 'package:ecom/features/auth/presentation/screens/login_screen.dart';
import 'package:ecom/features/auth/presentation/screens/signup_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/buyer_orders_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/cart_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/checkout_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/menu_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/product_detail_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/products_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/profile_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/wishlist_screen.dart';
import 'package:ecom/features/marketplace/presentation/screens/chat_screen.dart';
import 'package:ecom/features/orders/presentation/screens/order_detail_screen.dart';
import 'package:ecom/features/seller/presentation/screens/add_product_screen.dart';
import 'package:ecom/features/seller/presentation/screens/edit_product_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_analytics_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_dashboard_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_inventory_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_orders_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_settings_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_store_profile_screen.dart';
import 'package:ecom/features/seller_application/presentation/screens/seller_application_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../features/auth/domain/entities/app_user.dart';
import '../../../features/seller/presentation/screens/seller_customers_screen.dart';
import '../../../features/seller/presentation/screens/seller_finances_screen.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'rootNav',
);

// ---------------------------------------------------------------------------
// Route path constants — one source of truth, no magic strings
// ---------------------------------------------------------------------------

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

  // Buyer modal / push screens (outside the tab shell so the tab bar hides)
  static const buyerWishlist = '/buyer/wishlist';
  static const buyerCart = '/buyer/cart';
  static const buyerCheckout = '/buyer/checkout';
  static const buyerOrders = '/buyer/orders';
  static const buyerOrderDetail = '/buyer/orders/:orderId';
  static const buyerAddresses = '/buyer/addresses';
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

  // Seller application
  static const sellerApply = '/seller/apply';

  // Admin
  static const adminPanel = '/admin/control-panel';

  static const adminUsers = '/admin/users';

  static const adminStoreApprovals = '/admin/store-approvals';

  static const adminStores = '/admin/stores';

  static const adminSellers = '/admin/sellers';

  static const adminReports = '/admin/reports';

  static const adminSettings = '/admin/settings';
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = _AuthRedirectNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    debugLogDiagnostics: false,
    refreshListenable: authNotifier,

    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.watch(authStateSignalingProvider);

      if (authState.isLoading) {
        return null;
      }

      if (authState.hasError) {
        return null;
      }

      final user = authState.value;

      final loc = state.matchedLocation;

      final isAuthRoute =
          loc == AppRoutes.landing ||
          loc == AppRoutes.login ||
          loc == AppRoutes.signup;

      final isProtectedPath =
          loc.startsWith('/seller') ||
          loc.startsWith('/admin') ||
          loc == AppRoutes.buyerOrders ||
          loc == AppRoutes.buyerCart ||
          loc == AppRoutes.buyerCheckout ||
          loc == AppRoutes.buyerWishlist;

      if (user == null && isProtectedPath) return AppRoutes.login;

      if (user != null && !user.isActive) {
        return '${AppRoutes.login}?error=account_suspended';
      }

      // /seller/apply is accessible to any authenticated user (buyer applying)
      if (loc == AppRoutes.sellerApply) return null;

      if (user != null &&
          loc.startsWith('/seller') &&
          !user.roles.any((r) => r.name == 'seller')) {
        return AppRoutes.buyerHome;
      }

      if (user != null &&
          loc.startsWith('/admin') &&
          !user.roles.any((r) => r.name == 'admin')) {
        return AppRoutes.buyerHome;
      }

      if (user != null && isAuthRoute) {
        if (user.roles.contains(UserRole.superAdmin) ||
            user.roles.contains(UserRole.admin)) {
          return AppRoutes.adminPanel;
        }

        if (user.roles.contains(UserRole.seller)) {
          return AppRoutes.sellerDashboard;
        }

        return AppRoutes.buyerHome;
      }
      if (loc == AppRoutes.root) {
        if (user == null) return AppRoutes.landing;

        if (user.roles.contains(UserRole.superAdmin) ||
            user.roles.contains(UserRole.admin)) {
          return AppRoutes.adminPanel;
        }

        if (user.roles.contains(UserRole.seller)) {
          return AppRoutes.sellerDashboard;
        }

        return AppRoutes.buyerHome;
      }

      return null;
    },

    routes: [
      // ── Auth (no shell, no bottom nav) ────────────────────────────────────
      GoRoute(
        path: AppRoutes.root,
        builder: (context, state) => const SizedBox.shrink(),
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

      // ── Seller Application (accessible to authenticated buyers) ───────────
      GoRoute(
        path: AppRoutes.sellerApply,
        builder: (context, state) => const SellerApplicationScreen(),
      ),

      // ── Buyer: full-screen push routes (no tab bar) ───────────────────────
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
        path: AppRoutes.productDetail,
        builder: (context, state) =>
            ProductDetailScreen(productId: state.pathParameters['productId']!),
      ),
      GoRoute(
        path: AppRoutes.chat,
        builder: (context, state) =>
            ChatScreen(chatId: state.pathParameters['chatId']!),
      ),

      // ── Fix 1 & 2: Buyer tab shell with persistent history ────────────────
      //
      // StatefulShellRoute keeps each branch's navigator stack alive.
      // Each branch has its own history, so back within a tab works as
      // expected, and switching tabs doesn't destroy the other tab's stack.
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Fix 2 & 3: wrap the shell in the double-back-to-exit widget
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
                builder: (context, state) => const ProductsScreen(),
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
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.buyerMenu,
                builder: (context, state) => const MenuScreen(),
              ),
            ],
          ),
        ],
      ),

      // ── Seller: full-screen routes ────────────────────────────────────────
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
      // ── Seller tab shell ──────────────────────────────────────────────────
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
        path: AppRoutes.adminReports,
        builder: (context, state) => const AdminReportsScreen(),
      ),

      GoRoute(
        path: AppRoutes.adminSettings,
        builder: (context, state) => const AdminSettingsScreen(),
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Fix 2 & 3: Buyer shell scaffold with bottom nav + double-back-to-exit
// ---------------------------------------------------------------------------

class _BuyerShell extends StatefulWidget {
  const _BuyerShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<_BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<_BuyerShell> {
  DateTime? _lastBackPress;

  // The "home" branch index — back on home tab triggers double-back exit.
  static const _homeIndex = 0;

  Future<bool> _onWillPop() async {
    final shell = widget.navigationShell;

    // If we're NOT on the home tab, go back to the home tab.
    if (shell.currentIndex != _homeIndex) {
      shell.goBranch(_homeIndex);
      return false;
    }

    final navigator = rootNavigatorKey.currentState;

    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return false;
    }

    // Fix 3: On the root home screen — require a second back within 2 s to exit.
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

    // Second back press within 2 s → exit app.
    await SystemNavigator.pop();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // canPop: false means we intercept every back gesture/button.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onWillPop();
      },
      child: Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: widget.navigationShell.currentIndex,
          onDestinationSelected: (index) {
            widget.navigationShell.goBranch(
              index,
              // Fix 2: tapping the current tab goes to its root
              // (standard iOS/Android behaviour).
              initialLocation: index == widget.navigationShell.currentIndex,
            );
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view),
              label: 'Products',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profile',
            ),
            NavigationDestination(icon: Icon(Icons.menu), label: 'Menu'),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Seller shell scaffold with bottom nav
// ---------------------------------------------------------------------------

class _SellerShell extends StatelessWidget {
  const _SellerShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Auth redirect notifier — tells GoRouter to re-evaluate redirect when
// the auth state changes (fixes redirect not firing on login/logout)
// ---------------------------------------------------------------------------

class _AuthRedirectNotifier extends ChangeNotifier {
  _AuthRedirectNotifier(Ref ref) {
    ref.listen<AsyncValue<AppUser?>>(authStateSignalingProvider, (
      previous,
      next,
    ) {
      notifyListeners();
    });
  }
}
