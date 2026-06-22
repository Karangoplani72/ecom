import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/constants/app_radius.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_common.dart';
import 'package:ecom/features/admin/presentation/widgets/admin_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

final _adminProductsProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(firebaseFirestoreProvider)
      .collection('catalog')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((s) => s.docs
          .map((d) => {'id': d.id, ...d.data()})
          .toList());
});

final _storeNameProvider = FutureProvider.family<String, String>((ref, storeId) async {
  if (storeId.isEmpty) return 'Unknown Seller';
  final doc = await ref.read(firebaseFirestoreProvider)
      .collection('stores')
      .doc(storeId)
      .get();
  if (doc.exists) {
    final data = doc.data();
    return data?['storeName'] as String? ?? 'Unknown Seller';
  }
  return 'Unknown Seller';
});

class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  String _search = '';
  String _statusFilter = 'all';
  final Set<String> _selectedProductIds = {};

  Future<void> _batchMakeFlash(BuildContext context, List<String> productIds) async {
    final schedule = await _showFlashSaleDurationDialog(context);
    if (schedule == null) return;

    final firestore = ref.read(firebaseFirestoreProvider);
    final batch = firestore.batch();

    for (final id in productIds) {
      final docRef = firestore.collection('catalog').doc(id);
      batch.update(docRef, {
        'metadata.isFlashDeal': true,
        'metadata.flashSaleStartsAt': Timestamp.fromDate(schedule.startsAt),
        'metadata.flashSaleEndsAt': Timestamp.fromDate(schedule.endsAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully added ${productIds.length} products to Flash Deals'),
        ),
      );
      setState(() => _selectedProductIds.clear());
    }
  }

  Future<void> _batchRemoveFlash(BuildContext context, List<String> productIds) async {
    final firestore = ref.read(firebaseFirestoreProvider);
    final batch = firestore.batch();

    for (final id in productIds) {
      final docRef = firestore.collection('catalog').doc(id);
      batch.update(docRef, {
        'metadata.isFlashDeal': false,
        'metadata.flashSaleStartsAt': FieldValue.delete(),
        'metadata.flashSaleEndsAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed ${productIds.length} products from Flash Deals'),
        ),
      );
      setState(() => _selectedProductIds.clear());
    }
  }

  Widget _buildFloatingSelectionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => setState(() => _selectedProductIds.clear()),
            ),
            Text(
              '${_selectedProductIds.length} selected',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              style: TextButton.styleFrom(
                minimumSize: const Size(80, 36),
              ),
              onPressed: () => _batchRemoveFlash(context, _selectedProductIds.toList()),
              child: const Text('Remove Flash', style: TextStyle(color: Colors.orange)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(80, 36),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _batchMakeFlash(context, _selectedProductIds.toList()),
              child: const Text('Make Flash'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(_adminProductsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFmt =
        NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return AdminScaffold(
      title: 'Products',
      subtitle: 'Browse and moderate all catalog products',
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border:
                            OutlineInputBorder(borderRadius: AppRadius.borderLG),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (v) => setState(() => _search = v),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final f in [
                            ('all', 'All'),
                            ('active', 'Active'),
                            ('inactive', 'Inactive'),
                            ('outOfStock', 'Out of Stock'),
                          ])
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(f.$2),
                                selected: _statusFilter == f.$1,
                                onSelected: (_) =>
                                    setState(() => _statusFilter = f.$1),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: productsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, stack) => Center(
                    child: AdminEmptyRow(
                      icon: Icons.cloud_off_rounded,
                      message: e.toString(),
                    ),
                  ),
                  data: (products) {
                    final filtered = products.where((p) {
                      final title = (p['title'] as String? ?? '').toLowerCase();
                      final matchesSearch = _search.isEmpty ||
                          title.contains(_search.toLowerCase());

                      bool matchesStatus;
                      switch (_statusFilter) {
                        case 'active':
                          matchesStatus = p['isActive'] == true;
                          break;
                        case 'inactive':
                          matchesStatus = p['isActive'] == false;
                          break;
                        case 'outOfStock':
                          final stock = (p['metadata'] as Map<String, dynamic>?)?['stock'] as int? ?? 0;
                          matchesStatus = stock == 0;
                          break;
                        default:
                          matchesStatus = true;
                      }

                      return matchesSearch && matchesStatus;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const AdminEmptyRow(
                        icon: Icons.inventory_2_outlined,
                        message: 'No products match your filters.',
                      );
                    }

                    return ListView.separated(
                      padding: const EdgeInsets.only(
                        left: 20,
                        right: 20,
                        top: 12,
                        bottom: 80,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                      itemBuilder: (ctx, i) {
                        final product = filtered[i];
                        final productId = product['id'] as String;
                        return _ProductTile(
                          product: product,
                          currencyFmt: currencyFmt,
                          isSelected: _selectedProductIds.contains(productId),
                          onSelectedChanged: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedProductIds.add(productId);
                              } else {
                                _selectedProductIds.remove(productId);
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          if (_selectedProductIds.isNotEmpty)
            Positioned(
              left: 20,
              right: 20,
              bottom: 20,
              child: _buildFloatingSelectionBar(),
            ),
        ],
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final Map<String, dynamic> product;
  final NumberFormat currencyFmt;
  final bool isSelected;
  final ValueChanged<bool> onSelectedChanged;

  const _ProductTile({
    required this.product,
    required this.currencyFmt,
    required this.isSelected,
    required this.onSelectedChanged,
  });

  String _getFlashRemainingLabel(DateTime? startsAt, DateTime? endsAt) {
    final now = DateTime.now();
    if (startsAt != null && now.isBefore(startsAt)) {
      return 'Flash (Sched)';
    }
    if (endsAt == null) return 'Flash';
    final diff = endsAt.difference(now);
    if (diff.isNegative) return 'Flash (Exp)';
    if (diff.inHours > 0) {
      return 'Flash (${diff.inHours}h)';
    } else {
      return 'Flash (${diff.inMinutes}m)';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isActive = product['isActive'] as bool? ?? true;
    final isFlashDeal = (product['metadata'] as Map<String, dynamic>?)?['isFlashDeal'] as bool? ?? false;
    final stockQty = (product['metadata'] as Map<String, dynamic>?)?['stock'] as int? ?? 0;
    final price = (product['basePrice'] as num?)?.toDouble() ?? 0;
    final imageUrl = (product['imageUrls'] as List?)?.isNotEmpty == true
        ? (product['imageUrls'] as List).first as String?
        : null;

    final storeId = product['storeId'] as String? ?? '';
    final storeNameAsync = ref.watch(_storeNameProvider(storeId));

    final startsAtVal = (product['metadata'] as Map<String, dynamic>?)?['flashSaleStartsAt'];
    DateTime? startsAt;
    if (startsAtVal != null) {
      if (startsAtVal is Timestamp) {
        startsAt = startsAtVal.toDate();
      } else if (startsAtVal is String) {
        startsAt = DateTime.tryParse(startsAtVal);
      }
    }

    final endsAtVal = (product['metadata'] as Map<String, dynamic>?)?['flashSaleEndsAt'];
    DateTime? endsAt;
    if (endsAtVal != null) {
      if (endsAtVal is Timestamp) {
        endsAt = endsAtVal.toDate();
      } else if (endsAtVal is String) {
        endsAt = DateTime.tryParse(endsAtVal);
      }
    }
    final isExpired = endsAt != null && DateTime.now().isAfter(endsAt);

    return AdminSectionCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Checkbox(
            value: isSelected,
            activeColor: AppColors.primary,
            onChanged: (val) => onSelectedChanged(val ?? false),
          ),
          const SizedBox(width: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: imageUrl != null
                ? Image.network(
                    imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => _fallbackImage(),
                  )
                : _fallbackImage(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['title'] as String? ?? 'Unnamed Product',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                storeNameAsync.when(
                  data: (storeName) => Text(
                    'Seller: $storeName',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : AppColors.lightTextSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  loading: () => const Text(
                    'Seller: Loading...',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  error: (err, stack) => const Text(
                    'Seller: Unknown',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      currencyFmt.format(price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock: $stockQty',
                      style: TextStyle(
                        fontSize: 11,
                        color: stockQty == 0
                            ? AppColors.error
                            : (isDark
                                ? Colors.white54
                                : AppColors.lightTextSecondary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminStatusPill(
                    label: isActive ? 'Active' : 'Inactive',
                    color: isActive ? AppColors.success : AppColors.error,
                  ),
                  if (isFlashDeal) ...[
                    const SizedBox(width: 4),
                    AdminStatusPill(
                      label: isExpired
                          ? 'Flash (Exp)'
                          : (startsAt != null && DateTime.now().isBefore(startsAt)
                              ? 'Flash (Sched)'
                              : _getFlashRemainingLabel(startsAt, endsAt)),
                      color: isExpired
                          ? Colors.grey
                          : (startsAt != null && DateTime.now().isBefore(startsAt)
                              ? Colors.blue
                              : const Color(0xFFEF4444)),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                width: 90,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor:
                        isActive ? AppColors.error : AppColors.success,
                    side: BorderSide(
                      color: isActive ? AppColors.error : AppColors.success,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () async {
                    await ref
                        .read(firebaseFirestoreProvider)
                        .collection('catalog')
                        .doc(product['id'] as String)
                        .update({
                      'isActive': !isActive,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isActive ? 'Product deactivated' : 'Product activated',
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    isActive ? 'Deactivate' : 'Activate',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                width: 90,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor:
                        isFlashDeal ? Colors.orange : AppColors.primary,
                    side: BorderSide(
                      color: isFlashDeal ? Colors.orange : AppColors.primary,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  onPressed: () async {
                    if (isFlashDeal) {
                      await ref
                          .read(firebaseFirestoreProvider)
                          .collection('catalog')
                          .doc(product['id'] as String)
                          .update({
                        'metadata.isFlashDeal': false,
                        'metadata.flashSaleStartsAt': FieldValue.delete(),
                        'metadata.flashSaleEndsAt': FieldValue.delete(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Removed from Flash Deals'),
                          ),
                        );
                      }
                    } else {
                      final schedule = await _showFlashSaleDurationDialog(context);
                      if (schedule != null) {
                        await ref
                            .read(firebaseFirestoreProvider)
                            .collection('catalog')
                            .doc(product['id'] as String)
                            .update({
                          'metadata.isFlashDeal': true,
                          'metadata.flashSaleStartsAt': Timestamp.fromDate(schedule.startsAt),
                          'metadata.flashSaleEndsAt': Timestamp.fromDate(schedule.endsAt),
                          'updatedAt': FieldValue.serverTimestamp(),
                        });
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Added to Flash Deals'),
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: Text(
                    isFlashDeal ? 'Remove Flash' : 'Make Flash',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fallbackImage() {
    return Container(
      width: 56,
      height: 56,
      color: AppColors.primary.withValues(alpha: 0.08),
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}

class FlashSaleSchedule {
  final DateTime startsAt;
  final DateTime endsAt;
  FlashSaleSchedule({required this.startsAt, required this.endsAt});
}

Future<FlashSaleSchedule?> _showFlashSaleDurationDialog(BuildContext outerContext) async {
  final hoursController = TextEditingController(text: '1');
  bool startImmediately = true;
  DateTime customStartsAt = DateTime.now().add(const Duration(minutes: 5));
  bool usePresetDuration = true;
  int? selectedHoursPreset = 1;
  DateTime customEndsAt = DateTime.now().add(const Duration(hours: 1, minutes: 5));

  return showDialog<FlashSaleSchedule>(
    context: outerContext,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      return StatefulBuilder(
        builder: (builderContext, setDialogState) {
          final now = DateTime.now();
          final activeStartsAt = startImmediately ? now : customStartsAt;

          DateTime activeEndsAt;
          if (usePresetDuration) {
            final hrsText = hoursController.text.trim();
            final hrs = int.tryParse(hrsText) ?? 1;
            activeEndsAt = activeStartsAt.add(Duration(hours: hrs));
          } else {
            activeEndsAt = customEndsAt;
          }

          final startStr = startImmediately
              ? 'Immediately (Now)'
              : DateFormat('MMM d, yyyy, h:mm a').format(activeStartsAt);

          final endStr = DateFormat('MMM d, yyyy, h:mm a').format(activeEndsAt);

          final durationDiff = activeEndsAt.difference(activeStartsAt);
          String durationStr = '';
          if (durationDiff.isNegative) {
            durationStr = 'Invalid (Ends before Start)';
          } else if (durationDiff.inDays > 0) {
            durationStr = '${durationDiff.inDays}d ${durationDiff.inHours % 24}h';
          } else if (durationDiff.inHours > 0) {
            durationStr = '${durationDiff.inHours}h ${durationDiff.inMinutes % 60}m';
          } else {
            durationStr = '${durationDiff.inMinutes}m';
          }

          return AlertDialog(
            backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'Schedule Flash Sale',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure start and end details for this flash sale.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Start Time',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Immediately'),
                        selected: startImmediately,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              startImmediately = true;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Schedule Start'),
                        selected: !startImmediately,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              startImmediately = false;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (!startImmediately) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: builderContext,
                            initialDate: customStartsAt,
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 365)),
                          );
                          if (pickedDate == null) return;
                          if (!builderContext.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: builderContext,
                            initialTime: TimeOfDay.fromDateTime(customStartsAt),
                          );
                          if (pickedTime == null) return;

                          setDialogState(() {
                            customStartsAt = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.access_time_rounded, size: 16),
                        label: Text('Starts: ${DateFormat('MMM d, h:mm a').format(customStartsAt)}'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'End Time',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Preset Duration'),
                        selected: usePresetDuration,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              usePresetDuration = true;
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Specific Date/Time'),
                        selected: !usePresetDuration,
                        onSelected: (selected) {
                          if (selected) {
                            setDialogState(() {
                              usePresetDuration = false;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  if (usePresetDuration) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final hrs in [1, 3, 6, 12, 24])
                          ChoiceChip(
                            label: Text('$hrs ${hrs == 1 ? 'Hour' : 'Hours'}'),
                            selected: selectedHoursPreset == hrs,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedHoursPreset = hrs;
                                  hoursController.text = hrs.toString();
                                });
                              }
                            },
                          ),
                        ChoiceChip(
                          label: const Text('Custom Hrs'),
                          selected: selectedHoursPreset == null,
                          onSelected: (selected) {
                            if (selected) {
                              setDialogState(() {
                                selectedHoursPreset = null;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    if (selectedHoursPreset == null) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: hoursController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Duration in Hours',
                          hintText: 'Enter hours (e.g. 5)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (_) {
                          setDialogState(() {});
                        },
                      ),
                    ],
                  ] else ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final pickedDate = await showDatePicker(
                            context: builderContext,
                            initialDate: customEndsAt.isBefore(activeStartsAt) ? activeStartsAt.add(const Duration(hours: 1)) : customEndsAt,
                            firstDate: activeStartsAt,
                            lastDate: activeStartsAt.add(const Duration(days: 365)),
                          );
                          if (pickedDate == null) return;
                          if (!builderContext.mounted) return;
                          final pickedTime = await showTimePicker(
                            context: builderContext,
                            initialTime: TimeOfDay.fromDateTime(customEndsAt),
                          );
                          if (pickedTime == null) return;

                          setDialogState(() {
                            customEndsAt = DateTime(
                              pickedDate.year,
                              pickedDate.month,
                              pickedDate.day,
                              pickedTime.hour,
                              pickedTime.minute,
                            );
                          });
                        },
                        icon: const Icon(Icons.calendar_month_rounded, size: 16),
                        label: Text('Ends: ${DateFormat('MMM d, h:mm a').format(customEndsAt)}'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkSurface.withValues(alpha: 0.5) : AppColors.lightSurface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.event_available_rounded, color: AppColors.success, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Start: $startStr',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.event_busy_rounded, color: AppColors.error, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'End: $endStr',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Duration:',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                            Text(
                              durationStr,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: durationDiff.isNegative ? AppColors.error : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(builderContext).pop(),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  final finalStartsAt = startImmediately ? DateTime.now() : customStartsAt;
                  DateTime finalEndsAt;
                  if (usePresetDuration) {
                    final hoursText = hoursController.text.trim();
                    final hours = int.tryParse(hoursText);
                    if (hours == null || hours <= 0) {
                      ScaffoldMessenger.of(builderContext).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid number of hours')),
                      );
                      return;
                    }
                    finalEndsAt = finalStartsAt.add(Duration(hours: hours));
                  } else {
                    finalEndsAt = customEndsAt;
                  }

                  if (finalEndsAt.isBefore(finalStartsAt)) {
                    ScaffoldMessenger.of(builderContext).showSnackBar(
                      const SnackBar(content: Text('End date/time must be after start date/time')),
                    );
                    return;
                  }

                  if (finalEndsAt.isBefore(DateTime.now())) {
                    ScaffoldMessenger.of(builderContext).showSnackBar(
                      const SnackBar(content: Text('End date/time must be in the future')),
                    );
                    return;
                  }

                  Navigator.of(builderContext).pop(
                    FlashSaleSchedule(startsAt: finalStartsAt, endsAt: finalEndsAt),
                  );
                },
                child: const Text('Set Flash'),
              ),
            ],
          );
        },
      );
    },
  );
}
