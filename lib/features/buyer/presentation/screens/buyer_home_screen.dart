import 'dart:async';
import 'dart:ui';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/providers/categories_provider.dart';
import 'package:ecom/features/auth/presentation/controllers/auth_controller.dart';
import 'package:ecom/features/buyer/domain/entities/cart_item.dart';
import 'package:ecom/features/buyer/presentation/controllers/cart_controller.dart';
import 'package:ecom/features/buyer/presentation/controllers/speech_recognition_controller.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_side_drawer.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';
import 'package:ecom/features/marketplace/presentation/controllers/marketplace_controller.dart';
import 'package:ecom/shared/presentation/widgets/cart_icon_with_badge.dart';
import 'package:ecom/shared/presentation/widgets/notification_bell.dart';
import 'package:ecom/features/buyer/presentation/controllers/wishlist_controller.dart';
import 'package:ecom/core/utils/price_helper.dart';
import 'package:ecom/shared/presentation/widgets/wishlist_icon_with_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class BuyerHomeScreen extends ConsumerStatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  ConsumerState<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends ConsumerState<BuyerHomeScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;
  late final FocusNode _searchFocusNode;
  bool _isScrolled = false;
  String _searchQuery = '';
  final Set<String> _selectedCategories = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchFocusNode = FocusNode();
    _scrollController = ScrollController()
      ..addListener(() {
        if (_scrollController.offset > 20 && !_isScrolled) {
          setState(() => _isScrolled = true);
        } else if (_scrollController.offset <= 20 && _isScrolled) {
          setState(() => _isScrolled = false);
        }
      });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleCategory(String category) {
    setState(() {
      final normalized = category.toLowerCase();
      if (_selectedCategories.contains(normalized)) {
        _selectedCategories.remove(normalized);
      } else {
        _selectedCategories.add(normalized);
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
            _searchController.text = result;
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

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'electronics':
        return Icons.devices_other_rounded;
      case 'fashion':
        return Icons.checkroom_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'beauty':
        return Icons.spa_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      case 'groceries':
        return Icons.local_grocery_store_rounded;
      case 'books':
        return Icons.menu_book_rounded;
      case 'toys':
        return Icons.smart_toy_rounded;
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'gifts':
        return Icons.card_giftcard_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final productsAsync = ref.watch(marketplaceControllerProvider);

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

              // Search Bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(
                          alpha: isDark ? 0.1 : 0.4,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF7C3AED,
                          ).withValues(alpha: isDark ? 0.1 : 0.05),
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
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            style: GoogleFonts.inter(
                              color: isDark
                                  ? AppColors.darkTextPrimary
                                  : AppColors.lightTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search products, brands & more...',
                              hintStyle: GoogleFonts.inter(
                                color: isDark
                                    ? AppColors.darkTextSecond
                                    : AppColors.lightTextSecond,
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
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
                        if (_searchQuery.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                            child: Icon(
                              Icons.close,
                              color: isDark
                                  ? AppColors.darkTextSecond
                                  : AppColors.lightTextSecond,
                              size: 20,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _startVoiceSearch,
                            child: Icon(
                              Icons.mic_none_rounded,
                              color: isDark
                                  ? AppColors.darkTextSecond
                                  : AppColors.lightTextSecond,
                              size: 22,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Conditional Body: Filtered grid OR Luxury dashboard
              productsAsync.when(
                data: (products) {
                  final filtered = products.where((product) {
                    final matchesSearch =
                        product.title.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        ) ||
                        product.description.toLowerCase().contains(
                          _searchQuery.toLowerCase(),
                        );
                    final matchesCategory =
                        _selectedCategories.isEmpty ||
                        _selectedCategories.contains(
                          (product.metadata['category'] as String?)
                              ?.toLowerCase(),
                        );
                    return matchesSearch && matchesCategory;
                  }).toList();

                  final isSearching = _searchQuery.isNotEmpty;

                  if (isSearching) {
                    // Render Filtered Search Results Grid
                    if (filtered.isEmpty) {
                      return SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: _buildCategorySection(
                                context,
                                ref,
                                isDark,
                              ),
                            ),
                          ),
                          const SliverFillRemaining(
                            hasScrollBody: false,
                            child: Center(
                              child: Text(
                                'No products found matching filters.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return SliverMainAxisGroup(
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildCategorySection(context, ref, isDark),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.all(20),
                          sliver: SliverGrid(
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.68,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                ),
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              return _ProductCard(
                                product: filtered[index],
                                showTrendingBadge: false,
                              );
                            }, childCount: filtered.length),
                          ),
                        ),
                      ],
                    );
                  }

                  // Otherwise, Render Luxury Dashboard Sections (with category filtering applied if selected)
                  final displayProducts = _selectedCategories.isEmpty
                      ? products
                      : products
                            .where(
                              (p) => _selectedCategories.contains(
                                (p.metadata['category'] as String?)
                                    ?.toLowerCase(),
                              ),
                            )
                            .toList();

                  return SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 12),
                      // Section 1: Hero Banner
                      const _HeroBannerSection(),
                      const SizedBox(height: 24),

                      // Section 2: Categories
                      _buildCategorySection(context, ref, isDark),
                      const SizedBox(height: 28),

                      // Section 3: Featured Products
                      _buildHorizontalProductSection(
                        title: 'Featured',
                        subtitle: 'Exclusive recommendations',
                        products: displayProducts.take(10).toList(),
                        showTrendingBadge: false,
                      ),
                      const SizedBox(height: 28),

                      // Section 4: Trending Now
                      _buildHorizontalProductSection(
                        title: 'Trending Now',
                        subtitle: 'Top choice products this week',
                        products:
                            displayProducts.skip(10).take(10).toList().isEmpty
                            ? displayProducts.reversed.take(10).toList()
                            : displayProducts.skip(10).take(10).toList(),
                        showTrendingBadge: true,
                      ),
                    ]),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
                  ),
                ),
                error: (error, _) => SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),

              // Bottom offset for floating navbar
              const SliverToBoxAdapter(child: SizedBox(height: 110)),
            ],
          ),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(bool isDark) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final String greetingText = userProfileAsync.maybeWhen(
      data: (user) {
        if (user != null) {
          final name = user.displayName.trim();
          return '${name.isNotEmpty ? name : 'User'} 👋';
        }
        return 'User 👋';
      },
      orElse: () => 'User 👋',
    );

    // Get time based greeting
    final hour = DateTime.now().hour;
    String timeGreeting = 'Good morning';
    if (hour >= 12 && hour < 17) {
      timeGreeting = 'Good afternoon';
    } else if (hour >= 17) {
      timeGreeting = 'Good evening';
    }

    return SliverAppBar(
      floating: true,
      pinned: true,
      snap: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      leading: Builder(
        builder: (context) {
          return IconButton(
            icon: _buildGlassIcon(Icons.menu_rounded, isDark),
            onPressed: () => Scaffold.of(context).openDrawer(),
          );
        },
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            '$timeGreeting, $greetingText',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.lightTextPrimary,
            ),
          ),
          Text(
            'Discover something new',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white70 : AppColors.lightTextSecond,
            ),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        const NotificationBell(),
        const WishlistIconWithBadge(),
        const CartIconWithBadge(),
        const SizedBox(width: 8),
      ],
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? [
                        AppColors.darkBgPrimary.withValues(alpha: 0.95),
                        AppColors.darkBgPrimary.withValues(alpha: 0.6),
                      ]
                    : [
                        AppColors.lightBgPrimary.withValues(alpha: 0.95),
                        AppColors.lightBgPrimary.withValues(alpha: 0.6),
                      ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassIcon(IconData icon, bool isDark) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.07)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.15),
        ),
      ),
      child: Icon(
        icon,
        size: 18,
        color: isDark ? Colors.white : AppColors.lightTextPrimary,
      ),
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
  ) {
    final categoriesAsync = ref.watch(activeCategoriesStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Shop by Category',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/buyer/products'),
                child: Text(
                  'See all →',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedCategories.isNotEmpty) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedCategories.map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        cat.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C3AED),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategories.remove(cat);
                          });
                        },
                        child: const Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: Color(0xFF7C3AED),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          height: 88,
          child: categoriesAsync.when(
            data: (categories) {
              if (categories.isEmpty) {
                return const Center(child: Text('No categories available'));
              }
              return Center(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(categories.length, (index) {
                      final cat = categories[index];
                      final isSelected = _selectedCategories.contains(
                        cat.toLowerCase(),
                      );

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: GestureDetector(
                          onTap: () => _toggleCategory(cat),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.06)
                                      : Colors.white.withValues(alpha: 0.75),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xFF7C3AED)
                                        : Colors.white.withValues(
                                            alpha: isDark ? 0.1 : 0.5,
                                          ),
                                    width: isSelected ? 1.8 : 1.0,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: const Color(
                                              0xFF7C3AED,
                                            ).withValues(alpha: 0.25),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Icon(
                                  _getCategoryIcon(cat),
                                  color: isSelected
                                      ? const Color(0xFF7C3AED)
                                      : (isDark
                                            ? Colors.white70
                                            : AppColors.lightTextPrimary),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? const Color(0xFF7C3AED)
                                      : (isDark
                                            ? AppColors.darkTextSecond
                                            : AppColors.lightTextSecond),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildHorizontalProductSection({
    required String title,
    required String subtitle,
    required List<CatalogItem> products,
    required bool showTrendingBadge,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: isDark
                          ? Colors.white60
                          : AppColors.lightTextSecond,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.go('/buyer/products'),
                child: Text(
                  'See all →',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7C3AED),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 232,
          child: products.isEmpty
              ? Center(
                  child: Text(
                    'No products available.',
                    style: GoogleFonts.inter(color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: SizedBox(
                        width: 154,
                        child: _ProductCard(
                          product: products[index],
                          showTrendingBadge: showTrendingBadge,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HeroBannerSection extends StatefulWidget {
  const _HeroBannerSection();

  @override
  State<_HeroBannerSection> createState() => _HeroBannerSectionState();
}

class _HeroBannerSectionState extends State<_HeroBannerSection> {
  late final PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> _bannerConfigs = [
    {
      'title': 'Flash Sale · Up to 50% Off',
      'subtitle': 'Grab your favorites before they sell out.',
      'tag': 'Limited Offer',
      'gradient': const LinearGradient(
        colors: [Color(0xFF7C3AED), Color(0xFF4C1D95)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'New Arrivals · Just Dropped',
      'subtitle': 'Stay ahead of the curve with fresh items.',
      'tag': 'Fresh In',
      'gradient': const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFF9D174D)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
    {
      'title': 'Free Delivery · Orders Over ₹999',
      'subtitle': 'Fast transit right to your front door.',
      'tag': 'Delivery Deal',
      'gradient': const LinearGradient(
        colors: [Color(0xFF0EA5E9), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      if (_currentPage < _bannerConfigs.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 190,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (value) {
              setState(() {
                _currentPage = value;
              });
            },
            itemCount: _bannerConfigs.length,
            itemBuilder: (context, index) {
              final config = _bannerConfigs[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: config['gradient'] as Gradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(22),
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
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                config['tag'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              config['title'] as String,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              config['subtitle'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            'Shop Now',
                            style: GoogleFonts.inter(
                              color: Colors.black,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_bannerConfigs.length, (index) {
            final isSelected = _currentPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 6,
              width: isSelected ? 20 : 6,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                      )
                    : null,
                color: isSelected ? null : Colors.grey.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _ProductCard extends ConsumerStatefulWidget {
  final CatalogItem product;
  final bool showTrendingBadge;

  const _ProductCard({required this.product, required this.showTrendingBadge});

  @override
  ConsumerState<_ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends ConsumerState<_ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = widget.product.title;

    final hasActiveFlashSale = PriceHelper.isFlashSaleActive(widget.product);
    final effectivePrice = PriceHelper.getEffectivePrice(widget.product);
    final originalPriceStr = '₹${widget.product.basePrice.toStringAsFixed(0)}';
    final effectivePriceStr = '₹${effectivePrice.toStringAsFixed(0)}';

    final discount = widget.product.metadata['discount'] as String? ?? '';
    final imageUrl = widget.product.imageUrls.isNotEmpty
        ? widget.product.imageUrls.first
        : null;

    final cartItems = ref.watch(cartControllerProvider);
    CartItem? matchingCartItem;
    for (final item in cartItems) {
      if (item.productId == widget.product.id) {
        matchingCartItem = item;
        break;
      }
    }

    final wishlistAsync = ref.watch(wishlistStreamProvider);
    final isInWishlist = wishlistAsync.maybeWhen(
      data: (items) => items.any((i) => i.id == widget.product.id),
      orElse: () => false,
    );

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        context.push('/buyer/home/product/${widget.product.id}');
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: Tween(
          begin: 1.0,
          end: 0.96,
        ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)),
        child: GlassCardWidget(
          padding: const EdgeInsets.all(8),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image Frame
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: SizedBox.expand(
                                child: imageUrl.startsWith('http')
                                    ? Image.network(imageUrl, fit: BoxFit.cover)
                                    : Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: FloatingProductWidget(
                                            floatHeight: 6,
                                            child: Image.asset(
                                              imageUrl,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                      ),
                              ),
                            )
                          : Center(
                              child: FloatingProductWidget(
                                floatHeight: 6,
                                child: Image.asset(
                                  'assets/images/3d/product_headphones.png',
                                  width: 90,
                                  height: 90,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                    ),
                    if (widget.showTrendingBadge)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFA855F7), Color(0xFFEC4899)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🔥 Trending',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      )
                    else if (discount.isNotEmpty)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            discount,
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    // Rating pill bottom-left
                    Positioned(
                      bottom: 6,
                      left: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFFBBF24),
                              size: 8,
                            ),
                            const SizedBox(width: 1),
                            Text(
                              '4.8',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Wishlist button
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: () {
                          final notifier = ref.read(
                            wishlistControllerProvider.notifier,
                          );
                          if (isInWishlist) {
                            notifier.removeFromWishlist(widget.product.id);
                          } else {
                            notifier.addToWishlist(widget.product);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: isInWishlist
                                ? const Color(0xFFEC4899).withValues(alpha: 0.9)
                                : Colors.black.withValues(alpha: 0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isInWishlist
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: isDark ? Colors.white : AppColors.lightTextPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // Price Gradient and Plus Button row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: hasActiveFlashSale
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                originalPriceStr,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.grey,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              GradientText(
                                effectivePriceStr,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : GradientText(
                            originalPriceStr,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                            ),
                          ),
                  ),
                  if (matchingCartItem != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(cartControllerProvider.notifier)
                                .updateQuantity(matchingCartItem!.id, -1);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.remove,
                              color: isDark ? Colors.white : Colors.black87,
                              size: 10,
                              key: const ValueKey('remove_btn'),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text(
                            '${matchingCartItem.quantity}',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            ref
                                .read(cartControllerProvider.notifier)
                                .updateQuantity(matchingCartItem!.id, 1);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 10,
                            ),
                          ),
                        ),
                      ],
                    )
                  else
                    GestureDetector(
                      onTap: () async {
                        if (_isAdding) return;
                        setState(() => _isAdding = true);
                        try {
                          final cartItem = CartItem(
                            id: widget.product.id,
                            productId: widget.product.id,
                            title: widget.product.title,
                            storeId: widget.product.storeId,
                            storeName:
                                widget.product.metadata['storeName']
                                    as String? ??
                                'Seller Store',
                            unitPrice: effectivePrice,
                            imageUrl: widget.product.imageUrls.isNotEmpty
                                ? widget.product.imageUrls.first
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
                                content: Text(
                                  '${widget.product.title} added to cart!',
                                ),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(milliseconds: 1500),
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to add: $e'),
                                backgroundColor: const Color(0xFFEF4444),
                              ),
                            );
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isAdding = false);
                          }
                        }
                      },
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                          ),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFF7C3AED,
                              ).withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isAdding
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 1.5,
                                ),
                              )
                            : const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 14,
                              ),
                      ),
                    ),
                ],
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
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _rippleController,
                    builder: (context, child) {
                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          _buildRippleCircle(1.0),
                          _buildRippleCircle(0.7),
                          _buildRippleCircle(0.4),
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
