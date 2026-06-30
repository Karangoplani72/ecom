import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:ecom/features/buyer/data/dtos/coupon_dto.dart';
import 'package:ecom/features/buyer/domain/entities/coupon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

final adminCouponsProvider = StreamProvider<List<Coupon>>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore
      .collection('coupons')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (s) =>
            s.docs.map((d) => CouponDto.fromFirestore(d).toDomain()).toList(),
      );
});

final adminDiscountGivenProvider = StreamProvider<double>((ref) {
  final firestore = ref.watch(firebaseFirestoreProvider);
  return firestore.collection('orders').snapshots().map((s) {
    double sum = 0.0;
    for (final doc in s.docs) {
      final data = doc.data();
      if (data['couponCode'] != null) {
        sum += (data['discount'] as num?)?.toDouble() ?? 0.0;
      }
    }
    return sum;
  });
});

class AdminCouponsScreen extends ConsumerStatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  ConsumerState<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends ConsumerState<AdminCouponsScreen> {
  String _search = '';
  String _statusFilter = 'all'; // all, active, expired, inactive

  @override
  Widget build(BuildContext context) {
    final couponsAsync = ref.watch(adminCouponsProvider);
    final discountAsync = ref.watch(adminDiscountGivenProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AdminScaffold(
      title: 'Coupon Management',
      subtitle: 'Create and configure coupon discount codes',
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        onPressed: () => _showCouponForm(context),
        child: const Icon(Icons.add),
      ),
      body: couponsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: AdminEmptyRow(
            icon: Icons.error_outline_rounded,
            message: err.toString(),
          ),
        ),
        data: (coupons) {
          final totalCoupons = coupons.length;
          final activeCoupons = coupons
              .where(
                (c) =>
                    c.isActive &&
                    (c.expiryDate == null ||
                        c.expiryDate!.isAfter(DateTime.now())),
              )
              .length;
          final expiredCoupons = coupons
              .where(
                (c) =>
                    c.expiryDate != null &&
                    c.expiryDate!.isBefore(DateTime.now()),
              )
              .length;
          final totalDiscount = discountAsync.value ?? 0.0;

          final currencyFmt = NumberFormat.currency(
            locale: 'en_IN',
            symbol: '₹',
            decimalDigits: 0,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats Row
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: AdminMetricGrid(
                  metrics: [
                    AdminMetricCard(
                      label: 'Total Coupons',
                      value: totalCoupons.toString(),
                      icon: Icons.local_offer_outlined,
                      color: AppColors.primary,
                    ),
                    AdminMetricCard(
                      label: 'Active Coupons',
                      value: activeCoupons.toString(),
                      icon: Icons.check_circle_outline_rounded,
                      color: AppColors.success,
                    ),
                    AdminMetricCard(
                      label: 'Expired Coupons',
                      value: expiredCoupons.toString(),
                      icon: Icons.history_rounded,
                      color: const Color(0xFFF59E0B),
                    ),
                    AdminMetricCard(
                      label: 'Total Discount Given',
                      value: currencyFmt.format(totalDiscount),
                      icon: Icons.card_giftcard_rounded,
                      color: const Color(0xFF10B981),
                    ),
                  ],
                ),
              ),

              // Filter & Search bar
              Container(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final tab in [
                            ('all', 'All'),
                            ('active', 'Active'),
                            ('expired', 'Expired'),
                            ('inactive', 'Inactive'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(tab.$2),
                                selected: _statusFilter == tab.$1,
                                onSelected: (_) =>
                                    setState(() => _statusFilter = tab.$1),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: GoogleFonts.inter(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by coupon code...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),

              // List of coupons
              Expanded(
                child: Builder(
                  builder: (context) {
                    final filtered = coupons.where((c) {
                      // Filter by search query
                      if (_search.isNotEmpty &&
                          !c.code.toLowerCase().contains(
                            _search.toLowerCase(),
                          )) {
                        return false;
                      }

                      // Filter by status tab
                      final isExpired =
                          c.expiryDate != null &&
                          c.expiryDate!.isBefore(DateTime.now());
                      if (_statusFilter == 'active' &&
                          (!c.isActive || isExpired)) {
                        return false;
                      }
                      if (_statusFilter == 'expired' && !isExpired) {
                        return false;
                      }
                      if (_statusFilter == 'inactive' && c.isActive) {
                        return false;
                      }

                      return true;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const AdminEmptyRow(
                        icon: Icons.local_offer_outlined,
                        message: 'No coupons match your filters.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (ctx, i) => _CouponCard(coupon: filtered[i]),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCouponForm(BuildContext context, [Coupon? coupon]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CouponFormSheet(coupon: coupon),
    );
  }
}

class _CouponCard extends ConsumerWidget {
  final Coupon coupon;

  const _CouponCard({required this.coupon});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isExpired =
        coupon.expiryDate != null &&
        coupon.expiryDate!.isBefore(DateTime.now());

    Color statusColor = AppColors.success;
    String statusLabel = 'ACTIVE';

    if (!coupon.isActive) {
      statusColor = Colors.grey;
      statusLabel = 'INACTIVE';
    } else if (isExpired) {
      statusColor = const Color(0xFFF59E0B);
      statusLabel = 'EXPIRED';
    }

    final dateFmt = DateFormat('dd MMM yyyy');
    final currencyFmt = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: 0,
    );

    return AdminSectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                coupon.code,
                style: GoogleFonts.firaCode(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Row(
                children: [
                  if (coupon.isFirstOrderOnly) ...[
                    AdminStatusPill(
                      label: 'FIRST ORDER',
                      color: AppColors.primary.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 8),
                  ],
                  AdminStatusPill(label: statusLabel, color: statusColor),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(20),
                          ),
                        ),
                        builder: (_) => _CouponFormSheet(coupon: coupon),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coupon.discountType == 'percentage'
                        ? '${coupon.value.toStringAsFixed(0)}% OFF'
                        : '${currencyFmt.format(coupon.value)} OFF',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    coupon.minOrderValue > 0
                        ? 'Min Order: ${currencyFmt.format(coupon.minOrderValue)}'
                        : 'No minimum order',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white54
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Expiry: ${coupon.expiryDate == null ? 'Lifetime' : dateFmt.format(coupon.expiryDate!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isExpired
                          ? Colors.red
                          : (isDark
                                ? Colors.white54
                                : AppColors.lightTextSecondary),
                      fontWeight: isExpired
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Usage: ${coupon.usageCount} / ${coupon.totalUsageLimit == 0 ? '∞' : coupon.totalUsageLimit}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? Colors.white54
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Per-user limit: ${coupon.usageLimitPerUser}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white38
                      : AppColors.lightTextSecondary.withValues(alpha: 0.6),
                ),
              ),
              Flexible(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    coupon.isActive
                        ? Icons.block_rounded
                        : Icons.check_circle_outline,
                    size: 14,
                  ),
                  label: Text(
                    coupon.isActive ? 'Deactivate' : 'Activate',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () async {
                    final firestore = ref.read(firebaseFirestoreProvider);
                    await firestore
                        .collection('coupons')
                        .doc(coupon.id)
                        .update({
                          'isActive': !coupon.isActive,
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            coupon.isActive
                                ? 'Coupon ${coupon.code} deactivated'
                                : 'Coupon ${coupon.code} activated',
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CouponFormSheet extends ConsumerStatefulWidget {
  final Coupon? coupon;

  const _CouponFormSheet({this.coupon});

  @override
  ConsumerState<_CouponFormSheet> createState() => _CouponFormSheetState();
}

class _CouponFormSheetState extends ConsumerState<_CouponFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _codeController;
  late final TextEditingController _valueController;
  late final TextEditingController _minOrderController;
  late final TextEditingController _totalUsageController;
  late final TextEditingController _userUsageController;

  String _discountType = 'percentage';
  DateTime? _expiryDate;
  bool _isActive = true;
  bool _isFirstOrderOnly = false;
  bool _hasNoExpiry = false;

  @override
  void initState() {
    super.initState();
    final c = widget.coupon;
    _codeController = TextEditingController(text: c?.code ?? '');
    _valueController = TextEditingController(text: c?.value.toString() ?? '');
    _minOrderController = TextEditingController(
      text: c?.minOrderValue.toString() ?? '0.0',
    );
    _totalUsageController = TextEditingController(
      text: c?.totalUsageLimit.toString() ?? '0',
    );
    _userUsageController = TextEditingController(
      text: c?.usageLimitPerUser.toString() ?? '1',
    );

    if (c != null) {
      _discountType = c.discountType;
      _expiryDate = c.expiryDate;
      _isActive = c.isActive;
      _isFirstOrderOnly = c.isFirstOrderOnly;
      _hasNoExpiry = c.expiryDate == null;
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _valueController.dispose();
    _minOrderController.dispose();
    _totalUsageController.dispose();
    _userUsageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    if (_hasNoExpiry) return;
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate != null && _expiryDate!.isAfter(now)
          ? _expiryDate!
          : now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  void _saveForm() async {
    if (!_formKey.currentState!.validate() ||
        (!_hasNoExpiry && _expiryDate == null)) {
      return;
    }

    final code = _codeController.text.trim().toUpperCase();
    final value = double.parse(_valueController.text.trim());
    final minOrder = double.parse(_minOrderController.text.trim());
    final totalLimit = int.parse(_totalUsageController.text.trim());
    final userLimit = int.parse(_userUsageController.text.trim());

    final firestore = ref.read(firebaseFirestoreProvider);

    final data = {
      'code': code,
      'discountType': _discountType,
      'value': value,
      'minOrderValue': minOrder,
      'expiryDate': _hasNoExpiry ? null : Timestamp.fromDate(_expiryDate!),
      'usageLimitPerUser': userLimit,
      'totalUsageLimit': totalLimit,
      'isActive': _isActive,
      'isFirstOrderOnly': _isFirstOrderOnly,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.coupon == null) {
        // Create new
        data['usageCount'] = 0;
        data['usedBy'] = [];
        data['createdAt'] = FieldValue.serverTimestamp();
        await firestore.collection('coupons').add(data);
      } else {
        // Edit existing
        await firestore
            .collection('coupons')
            .doc(widget.coupon!.id)
            .update(data);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.coupon == null
                  ? 'Coupon created successfully'
                  : 'Coupon updated successfully',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save coupon: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.coupon != null;
    final dateFmt = DateFormat('dd MMM yyyy');
    final screenHeight = MediaQuery.sizeOf(context).height;
    final keyboardHeight = MediaQuery.viewInsetsOf(context).bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: screenHeight * 0.9),
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, keyboardHeight + 24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Coupon' : 'Create Coupon',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Coupon Code
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  maxLength: 20,
                  decoration: const InputDecoration(
                    labelText: 'Coupon Code *',
                    hintText: 'e.g. SUMMER-50',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter coupon code';
                    }
                    final regex = RegExp(r'^[A-Z0-9\-]+$');
                    if (!regex.hasMatch(val.trim().toUpperCase())) {
                      return 'Only uppercase letters, numbers, and hyphens';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Discount Type
                DropdownButtonFormField<String>(
                  // ignore: deprecated_member_use
                  value: _discountType,
                  decoration: const InputDecoration(
                    labelText: 'Discount Type *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'percentage',
                      child: Text('Percentage (%)'),
                    ),
                    DropdownMenuItem(
                      value: 'flat',
                      child: Text('Flat Amount (₹)'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _discountType = v);
                  },
                ),
                const SizedBox(height: 12),

                // Value
                TextFormField(
                  controller: _valueController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: _discountType == 'percentage'
                        ? 'Percentage Value *'
                        : 'Flat Value (₹) *',
                    border: const OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter value';
                    }
                    final num = double.tryParse(val.trim());
                    if (num == null) {
                      return 'Enter a valid number';
                    }
                    if (_discountType == 'percentage') {
                      if (num < 0.01 || num > 100) {
                        return 'Percentage must be between 0.01 and 100';
                      }
                    } else {
                      if (num < 1 || num > 999999) {
                        return 'Flat value must be between 1 and 999999';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Min Order Value
                TextFormField(
                  controller: _minOrderController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Minimum Order Value (₹)',
                    hintText: '0 = No minimum',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val != null && val.trim().isNotEmpty) {
                      final num = double.tryParse(val.trim());
                      if (num == null || num < 0) {
                        return 'Enter a valid positive number';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Expiry Date picker & Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Opacity(
                        opacity: _hasNoExpiry ? 0.5 : 1.0,
                        child: InkWell(
                          onTap: _hasNoExpiry ? null : _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Expiry Date *',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today_rounded),
                            ),
                            child: Text(
                              _expiryDate == null
                                  ? 'Select Date'
                                  : dateFmt.format(_expiryDate!),
                              style: TextStyle(
                                fontSize: 14,
                                color: _expiryDate == null ? Colors.grey : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Lifetime', style: TextStyle(fontSize: 12)),
                        Switch(
                          value: _hasNoExpiry,
                          onChanged: (val) {
                            setState(() {
                              _hasNoExpiry = val;
                              if (val) _expiryDate = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ],
                ),
                if (!_hasNoExpiry && _expiryDate == null)
                  const Padding(
                    padding: EdgeInsets.only(top: 4, left: 12),
                    child: Text(
                      'Expiry date is required',
                      style: TextStyle(color: AppColors.error, fontSize: 12),
                    ),
                  ),
                const SizedBox(height: 12),

                // Usage Limits
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _totalUsageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Total Usage Limit',
                          hintText: '0 = Unlimited',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val.trim());
                          if (n == null || n < 0) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _userUsageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Limit Per User',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Required';
                          }
                          final n = int.tryParse(val.trim());
                          if (n == null || n < 1) {
                            return 'Min 1';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // First Order Only Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('First Order Only'),
                  subtitle: const Text(
                    'Valid only for new customers',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isFirstOrderOnly,
                  onChanged: (val) => setState(() => _isFirstOrderOnly = val),
                ),

                // Active Toggle
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Is Active'),
                  value: _isActive,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _saveForm,
                        child: Text(isEdit ? 'Save Changes' : 'Create Coupon'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
