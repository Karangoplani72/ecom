import 'dart:ui';

import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/buyer/presentation/widgets/buyer_anti_gravity_widgets.dart';
import 'package:ecom/features/orders/domain/entities/order.dart';
import 'package:ecom/features/orders/domain/entities/order_item.dart';
import 'package:ecom/features/orders/domain/entities/order_status.dart';
import 'package:ecom/features/orders/presentation/controllers/order_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class BuyerOrdersScreen extends ConsumerWidget {
  const BuyerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(buyerOrdersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.darkBgPrimary
            : AppColors.lightBgPrimary,
        body: Stack(
          children: [
            const IgnorePointer(child: OrbBackgroundWidget()),
            ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF7C3AED)),
              ),
              error: (error, _) => Center(
                child: Text(
                  'Error: $error',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
              data: (orders) {
                final activeOrders = orders.where((o) {
                  return o.status == OrderStatus.pending ||
                      o.status == OrderStatus.confirmed ||
                      o.status == OrderStatus.packed ||
                      o.status == OrderStatus.shipped ||
                      o.status == OrderStatus.outForDelivery;
                }).toList();

                final deliveredOrders = orders.where((o) {
                  return o.status == OrderStatus.delivered;
                }).toList();

                final cancelledOrders = orders.where((o) {
                  return o.status == OrderStatus.cancelled ||
                      o.status == OrderStatus.refunded;
                }).toList();

                return NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        floating: true,
                        pinned: true,
                        snap: true,
                        forceElevated: innerBoxIsScrolled,
                        leadingWidth: 70,
                        leading: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Center(
                            child: _buildFrostedCircleButton(
                              icon: Icons.arrow_back_ios_new_rounded,
                              onPressed: () => context.pop(),
                              isDark: isDark,
                            ),
                          ),
                        ),
                        title: Text(
                          'My Orders',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        centerTitle: true,
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(50),
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Container(
                                color: Colors.transparent,
                                child: TabBar(
                                  indicatorColor: const Color(0xFF7C3AED),
                                  indicatorWeight: 3,
                                  labelColor: const Color(0xFF7C3AED),
                                  unselectedLabelColor: isDark
                                      ? Colors.white54
                                      : Colors.black54,
                                  labelStyle: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                  tabs: const [
                                    Tab(text: 'All'),
                                    Tab(text: 'Active'),
                                    Tab(text: 'Delivered'),
                                    Tab(text: 'Cancelled'),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
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
                                          AppColors.darkBgPrimary.withValues(
                                            alpha: 0.95,
                                          ),
                                          AppColors.darkBgPrimary.withValues(
                                            alpha: 0.6,
                                          ),
                                        ]
                                      : [
                                          AppColors.lightBgPrimary.withValues(
                                            alpha: 0.95,
                                          ),
                                          AppColors.lightBgPrimary.withValues(
                                            alpha: 0.6,
                                          ),
                                        ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ];
                  },
                  body: TabBarView(
                    children: [
                      _OrdersTabList(
                        orders: orders,
                        emptyMsg: 'No orders placed yet.',
                      ),
                      _OrdersTabList(
                        orders: activeOrders,
                        emptyMsg: 'No active orders in progress.',
                      ),
                      _OrdersTabList(
                        orders: deliveredOrders,
                        emptyMsg: 'No delivered orders.',
                      ),
                      _OrdersTabList(
                        orders: cancelledOrders,
                        emptyMsg: 'No cancelled orders.',
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrostedCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.04),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.12 : 0.2),
        ),
      ),
      child: Center(
        child: IconButton(
          padding: EdgeInsets.zero,
          icon: Icon(
            icon,
            size: 16,
            color: isDark ? Colors.white : AppColors.lightTextPrimary,
          ),
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _OrdersTabList extends StatelessWidget {
  final List<AppOrder> orders;
  final String emptyMsg;

  const _OrdersTabList({required this.orders, required this.emptyMsg});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;

    if (orders.isEmpty) {
      return Center(
        child: GlassCardWidget(
          padding: const EdgeInsets.all(28),
          borderRadius: 24,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.receipt_long_outlined,
                size: 54,
                color: Color(0xFF7C3AED),
              ),
              const SizedBox(height: 16),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      physics: const BouncingScrollPhysics(),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _InteractiveOrderCard(order: order);
      },
    );
  }
}

class _InteractiveOrderCard extends StatefulWidget {
  final AppOrder order;

  const _InteractiveOrderCard({required this.order});

  @override
  State<_InteractiveOrderCard> createState() => _InteractiveOrderCardState();
}

class _InteractiveOrderCardState extends State<_InteractiveOrderCard>
    with SingleTickerProviderStateMixin {
  bool _isTimelineExpanded = false;
  late final AnimationController _pressController;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.lightTextPrimary;
    final formattedDate = DateFormat(
      'MMM d, yyyy',
    ).format(widget.order.createdAt);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTapDown: (_) => _pressController.forward(),
        onTapUp: (_) {
          _pressController.reverse();
          context.push('/buyer/orders/${widget.order.orderId}');
        },
        onTapCancel: () => _pressController.reverse(),
        child: ScaleTransition(
          scale: Tween(begin: 1.0, end: 0.98).animate(
            CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
          ),
          child: GlassCardWidget(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Store Name and Status Pill
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.order.storeName,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    _buildStatusPill(widget.order.status),
                  ],
                ),
                const SizedBox(height: 12),

                // Thumbnails / Date and Price Row
                Row(
                  children: [
                    _buildThumbnailStack(widget.order.items),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order Date: $formattedDate',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecond
                                  : AppColors.lightTextSecond,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'ID: #${widget.order.orderId.substring(0, 8).toUpperCase()}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecond
                                  : AppColors.lightTextSecond,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        GradientText(
                          '₹${widget.order.totalAmount.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        // Timeline expand toggler
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isTimelineExpanded = !_isTimelineExpanded;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Icon(
                              _isTimelineExpanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 20,
                              color: const Color(0xFF7C3AED),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Inline Timeline Expandable
                AnimatedSize(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: _isTimelineExpanded
                      ? Column(
                          children: [
                            const Divider(height: 24),
                            _buildHorizontalTimeline(widget.order.status),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusPill(OrderStatus status) {
    String label = '';
    Gradient gradient = const LinearGradient(
      colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
    );

    switch (status) {
      case OrderStatus.pending:
      case OrderStatus.confirmed:
      case OrderStatus.packed:
        label = 'Processing';
        gradient = const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
        );
        break;
      case OrderStatus.shipped:
      case OrderStatus.outForDelivery:
        label = 'In Transit';
        gradient = const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF0EA5E9)],
        );
        break;
      case OrderStatus.delivered:
        label = 'Delivered';
        gradient = const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
        );
        break;
      case OrderStatus.cancelled:
      case OrderStatus.returnRequested:
      case OrderStatus.returnApproved:
      case OrderStatus.returnRejected:
      case OrderStatus.refunded:
        label = 'Returns & Refunds';
        gradient = const LinearGradient(
          colors: [Color(0xFFEF4444), Color(0xFFF87171)],
        );
        break;
      case OrderStatus.returned:
        // TODO: Handle this case.
        throw UnimplementedError();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildThumbnailStack(List<OrderItem> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    if (items.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: items.first.imageUrl.startsWith('http')
            ? Image.network(
                items.first.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              )
            : Image.asset(
                items.first.imageUrl,
                width: 48,
                height: 48,
                fit: BoxFit.contain,
              ),
      );
    }

    // Stack thumbnails
    return SizedBox(
      width: 60,
      height: 48,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: items[0].imageUrl.startsWith('http')
                  ? Image.network(
                      items[0].imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      items[0].imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.contain,
                    ),
            ),
          ),
          Positioned(
            left: 16,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: items[1].imageUrl.startsWith('http')
                    ? Image.network(
                        items[1].imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        items[1].imageUrl,
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                      ),
              ),
            ),
          ),
          if (items.length > 2)
            Positioned(
              left: 20,
              top: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFFA855F7)],
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '+${items.length - 2}',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTimeline(OrderStatus status) {
    final steps = ['Placed', 'Confirmed', 'Shipped', 'Delivered'];
    int currentStepIndex = 0;

    if (status == OrderStatus.pending) currentStepIndex = 0;
    if (status == OrderStatus.confirmed || status == OrderStatus.packed) {
      currentStepIndex = 1;
    }
    if (status == OrderStatus.shipped || status == OrderStatus.outForDelivery) {
      currentStepIndex = 2;
    }
    if (status == OrderStatus.delivered) currentStepIndex = 3;

    final isCancelled =
        status == OrderStatus.cancelled || status == OrderStatus.refunded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: isCancelled
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.cancel_outlined, color: Colors.redAccent),
                const SizedBox(width: 8),
                Text(
                  'Order Cancelled / Refunded',
                  style: GoogleFonts.inter(
                    color: Colors.redAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(steps.length, (index) {
                final label = steps[index];
                final isDone = index < currentStepIndex;
                final isCurrent = index == currentStepIndex;

                return Column(
                  children: [
                    if (isCurrent)
                      const PulsingDot(size: 6, color: Color(0xFF7C3AED))
                    else
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF7C3AED)
                              : Colors.grey.shade600,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: isCurrent || isDone
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isCurrent || isDone
                            ? const Color(0xFF7C3AED)
                            : Colors.grey,
                      ),
                    ),
                  ],
                );
              }),
            ),
    );
  }
}
