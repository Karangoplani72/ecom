import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/widgets/app_empty_view.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_product_card.dart';
import 'package:ecom/core/widgets/app_shimmer.dart';
import 'package:ecom/core/widgets/responsive_layout.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:ecom/features/marketplace/presentation/controllers/notification_controller.dart';
import 'package:ecom/shared/presentation/navigation/router.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/theme/app_shadows.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

class BuyerHomeScreen extends ConsumerStatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  ConsumerState<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends ConsumerState<BuyerHomeScreen>
    with SingleTickerProviderStateMixin {
  late ScrollController _scrollController;
  late AnimationController _heroAnimController;

  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.offset > 50 && !_isScrolled) {
          setState(() => _isScrolled = true);
        } else if (_scrollController.offset <= 50 && _isScrolled) {
          setState(() => _isScrolled = false);
        }
      });

    _heroAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _heroAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogState = ref.watch(marketplaceControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final userId = ref.watch(currentUserIdProvider);
    final notificationsAsync = userId != null
        ? ref.watch(userNotificationsProvider)
        : null;
    final unreadCount =
        notificationsAsync?.value?.where((n) => !n.isRead).length ?? 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isScrolled 
                ? (isDark ? AppColors.surfaceDark.withValues(alpha: 0.8) : Colors.white.withValues(alpha: 0.8))
                : Colors.transparent,
            boxShadow: _isScrolled ? (isDark ? AppShadows.darkSm : AppShadows.lightSm) : [],
          ),
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                  sigmaX: _isScrolled ? 10 : 0, sigmaY: _isScrolled ? 10 : 0),
              child: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: AnimatedOpacity(
                  opacity: _isScrolled ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    'Discover',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                actions: [
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () =>
                            context.push(AppRoutes.buyerNotifications),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.favorite_border),
                    onPressed: () => context.push('/buyer/wishlist'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () => context.push('/buyer/cart'),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),
      ),
      body: ResponsiveLayout(
        maxWidth: 1200,
        usePagePadding: false,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
            ),
            
            // Hero Title
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _heroAnimController,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
                    CurvedAnimation(parent: _heroAnimController, curve: Curves.easeOutCubic),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Explore',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                            letterSpacing: -1,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          'the best premium products',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Premium Search Bar
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _heroAnimController,
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
                    CurvedAnimation(parent: _heroAnimController, curve: Curves.easeOutCubic),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                    child: GestureDetector(
                      onTap: () => context.push('/buyer/products'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isDark ? AppShadows.darkMd : AppShadows.lightMd,
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.borderLight,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search, color: isDark ? AppColors.primaryLight : AppColors.primary),
                            const SizedBox(width: 16),
                            Text(
                              'Search anything...',
                              style: TextStyle(
                                fontSize: 16,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (isDark ? AppColors.primaryLight : AppColors.primary).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(Icons.tune, color: isDark ? AppColors.primaryLight : AppColors.primary, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Categories
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _heroAnimController, curve: const Interval(0.4, 1.0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 110,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 20),
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return GestureDetector(
                            onTap: () => context.push('/buyer/products?category=${category.name}'),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.surfaceDark : Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: isDark ? AppShadows.darkSm : AppShadows.lightSm,
                                    border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                                  ),
                                  child: Icon(category.icon, color: isDark ? AppColors.primaryLight : AppColors.primary, size: 28),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  category.name,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Featured Header
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverToBoxAdapter(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/buyer/products'),
                      child: Text(
                        'See all',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.primaryLight : AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            catalogState.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 1200 ? 5 : width > 900 ? 4 : width > 600 ? 3 : 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 24,
                    childAspectRatio: 0.65,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const AppShimmer(borderRadius: 24),
                    childCount: 4,
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                child: AppErrorView(
                  message: error.toString(),
                  onRetry: () => ref.invalidate(marketplaceControllerProvider),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: AppEmptyView(
                      title: 'No Products Available',
                      subtitle: 'New products will appear here when sellers publish them.',
                      icon: Icons.inventory_2_outlined,
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 100),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: width > 1200 ? 5 : width > 900 ? 4 : width > 600 ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 24,
                      childAspectRatio: 0.65,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = items[index];
                      return AppProductCard(
                        title: item.title,
                        imageUrl: item.imageUrls.isNotEmpty ? item.imageUrls.first : '',
                        rating: 4.8,
                        price: item.basePrice,
                        onTap: () => context.push('/buyer/home/product/${item.id}'),
                      );
                    }, childCount: items.length),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String name;
  final IconData icon;

  const _CategoryItem(this.name, this.icon);
}

const _categories = [
  _CategoryItem('Fashion', Icons.checkroom),
  _CategoryItem('Electronics', Icons.devices),
  _CategoryItem('Home', Icons.home_work),
  _CategoryItem('Beauty', Icons.face),
  _CategoryItem('Sports', Icons.sports_basketball),
  _CategoryItem('Books', Icons.menu_book),
];
