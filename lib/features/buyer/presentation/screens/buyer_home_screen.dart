import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/utils/time_utils.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/profile_image_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/profile_avatar.dart';
import 'package:ecom/features/buyer/presentation/controllers/speech_recognition_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:ecom/shared/presentation/widgets/cart_icon_with_badge.dart';
import 'package:ecom/shared/presentation/widgets/notification_bell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class BuyerHomeScreen extends ConsumerStatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  ConsumerState<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends ConsumerState<BuyerHomeScreen> {
  late ScrollController _scrollController;
  TextEditingController? _searchController;
  bool _isScrolled = false;
  String? _searchQuery;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.offset > 50 && !_isScrolled) {
          setState(() => _isScrolled = true);
        } else if (_scrollController.offset <= 50 && _isScrolled) {
          setState(() => _isScrolled = false);
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController?.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategory == category) {
        _selectedCategory = null;
      } else {
        _selectedCategory = category;
      }
    });
  }

  void _startVoiceSearch() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Voice Search',
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _VoiceSearchDialog(
          onResult: (result) {
            _searchController?.text = result;
            setState(() {
              _searchQuery = result;
            });
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutBack,
            ),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(marketplaceControllerProvider);
    final searchQuery = _searchQuery ?? '';
    final controller = _searchController ??= TextEditingController();
    final isFiltered = searchQuery.isNotEmpty || _selectedCategory != null;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : AppColors.lightBgPrimary,
      extendBodyBehindAppBar: true,
      drawer: const BuyerSideDrawer(),
      body: Stack(
        children: [
          const IgnorePointer(child: OrbBackgroundWidget()),
          CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(isDark),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBgSurface
                              : AppColors.lightBgSurface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isDark
                                  ? Colors.black26
                                  : const Color(
                                      0xFF7C3AED,
                                    ).withValues(alpha: 0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.search,
                              color: isDark
                                  ? AppColors.darkTextSecond
                                  : AppColors.lightTextSecond,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: controller,
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Search products, brands & more...',
                                  hintStyle: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecond
                                        : AppColors.lightTextSecond,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    _searchQuery = val.trim();
                                  });
                                },
                              ),
                            ),
                            if (searchQuery.isNotEmpty)
                              GestureDetector(
                                onTap: () {
                                  controller.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Icon(
                                    Icons.clear,
                                    color: isDark
                                        ? AppColors.darkTextSecond
                                        : AppColors.lightTextSecond,
                                    size: 20,
                                  ),
                                ),
                              ),
                            GestureDetector(
                              onTap: _startVoiceSearch,
                              behavior: HitTestBehavior.opaque,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color:
                                      (isDark
                                              ? AppColors.darkAccentPurple
                                              : AppColors.lightAccentPurple)
                                          .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.mic,
                                  color: isDark
                                      ? AppColors.darkAccentPurple
                                      : AppColors.lightAccentPurple,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Hero Banner
                      if (!isFiltered) ...[
                        const _HeroBannerWidget(),
                        const SizedBox(height: 32),
                      ],

                      // Categories
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 100,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          clipBehavior: Clip.none,
                          children: [
                            _CategoryPillWidget(
                              icon: Icons.devices_other,
                              label: 'Electronics',
                              color: const Color(0xFF8B5CF6),
                              isSelected: _selectedCategory == 'Electronics',
                              onTap: () => _toggleCategory('Electronics'),
                            ),
                            _CategoryPillWidget(
                              icon: Icons.checkroom,
                              label: 'Fashion',
                              color: const Color(0xFFEC4899),
                              isSelected: _selectedCategory == 'Fashion',
                              onTap: () => _toggleCategory('Fashion'),
                            ),
                            _CategoryPillWidget(
                              icon: Icons.home_outlined,
                              label: 'Home',
                              color: const Color(0xFFF59E0B),
                              isSelected: _selectedCategory == 'Home',
                              onTap: () => _toggleCategory('Home'),
                            ),
                            _CategoryPillWidget(
                              icon: Icons.spa_outlined,
                              label: 'Beauty',
                              color: const Color(0xFF10B981),
                              isSelected: _selectedCategory == 'Beauty',
                              onTap: () => _toggleCategory('Beauty'),
                            ),
                            _CategoryPillWidget(
                              icon: Icons.sports_soccer_outlined,
                              label: 'Sports',
                              color: const Color(0xFF3B82F6),
                              isSelected: _selectedCategory == 'Sports',
                              onTap: () => _toggleCategory('Sports'),
                            ),
                            _CategoryPillWidget(
                              icon: Icons.local_grocery_store_outlined,
                              label: 'Groceries',
                              color: const Color(0xFF84CC16),
                              isSelected: _selectedCategory == 'Groceries',
                              onTap: () => _toggleCategory('Groceries'),
                            ),
                            _CategoryPillWidget(
                              icon: Icons.menu_book_outlined,
                              label: 'Books',
                              color: const Color(0xFFF43F5E),
                              isSelected: _selectedCategory == 'Books',
                              onTap: () => _toggleCategory('Books'),
                            ),
                            _CategoryPillWidget(
                              icon: Icons.smart_toy_outlined,
                              label: 'Toys',
                              color: const Color(0xFF06B6D4),
                              isSelected: _selectedCategory == 'Toys',
                              onTap: () => _toggleCategory('Toys'),
                            ),
                            _CategoryPillWidget(
                              icon: Icons.fitness_center,
                              label: 'Fitness',
                              color: const Color(0xFFF97316),
                              isSelected: _selectedCategory == 'Fitness',
                              onTap: () => _toggleCategory('Fitness'),
                            ),
                            _CategoryPillWidget(
                              icon: Icons.card_giftcard_outlined,
                              label: 'Gifts',
                              color: const Color(0xFFD946EF),
                              isSelected: _selectedCategory == 'Gifts',
                              onTap: () => _toggleCategory('Gifts'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      ...productsAsync.when(
                        data: (products) {
                          final flashDeals = products.where((product) {
                            final isFlash =
                                product.metadata['isFlashDeal'] as bool? ??
                                false;
                            if (!isFlash) return false;

                            final now = DateTime.now();

                            // Check startsAt
                            final startsAtVal =
                                product.metadata['flashSaleStartsAt'];
                            if (startsAtVal != null) {
                              DateTime? startsAt;
                              if (startsAtVal is Timestamp) {
                                startsAt = startsAtVal.toDate();
                              } else if (startsAtVal is String) {
                                startsAt = DateTime.tryParse(startsAtVal);
                              }
                              if (startsAt != null && now.isBefore(startsAt)) {
                                return false;
                              }
                            }

                            // Check endsAt
                            final endsAtVal =
                                product.metadata['flashSaleEndsAt'];
                            if (endsAtVal != null) {
                              DateTime? endsAt;
                              if (endsAtVal is Timestamp) {
                                endsAt = endsAtVal.toDate();
                              } else if (endsAtVal is String) {
                                endsAt = DateTime.tryParse(endsAtVal);
                              }
                              if (endsAt != null && now.isAfter(endsAt)) {
                                return false;
                              }
                            }
                            return true;
                          }).toList();

                          if (flashDeals.isEmpty) {
                            return [const SizedBox.shrink()];
                          }
                          if (isFiltered) return [const SizedBox.shrink()];
                          return [
                            // Flash Deals Header
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'Flash Deals',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(
                                            Icons.local_fire_department,
                                            color: Color(0xFFEF4444),
                                            size: 16,
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            'Ending in',
                                            style: TextStyle(
                                              color: Color(0xFFEF4444),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Text(
                                  'View All',
                                  style: TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            _CountdownTimerWidget(flashDeals: flashDeals),
                            const SizedBox(height: 16),

                            // Flash Deals List
                            SizedBox(
                              height: 230,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                clipBehavior: Clip.none,
                                itemCount: flashDeals.length > 5
                                    ? 5
                                    : flashDeals.length,
                                itemBuilder: (context, index) {
                                  final product = flashDeals[index];
                                  return _ProductCard(product: product);
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ];
                        },
                        loading: () => [
                          const Center(child: CircularProgressIndicator()),
                        ],
                        error: (error, _) => [
                          Center(child: Text('Error: $error')),
                        ],
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isFiltered ? 'Search Results' : 'Recommended',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (isFiltered)
                            GestureDetector(
                              onTap: () {
                                _searchController?.clear();
                                setState(() {
                                  _searchQuery = '';
                                  _selectedCategory = null;
                                });
                              },
                              child: const Text(
                                'Clear All',
                                style: TextStyle(
                                  color: Color(0xFFEC4899),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // Recommended Grid
              productsAsync.when(
                data: (products) {
                  final filtered = products.where((product) {
                    final q = _searchQuery ?? '';
                    final matchesQuery =
                        q.isEmpty ||
                        product.title.toLowerCase().contains(q.toLowerCase()) ||
                        product.description.toLowerCase().contains(
                          q.toLowerCase(),
                        );
                    final matchesCategory =
                        _selectedCategory == null ||
                        (product.metadata['category'] as String?)
                                ?.toLowerCase() ==
                            _selectedCategory!.toLowerCase();
                    return matchesQuery && matchesCategory;
                  }).toList();

                  if (filtered.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 60,
                          horizontal: 24,
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkBgSurface.withValues(alpha: 0.5)
                              : AppColors.lightBgSurface.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: isDark
                                    ? AppColors.darkTextSecond.withValues(
                                        alpha: 0.5,
                                      )
                                    : AppColors.lightTextSecond.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No matching products found',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.darkTextPrimary
                                      : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try checking your spelling or search for something else.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: isDark
                                      ? AppColors.darkTextSecond
                                      : AppColors.lightTextSecond,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 140,
                            childAspectRatio: 0.53,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final product = filtered[index];
                        return _ProductCard(product: product);
                      }, childCount: filtered.length),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => SliverToBoxAdapter(
                  child: Center(child: Text('Error: $error')),
                ),
              ),

              // Bottom padding
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final opt = ref.watch(optimisticProfileProvider);

    final String greetingText = userProfileAsync.maybeWhen(
      data: (user) {
        if (user != null) {
          final name = user.displayName.trim();
          return 'Hi, ${name.isNotEmpty ? name : 'User'} 👋';
        }
        return 'Hello User';
      },
      orElse: () => 'Hello User',
    );

    return SliverAppBar(
      expandedHeight: 80,
      collapsedHeight: 60,
      pinned: true,
      backgroundColor: _isScrolled
          ? (isDark
                ? AppColors.darkBgPrimary.withValues(alpha: 0.8)
                : AppColors.lightBgPrimary.withValues(alpha: 0.8))
          : Colors.transparent,
      elevation: _isScrolled ? 4 : 0,
      flexibleSpace: _isScrolled
          ? ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.transparent),
              ),
            )
          : null,
      leading: Builder(
        builder: (context) => IconButton(
          icon: Icon(
            Icons.menu,
            color: isDark
                ? AppColors.darkTextPrimary
                : AppColors.lightTextPrimary,
          ),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      centerTitle: true,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            greetingText,
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextPrimary
                  : AppColors.lightTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            getGreetingMessage(),
            style: TextStyle(
              color: isDark
                  ? AppColors.darkTextSecond
                  : AppColors.lightTextSecond,
              fontSize: 13,
            ),
          ),
        ],
      ),
      actions: [
        const NotificationBell(),
        const CartIconWithBadge(),
        GestureDetector(
          onTap: () => context.push('/buyer/profile'),
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: ProfileAvatar(
              imageUrl: opt.imageUrl,
              localImageBytes: opt.localBytes,
              isUploading: opt.isUploading,
              userName: userProfileAsync.value?.displayName ?? 'User',
              radius: 18,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroBannerWidget extends StatelessWidget {
  const _HeroBannerWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Special Offer',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Mega Sale',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Up to 60% Off',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Shop Now',
                    style: TextStyle(
                      color: Color(0xFF6D28D9),
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 10,
            bottom: -20,
            child: FloatingProductWidget(
              floatHeight: 8,
              child: Image.asset(
                'assets/images/3d/hero_bag.png',
                width: 130,
                height: 130,
              ),
            ),
          ),
          Positioned(
            right: 120,
            bottom: 0,
            child: FloatingProductWidget(
              floatHeight: 6,
              child: Image.asset(
                'assets/images/3d/hero_gift.png',
                width: 60,
                height: 60,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPillWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryPillWidget({
    required this.icon,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.2)
                    : (isDark
                          ? AppColors.darkBgSurface
                          : color.withValues(alpha: 0.1)),
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(color: color, width: 2)
                    : (isDark ? Border.all(color: Colors.white10) : null),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: isSelected ? 0.4 : 0.2),
                    blurRadius: isSelected ? 16 : 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: Icon(icon, size: 28, color: color)),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? color
                    : (isDark
                          ? AppColors.darkTextPrimary
                          : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountdownTimerWidget extends StatefulWidget {
  final List<CatalogItem> flashDeals;

  const _CountdownTimerWidget({required this.flashDeals});

  @override
  State<_CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<_CountdownTimerWidget> {
  late Timer _timer;
  late Duration _timeLeft;

  @override
  void initState() {
    super.initState();
    _timeLeft = _calculateTimeLeft();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _timeLeft = _calculateTimeLeft();
        });
      }
    });
  }

  Duration _calculateTimeLeft() {
    final now = DateTime.now();
    DateTime? earliestEnd;

    for (final product in widget.flashDeals) {
      final endsAtVal = product.metadata['flashSaleEndsAt'];
      if (endsAtVal != null) {
        DateTime? endsAt;
        if (endsAtVal is Timestamp) {
          endsAt = endsAtVal.toDate();
        } else if (endsAtVal is String) {
          endsAt = DateTime.tryParse(endsAtVal);
        }
        if (endsAt != null && endsAt.isAfter(now)) {
          if (earliestEnd == null || endsAt.isBefore(earliestEnd)) {
            earliestEnd = endsAt;
          }
        }
      }
    }

    final targetTime =
        earliestEnd ?? DateTime(now.year, now.month, now.day, 23, 59, 59);
    final difference = targetTime.difference(now);
    return difference.isNegative ? Duration.zero : difference;
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _timeLeft.inHours.toString().padLeft(2, '0');
    final minutes = (_timeLeft.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (_timeLeft.inSeconds % 60).toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            hours,
            style: const TextStyle(
              color: Color(0xFF4338CA),
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            ' : ',
            style: TextStyle(
              color: Color(0xFF4338CA),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            minutes,
            style: const TextStyle(
              color: Color(0xFF4338CA),
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Text(
            ' : ',
            style: TextStyle(
              color: Color(0xFF4338CA),
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            seconds,
            style: const TextStyle(
              color: Color(0xFF4338CA),
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends ConsumerWidget {
  final CatalogItem product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = product.title;
    final price = '₹${product.basePrice.toStringAsFixed(2)}';
    final oldPrice = product.metadata['oldPrice'] as String? ?? '';
    final discount = product.metadata['discount'] as String? ?? '';
    final imageUrl = product.imageUrls.isNotEmpty
        ? product.imageUrls.first
        : null;

    return Container(
      width: 125,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => context.push('/buyer/home/product/${product.id}'),
        child: GlassCardWidget(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 90,
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white10
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: FloatingProductWidget(
                        floatHeight: 6,
                        child: imageUrl != null && imageUrl.startsWith('http')
                            ? Image.network(
                                imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : Image.asset(
                                imageUrl ??
                                    'assets/images/3d/product_headphones.png',
                                width: 60,
                                height: 60,
                              ),
                      ),
                    ),
                  ),
                  if (discount.isNotEmpty)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          discount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    price,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: Color(0xFF7C3AED),
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (oldPrice.isNotEmpty)
                    Text(
                      oldPrice,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                        color: Colors.grey,
                        decoration: TextDecoration.lineThrough,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 28,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () async {
                    try {
                      final cartItem = CartItem(
                        id: product.id,
                        productId: product.id,
                        title: product.title,
                        storeId: product.storeId,
                        storeName:
                            product.metadata['storeName'] as String? ??
                            'Seller Store',
                        unitPrice: product.basePrice,
                        imageUrl: product.imageUrls.isNotEmpty
                            ? product.imageUrls.first
                            : 'assets/images/3d/product_headphones.png',
                        quantity: 1,
                      );

                      await ref
                          .read(cartControllerProvider.notifier)
                          .addItem(cartItem);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.title} added to cart!'),
                            backgroundColor: const Color(0xFF10B981),
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            duration: const Duration(seconds: 2),
                            action: SnackBarAction(
                              label: 'VIEW',
                              textColor: Colors.white,
                              onPressed: () {
                                context.push('/buyer/cart');
                              },
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to add to cart: $e'),
                            backgroundColor: const Color(0xFFEF4444),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VoiceSearchDialog extends ConsumerStatefulWidget {
  final Function(String) onResult;

  const _VoiceSearchDialog({required this.onResult});

  @override
  ConsumerState<_VoiceSearchDialog> createState() => _VoiceSearchDialogState();
}

class _VoiceSearchDialogState extends ConsumerState<_VoiceSearchDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _rippleController;

  @override
  void initState() {
    super.initState();
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(speechRecognitionControllerProvider.notifier).startListening();
    });
  }

  @override
  void dispose() {
    _rippleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SpeechRecognitionState>(speechRecognitionControllerProvider, (
      previous,
      next,
    ) {
      if (next.status == SpeechRecognitionStatus.done &&
          next.partialTranscript.isNotEmpty) {
        widget.onResult(next.partialTranscript);
        if (context.mounted && Navigator.canPop(context)) {
          Navigator.of(context).pop();
        }
      }
    });

    final speechState = ref.watch(speechRecognitionControllerProvider);

    // Manage animation state based on speech status
    if (speechState.status == SpeechRecognitionStatus.listening ||
        speechState.status == SpeechRecognitionStatus.processing) {
      if (!_rippleController.isAnimating) {
        _rippleController.repeat();
      }
    } else {
      if (_rippleController.isAnimating) {
        _rippleController.stop();
      }
    }

    String statusText = '';
    String recognizedText = speechState.partialTranscript;

    switch (speechState.status) {
      case SpeechRecognitionStatus.idle:
        statusText = 'Tap mic to start...';
        break;
      case SpeechRecognitionStatus.listening:
        statusText = 'Listening...';
        break;
      case SpeechRecognitionStatus.processing:
        statusText = 'Listening...';
        break;
      case SpeechRecognitionStatus.done:
        if (speechState.partialTranscript.isEmpty) {
          statusText = 'No speech detected. Tap mic to try again.';
        } else {
          statusText = 'Recognized speech:';
        }
        break;
      case SpeechRecognitionStatus.error:
        // errorMessage here is always curated, human-readable copy set by
        // the controller (never a raw exception string) - safe to show.
        statusText =
            speechState.errorMessage ??
            'No speech detected. Tap mic to try again.';
        break;
      case SpeechRecognitionStatus.permissionDenied:
        statusText =
            speechState.errorMessage ??
            'Microphone permission needed — tap to open settings';
        break;
      case SpeechRecognitionStatus.notAvailable:
        statusText =
            speechState.errorMessage ??
            "Speech recognition isn't available on this device";
        break;
    }

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.7),
      body: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Stack(
          children: [
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),

            // Listening wave and microphone
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated audio ripple
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildRippleCircle(1.0),
                          _buildRippleCircle(0.7),
                          _buildRippleCircle(0.4),
                          // Core mic button
                          GestureDetector(
                            onTap: () {
                              final status = ref
                                  .read(speechRecognitionControllerProvider)
                                  .status;
                              if (status ==
                                  SpeechRecognitionStatus.permissionDenied) {
                                ref
                                    .read(
                                      speechRecognitionControllerProvider
                                          .notifier,
                                    )
                                    .openSettings();
                              } else if (status ==
                                      SpeechRecognitionStatus.listening ||
                                  status ==
                                      SpeechRecognitionStatus.processing) {
                                ref
                                    .read(
                                      speechRecognitionControllerProvider
                                          .notifier,
                                    )
                                    .stopListening();
                              } else {
                                ref
                                    .read(
                                      speechRecognitionControllerProvider
                                          .notifier,
                                    )
                                    .startListening();
                              }
                            },
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFF8B5CF6),
                                    Color(0xFFEC4899),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Color(0xFF8B5CF6),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.mic,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 48),

                  // Status Text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: Text(
                      statusText,
                      key: ValueKey(statusText),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recognized Text
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: recognizedText.isNotEmpty
                        ? Text(
                            '"$recognizedText"',
                            key: ValueKey(recognizedText),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                            ),
                          )
                        : const SizedBox(height: 34),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRippleCircle(double progressOffset) {
    double progress = (_rippleController.value + progressOffset) % 1.0;
    double scale = 1.0 + (progress * 1.5);
    double opacity = (1.0 - progress) * 0.4;

    return Transform.scale(
      scale: scale,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF8B5CF6).withValues(alpha: opacity),
          border: Border.all(
            color: const Color(0xFFEC4899).withValues(alpha: opacity),
            width: 1.5,
          ),
        ),
      ),
    );
  }
}
