import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- Imports for Screens ---
import 'package:ecom/features/auth/presentation/screens/landing_screen.dart';
import 'package:ecom/features/auth/presentation/screens/login_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/buyer_home_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/cart_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/checkout_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/buyer_orders_screen.dart';
import 'package:ecom/features/buyer/presentation/screens/product_detail_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_dashboard_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_inventory_screen.dart';
import 'package:ecom/features/seller/presentation/screens/add_product_screen.dart';
import 'package:ecom/features/seller/presentation/screens/seller_finances_screen.dart';

// --- Auth Imports ---
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/auth/domain/entities/app_user.dart';

// --- Navigation Keys ---
final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'rootNav');
final GlobalKey<NavigatorState> _buyerShellKey = GlobalKey<NavigatorState>(debugLabel: 'buyerShellNav');
final GlobalKey<NavigatorState> _sellerShellKey = GlobalKey<NavigatorState>(debugLabel: 'sellerShellNav');
final GlobalKey<NavigatorState> _adminShellKey = GlobalKey<NavigatorState>(debugLabel: 'adminShellNav');

final routerProvider = Provider<GoRouter>((ref) {
  final authStateAsync = ref.watch(authStateSignalingProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: '/landing',
    redirect: (BuildContext context, GoRouterState state) {
      final user = authStateAsync.value;
      if (authStateAsync.isLoading) return null;

      final isNavigatingPublicPath = state.matchedLocation == '/login' || state.matchedLocation == '/landing';
      if (user == null) return isNavigatingPublicPath ? null : '/landing';
      if (!user.isActive) return '/login?error=account_suspended';
      return null;
    },
    routes: [
      GoRoute(path: '/landing', builder: (context, state) => const LandingScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      // Buyer Cluster
      ShellRoute(
        navigatorKey: _buyerShellKey,
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(path: '/buyer/home', builder: (context, state) => const BuyerHomeScreen(), routes: [
            GoRoute(path: 'product/:productId', builder: (context, state) => ProductDetailScreen(productId: state.pathParameters['productId']!)),
          ]),
          GoRoute(path: '/buyer/cart', builder: (context, state) => const CartScreen()),
          GoRoute(path: '/buyer/checkout', builder: (context, state) => const CheckoutScreen()),
          GoRoute(path: '/buyer/orders', builder: (context, state) => const BuyerOrdersScreen()),
        ],
      ),

      // Seller Cluster
      ShellRoute(
        navigatorKey: _sellerShellKey,
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(path: '/seller/dashboard', builder: (context, state) => const SellerDashboardScreen()),
          GoRoute(path: '/seller/inventory', builder: (context, state) => const SellerInventoryScreen(), routes: [
            GoRoute(path: 'add', parentNavigatorKey: rootNavigatorKey, builder: (context, state) => const AddProductScreen()),
          ]),
          GoRoute(path: '/seller/finances', builder: (context, state) => const SellerFinancesScreen()),
        ],
      ),

      // Admin Cluster
      ShellRoute(
        navigatorKey: _adminShellKey,
        builder: (context, state, child) => Scaffold(body: child),
        routes: [
          GoRoute(path: '/admin/control-panel', builder: (context, state) => const Scaffold(body: Center(child: Text('Admin')))),
        ],
      ),
    ],
  );
});