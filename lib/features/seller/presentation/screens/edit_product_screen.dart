import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/categories_provider.dart';
import 'package:ecom/core/services/cloudinary_service.dart';
import 'package:ecom/core/theme/app_colors.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_network_image.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/app_scaffold.dart';
import 'package:ecom/core/widgets/app_text_field.dart';
import 'package:ecom/features/seller/domain/entities/seller_product.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Data holders
// ─────────────────────────────────────────────────────────────────────────────

class _NewImage {
  final XFile file;
  final Uint8List bytes;

  const _NewImage({required this.file, required this.bytes});
}

class _EditSkuRow {
  final Map<String, String> combination;
  final TextEditingController priceCtrl;
  final TextEditingController compareCtrl;
  final TextEditingController stockCtrl;
  final TextEditingController skuCodeCtrl;
  _NewImage? newSkuImage;
  String? existingImageUrl;

  _EditSkuRow({
    required this.combination,
    double price = 0,
    double? compareAtPrice,
    int stock = 0,
    String? skuCode,
    String? imageUrl,
  }) : priceCtrl = TextEditingController(
         text: price > 0 ? price.toString() : '',
       ),
       compareCtrl = TextEditingController(
         text: compareAtPrice != null ? compareAtPrice.toString() : '',
       ),
       stockCtrl = TextEditingController(text: stock.toString()),
       skuCodeCtrl = TextEditingController(text: skuCode ?? ''),
       existingImageUrl = imageUrl;

  void dispose() {
    priceCtrl.dispose();
    compareCtrl.dispose();
    stockCtrl.dispose();
    skuCodeCtrl.dispose();
  }

  String get skuId =>
      combination.values.join('_').replaceAll(' ', '-').toLowerCase();

  String get label => combination.values.join(' / ');
}

// ─────────────────────────────────────────────────────────────────────────────
// SKU Matrix builder
// ─────────────────────────────────────────────────────────────────────────────

List<Map<String, String>> _buildCombinations(List<VariantAttribute> attrs) {
  if (attrs.isEmpty) return [];
  List<Map<String, String>> combos = [{}];
  for (final attr in attrs) {
    final next = <Map<String, String>>[];
    for (final combo in combos) {
      for (final opt in attr.options) {
        next.add({...combo, attr.name: opt.value});
      }
    }
    combos = next;
  }
  return combos;
}

// ─────────────────────────────────────────────────────────────────────────────
// Variant presets — common types, colors & sizes for an industry-standard UX
// ─────────────────────────────────────────────────────────────────────────────

const List<String> _kVariantTypePresets = [
  'Color',
  'Size',
  'Storage',
  'Material',
  'Style',
  'Flavor',
  'Weight',
  'Pack Size',
  'Capacity',
];

class _ColorPreset {
  final String name;
  final String hex;

  const _ColorPreset(this.name, this.hex);
}

const List<_ColorPreset> _kColorPresets = [
  _ColorPreset('Black', '#000000'),
  _ColorPreset('White', '#FFFFFF'),
  _ColorPreset('Red', '#E53935'),
  _ColorPreset('Blue', '#1E88E5'),
  _ColorPreset('Green', '#43A047'),
  _ColorPreset('Yellow', '#FBC02D'),
  _ColorPreset('Orange', '#FB8C00'),
  _ColorPreset('Pink', '#EC407A'),
  _ColorPreset('Purple', '#8E24AA'),
  _ColorPreset('Grey', '#9E9E9E'),
  _ColorPreset('Brown', '#6D4C41'),
  _ColorPreset('Navy Blue', '#1A237E'),
  _ColorPreset('Maroon', '#800000'),
  _ColorPreset('Beige', '#D2B48C'),
  _ColorPreset('Gold', '#D4AF37'),
  _ColorPreset('Silver', '#C0C0C0'),
];

const List<String> _kSizePresets = [
  'XS',
  'S',
  'M',
  'L',
  'XL',
  'XXL',
  'XXXL',
  'Small',
  'Medium',
  'Large',
  'Free Size',
];

Color _hexToColor(String hex) {
  var h = hex.replaceAll('#', '');
  if (h.length == 6) h = 'FF$h';
  return Color(int.parse(h, radix: 16));
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class EditProductScreen extends ConsumerStatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  static const _statusOptions = ['active', 'inactive', 'archived', 'draft'];

  final _formKey = GlobalKey<FormState>();
  final _scrollCtrl = ScrollController();

  // ── Basic ──────────────────────────────────────────────────────────────────
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String? _selectedCategory;
  String _status = 'active';
  String? _storeId;

  // ── Gallery ────────────────────────────────────────────────────────────────
  List<String> _existingUrls = [];
  final List<_NewImage> _newImages = [];
  bool _isPicking = false;

  // ── Variants ───────────────────────────────────────────────────────────────
  bool _hasVariants = false;
  List<VariantAttribute> _variantAttributes = [];
  List<_EditSkuRow> _skuRows = [];

  // ── Simple ─────────────────────────────────────────────────────────────────
  final _simplePriceCtrl = TextEditingController();
  final _simpleCompareCtrl = TextEditingController();
  final _simpleStockCtrl = TextEditingController(text: '0');

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _brandCtrl.dispose();
    _tagsCtrl.dispose();
    _simplePriceCtrl.dispose();
    _simpleCompareCtrl.dispose();
    _simpleStockCtrl.dispose();
    for (final r in _skuRows) {
      r.dispose();
    }
    super.dispose();
  }

  // ── Load ───────────────────────────────────────────────────────────────────

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('catalog')
          .doc(widget.productId)
          .get();

      if (!doc.exists) {
        setState(() {
          _isLoading = false;
          _loadError = 'Product not found.';
        });
        return;
      }

      final data = doc.data()!;
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (data['storeId'] != currentUid) {
        setState(() {
          _isLoading = false;
          _loadError = "You don't have permission to edit this product.";
        });
        return;
      }

      final meta = (data['metadata'] as Map<String, dynamic>?) ?? {};
      _storeId = data['storeId'] as String;
      _titleCtrl.text = data['title'] as String? ?? '';
      _descCtrl.text = data['description'] as String? ?? '';
      _brandCtrl.text = meta['brand'] as String? ?? '';
      _tagsCtrl.text = ((meta['tags'] as List<dynamic>?) ?? []).join(', ');
      _selectedCategory = meta['category'] as String?;
      _status = data['status'] as String? ?? 'active';
      _existingUrls = List<String>.from((data['imageUrls'] as List?) ?? []);

      final rawAttrs = data['variantAttributes'] as List<dynamic>?;
      final rawSkus = data['variantSkus'] as List<dynamic>?;

      if (rawAttrs != null && rawAttrs.isNotEmpty) {
        _variantAttributes = rawAttrs
            .map(
              (e) =>
                  VariantAttribute.fromMap(Map<String, dynamic>.from(e as Map)),
            )
            .toList();
        _hasVariants = true;

        // Build rows from existing SKUs
        final skuMap = <String, VariantSku>{};
        if (rawSkus != null) {
          for (final e in rawSkus) {
            final sku = VariantSku.fromMap(Map<String, dynamic>.from(e as Map));
            skuMap[sku.skuId] = sku;
          }
        }
        final combos = _buildCombinations(_variantAttributes);
        _skuRows = combos.map((combo) {
          final id = combo.values.join('_').replaceAll(' ', '-').toLowerCase();
          final existing = skuMap[id];
          return _EditSkuRow(
            combination: combo,
            price: existing?.price ?? 0,
            compareAtPrice: existing?.compareAtPrice,
            stock: existing?.stock ?? 0,
            skuCode: existing?.skuCode,
            imageUrl: existing?.imageUrl,
          );
        }).toList();
      } else {
        _hasVariants = false;
        _simplePriceCtrl.text = ((data['basePrice'] as num?) ?? 0).toString();
        _simpleCompareCtrl.text = data['compareAtPrice'] != null
            ? data['compareAtPrice'].toString()
            : '';
        _simpleStockCtrl.text = ((meta['stock'] as num?) ?? 0).toString();
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load: $e';
      });
    }
  }

  // ── Image helpers ──────────────────────────────────────────────────────────

  Future<void> _pickGalleryImages() async {
    final total = _existingUrls.length + _newImages.length;
    if (_isPicking || total >= 8) return;
    _isPicking = true;
    try {
      final files = await ImagePicker().pickMultiImage(imageQuality: 85);
      if (files.isEmpty) return;
      final remaining = 8 - total;
      final loaded = <_NewImage>[];
      for (final f in files) {
        if (loaded.length >= remaining) break;
        final bytes = await f.readAsBytes();
        final isDupe = _newImages.any(
          (e) => e.file.name == f.name && e.bytes.length == bytes.length,
        );
        if (!isDupe) loaded.add(_NewImage(file: f, bytes: bytes));
      }
      if (loaded.isNotEmpty) setState(() => _newImages.addAll(loaded));
    } finally {
      _isPicking = false;
    }
  }

  Future<void> _pickSkuImage(int rowIndex) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _skuRows[rowIndex].newSkuImage = _NewImage(file: file, bytes: bytes);
      _skuRows[rowIndex].existingImageUrl = null;
    });
  }

  // ── Variant helpers ────────────────────────────────────────────────────────

  void _rebuildSkuRows() {
    final combos = _buildCombinations(_variantAttributes);
    final existingMap = {for (final r in _skuRows) r.skuId: r};

    final newRows = combos.map((combo) {
      final id = combo.values.join('_').replaceAll(' ', '-').toLowerCase();
      if (existingMap.containsKey(id)) return existingMap[id]!;
      return _EditSkuRow(combination: combo);
    }).toList();

    for (final r in _skuRows) {
      if (!newRows.contains(r)) r.dispose();
    }
    setState(() => _skuRows = newRows);
  }

  void _showAddAttributeDialog({int? editIndex}) {
    final existingAttr = editIndex != null
        ? _variantAttributes[editIndex]
        : null;

    String selectedType;
    if (existingAttr != null) {
      final match = _kVariantTypePresets.firstWhere(
        (p) => p.toLowerCase() == existingAttr.name.toLowerCase(),
        orElse: () => '',
      );
      selectedType = match.isNotEmpty ? match : 'Custom';
    } else {
      selectedType = 'Color';
    }

    final customNameCtrl = TextEditingController(
      text: (existingAttr != null && selectedType == 'Custom')
          ? existingAttr.name
          : '',
    );
    final List<VariantOption> options = existingAttr != null
        ? List<VariantOption>.from(existingAttr.options)
        : <VariantOption>[];
    final optCtrl = TextEditingController();
    final colorNameCtrl = TextEditingController();
    final colorHexCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          void addOption(VariantOption opt) {
            if (opt.value.isEmpty) return;
            final exists = options.any(
              (o) => o.value.toLowerCase() == opt.value.toLowerCase(),
            );
            if (exists) return;
            setS(() => options.add(opt));
          }

          return _BottomSheetContainer(
            title: editIndex != null ? 'Edit Variant Type' : 'Add Variant Type',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Variant Type *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    ..._kVariantTypePresets.map(
                      (t) => DropdownMenuItem(value: t, child: Text(t)),
                    ),
                    const DropdownMenuItem(
                      value: 'Custom',
                      child: Text('Custom…'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v == null || v == selectedType) return;
                    setS(() {
                      selectedType = v;
                      options.clear();
                    });
                  },
                ),
                if (selectedType == 'Custom') ...[
                  const SizedBox(height: 12),
                  AppTextField(
                    controller: customNameCtrl,
                    label: 'Custom Type Name *',
                    hint: 'e.g. Fragrance, Edition',
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'Options',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  selectedType == 'Color'
                      ? 'Tap a common color, or add your own with a hex code'
                      : selectedType == 'Size'
                      ? 'Tap to add common sizes, or type a custom one'
                      : 'Add all possible values for this variant type',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                if (options.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: options.asMap().entries.map((entry) {
                      final opt = entry.value;
                      return Chip(
                        avatar: opt.colorHex != null
                            ? CircleAvatar(
                                backgroundColor: _hexToColor(opt.colorHex!),
                              )
                            : null,
                        label: Text(opt.value),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () =>
                            setS(() => options.removeAt(entry.key)),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 12),
                if (selectedType == 'Color') ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kColorPresets.map((c) {
                      final already = options.any(
                        (o) => o.value.toLowerCase() == c.name.toLowerCase(),
                      );
                      return GestureDetector(
                        onTap: already
                            ? null
                            : () => addOption(
                                VariantOption(value: c.name, colorHex: c.hex),
                              ),
                        child: Opacity(
                          opacity: already ? 0.35 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _hexToColor(c.hex),
                                    border: Border.all(
                                      color: Colors.grey.withValues(alpha: 0.4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  c.name,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Custom color',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: AppTextField(
                          controller: colorNameCtrl,
                          label: '',
                          hint: 'Color name',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: AppTextField(
                          controller: colorHexCtrl,
                          label: '',
                          hint: '#RRGGBB',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          final name = colorNameCtrl.text.trim();
                          var hex = colorHexCtrl.text.trim();
                          if (name.isEmpty) return;
                          String? finalHex;
                          if (hex.isNotEmpty) {
                            if (!hex.startsWith('#')) hex = '#$hex';
                            final isValidHex = RegExp(
                              r'^#([0-9A-Fa-f]{6})$',
                            ).hasMatch(hex);
                            if (isValidHex) {
                              finalHex = hex.toUpperCase();
                            } else {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Invalid hex code — using default color',
                                  ),
                                ),
                              );
                            }
                          }
                          addOption(
                            VariantOption(value: name, colorHex: finalHex),
                          );
                          colorNameCtrl.clear();
                          colorHexCtrl.clear();
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ] else if (selectedType == 'Size') ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _kSizePresets.map((s) {
                      final already = options.any(
                        (o) => o.value.toLowerCase() == s.toLowerCase(),
                      );
                      return GestureDetector(
                        onTap: already
                            ? null
                            : () => addOption(VariantOption(value: s)),
                        child: Opacity(
                          opacity: already ? 0.35 : 1.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: optCtrl,
                          label: '',
                          hint: 'Custom size (e.g. 32, EU 42)',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          final v = optCtrl.text.trim();
                          if (v.isNotEmpty) {
                            addOption(VariantOption(value: v));
                            optCtrl.clear();
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          controller: optCtrl,
                          label: '',
                          hint: 'Type option value & press +',
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        onPressed: () {
                          final v = optCtrl.text.trim();
                          if (v.isNotEmpty) {
                            addOption(VariantOption(value: v));
                            optCtrl.clear();
                          }
                        },
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                AppPrimaryButton(
                  text: editIndex != null
                      ? 'Update Variant Type'
                      : 'Add Variant Type',
                  onPressed: () {
                    final name = selectedType == 'Custom'
                        ? customNameCtrl.text.trim()
                        : selectedType;
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Enter a variant type name'),
                        ),
                      );
                      return;
                    }
                    if (options.isEmpty) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(
                          content: Text('Add at least one option'),
                        ),
                      );
                      return;
                    }
                    final attr = VariantAttribute(
                      name: name,
                      options: List<VariantOption>.from(options),
                    );
                    setState(() {
                      if (editIndex != null) {
                        _variantAttributes[editIndex] = attr;
                      } else {
                        _variantAttributes.add(attr);
                      }
                    });
                    _rebuildSkuRows();
                    Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Category request ───────────────────────────────────────────────────────

  Future<void> _showRequestCategoryDialog() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final fKey = GlobalKey<FormState>();
    bool loading = false;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Request New Category'),
          content: Form(
            key: fKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category Name *',
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: loading ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: loading
                  ? null
                  : () async {
                      if (!fKey.currentState!.validate()) return;
                      setS(() => loading = true);
                      try {
                        final uid =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        final ref = FirebaseFirestore.instance
                            .collection('category_requests')
                            .doc();
                        await ref.set({
                          'id': ref.id,
                          'sellerId': uid,
                          'sellerName':
                              FirebaseAuth.instance.currentUser?.email ?? '',
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                          'status': 'pending',
                          'createdAt': FieldValue.serverTimestamp(),
                        });
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Request submitted')),
                          );
                        }
                      } catch (e) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(
                            ctx,
                          ).showSnackBar(SnackBar(content: Text('Failed: $e')));
                        }
                      } finally {
                        setS(() => loading = false);
                      }
                    },
              child: loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Validation ─────────────────────────────────────────────────────────────

  String? _validate() {
    if (_titleCtrl.text.trim().isEmpty) return 'Product title is required';
    if (_descCtrl.text.trim().isEmpty) return 'Description is required';
    if (_selectedCategory == null) return 'Select a category';
    if (_existingUrls.isEmpty && _newImages.isEmpty) {
      return 'Add at least one product photo';
    }
    if (_hasVariants) {
      if (_variantAttributes.isEmpty) {
        return 'Add at least one variant type';
      }
      for (final row in _skuRows) {
        final p = double.tryParse(row.priceCtrl.text.trim());
        if (p == null || p <= 0) {
          return 'Enter a valid price for variant: ${row.label}';
        }
        final s = int.tryParse(row.stockCtrl.text.trim());
        if (s == null || s < 0) {
          return 'Enter valid stock for variant: ${row.label}';
        }
      }
    } else {
      final p = double.tryParse(_simplePriceCtrl.text.trim());
      if (p == null || p <= 0) return 'Enter a valid selling price';
      final s = int.tryParse(_simpleStockCtrl.text.trim());
      if (s == null || s < 0) return 'Enter a valid stock quantity';
    }
    return null;
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final error = _validate();
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    final storeId = _storeId;
    if (storeId == null) return;

    setState(() => _isSaving = true);
    try {
      // Upload new gallery images
      final uploadedUrls = await Future.wait(
        List.generate(
          _newImages.length,
          (i) => CloudinaryService.uploadImage(
            bytes: _newImages[i].bytes,
            fileName:
                '${widget.productId}_${DateTime.now().millisecondsSinceEpoch}_$i.jpg',
            sellerId: storeId,
          ),
        ),
      );
      final allUrls = [..._existingUrls, ...uploadedUrls];

      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      Map<String, dynamic> updateData;

      if (_hasVariants) {
        final uploadedSkus = <Map<String, dynamic>>[];
        for (final row in _skuRows) {
          String? skuImageUrl = row.existingImageUrl;
          if (row.newSkuImage != null) {
            skuImageUrl = await CloudinaryService.uploadImage(
              bytes: row.newSkuImage!.bytes,
              fileName:
                  '${widget.productId}_sku_${row.skuId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
              sellerId: storeId,
            );
          }
          final price = double.tryParse(row.priceCtrl.text.trim()) ?? 0;
          final compare = double.tryParse(row.compareCtrl.text.trim());
          uploadedSkus.add(
            VariantSku(
              skuId: row.skuId,
              combination: row.combination,
              price: price,
              compareAtPrice: (compare != null && compare > price)
                  ? compare
                  : null,
              stock: int.tryParse(row.stockCtrl.text.trim()) ?? 0,
              skuCode: row.skuCodeCtrl.text.trim().isEmpty
                  ? null
                  : row.skuCodeCtrl.text.trim(),
              imageUrl: skuImageUrl,
            ).toMap(),
          );
        }

        final totalStock = _skuRows.fold(
          0,
          (total, r) => total + (int.tryParse(r.stockCtrl.text.trim()) ?? 0),
        );
        final minPrice = _skuRows
            .map((r) => double.tryParse(r.priceCtrl.text.trim()) ?? 0.0)
            .reduce((a, b) => a < b ? a : b);

        updateData = {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'status': _status,
          'isActive': _status == 'active',
          'basePrice': minPrice,
          'compareAtPrice': FieldValue.delete(),
          'imageUrls': allUrls,
          'category': _selectedCategory ?? '',
          'metadata': {
            'category': _selectedCategory ?? '',
            'brand': _brandCtrl.text.trim(),
            'tags': tags,
            'stock': totalStock,
          },
          'variantAttributes': _variantAttributes
              .map((a) => a.toMap())
              .toList(),
          'variantSkus': uploadedSkus,
          'updatedAt': FieldValue.serverTimestamp(),
        };
      } else {
        final price = double.tryParse(_simplePriceCtrl.text.trim()) ?? 0;
        final compare = double.tryParse(_simpleCompareCtrl.text.trim());
        final stock = int.tryParse(_simpleStockCtrl.text.trim()) ?? 0;

        updateData = {
          'title': _titleCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'status': _status,
          'isActive': _status == 'active',
          'basePrice': price,
          if (compare != null && compare > price)
            'compareAtPrice': compare
          else
            'compareAtPrice': FieldValue.delete(),
          'imageUrls': allUrls,
          'category': _selectedCategory ?? '',
          'metadata': {
            'category': _selectedCategory ?? '',
            'brand': _brandCtrl.text.trim(),
            'tags': tags,
            'stock': stock,
          },
          'variantAttributes': [],
          'variantSkus': [],
          'updatedAt': FieldValue.serverTimestamp(),
        };
      }

      final fs = FirebaseFirestore.instance;
      final batch = fs.batch();
      batch.update(fs.collection('catalog').doc(widget.productId), updateData);
      batch.set(
        fs
            .collection('stores')
            .doc(storeId)
            .collection('products')
            .doc(widget.productId),
        updateData,
        SetOptions(merge: true),
      );
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.canPop() ? context.pop() : context.go('/seller/inventory');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ── Delete ─────────────────────────────────────────────────────────────────

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text(
          'This will permanently remove the listing from your store.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final storeId = _storeId;
    if (storeId == null) return;

    setState(() => _isSaving = true);
    try {
      final fs = FirebaseFirestore.instance;
      final batch = fs.batch();
      batch.delete(fs.collection('catalog').doc(widget.productId));
      batch.delete(
        fs
            .collection('stores')
            .doc(storeId)
            .collection('products')
            .doc(widget.productId),
      );
      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product deleted')));
      context.canPop() ? context.pop() : context.go('/seller/inventory');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete: $e')));
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(title: 'Edit Product', body: AppLoadingView());
    }
    if (_loadError != null) {
      return AppScaffold(
        title: 'Edit Product',
        body: AppErrorView(message: _loadError!, onRetry: _loadProduct),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBgPrimary
          : AppColors.lightBgPrimary,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.canPop()
              ? context.pop()
              : context.go('/seller/inventory'),
        ),
        title: const Text('Edit Product'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _isSaving ? null : _confirmDelete,
          ),
        ],
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
          children: [
            // ── 1. Basic Info ──────────────────────────────────────────────
            _SectionHeader(
              number: '1',
              title: 'Basic Information',
              subtitle: 'Product name, description and category',
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _titleCtrl,
              label: 'Product Title *',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descCtrl,
              label: 'Description *',
              maxLines: 5,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _brandCtrl,
              label: 'Brand',
              hint: 'e.g. Nike, Unbranded',
            ),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Request New Category'),
                onPressed: _showRequestCategoryDialog,
              ),
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _tagsCtrl,
              label: 'Tags',
              hint: 'comma separated: summer, cotton, casual',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: InputDecoration(
                labelText: 'Listing Status',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: _statusOptions
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s == 'active'
                                  ? AppColors.success
                                  : s == 'inactive'
                                  ? Colors.orange
                                  : Colors.grey,
                            ),
                          ),
                          Text(s[0].toUpperCase() + s.substring(1)),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _status = v ?? _status),
            ),

            const SizedBox(height: 28),
            const _Divider(),
            const SizedBox(height: 28),

            // ── 2. Product Gallery ─────────────────────────────────────────
            _SectionHeader(
              number: '2',
              title: 'Product Photos *',
              subtitle: 'Up to 8 photos. First photo is the cover.',
            ),
            const SizedBox(height: 16),
            _buildGalleryPicker(isDark, cs),

            const SizedBox(height: 28),
            const _Divider(),
            const SizedBox(height: 28),

            // ── 3. Variants ────────────────────────────────────────────────
            _SectionHeader(
              number: '3',
              title: 'Product Variants',
              subtitle: 'Does this product come in different options?',
            ),
            const SizedBox(height: 16),
            _buildVariantToggle(isDark),
            if (_hasVariants) ...[
              const SizedBox(height: 20),
              _buildVariantAttributeSection(isDark),
            ],

            const SizedBox(height: 28),
            const _Divider(),
            const SizedBox(height: 28),

            // ── 4. Pricing & Inventory ─────────────────────────────────────
            _SectionHeader(
              number: '4',
              title: _hasVariants
                  ? 'Pricing & Inventory per Variant'
                  : 'Pricing & Inventory',
              subtitle: _hasVariants
                  ? 'Set price, stock and optional image for each combination'
                  : 'Set your selling price and available stock',
            ),
            const SizedBox(height: 16),
            if (_hasVariants) _buildSkuTable(isDark) else _buildSimplePricing(),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
    );
  }

  // ── Sub-builders ───────────────────────────────────────────────────────────

  Widget _buildCategoryDropdown() {
    return ref
        .watch(activeCategoriesStreamProvider)
        .when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) => Text('Error: $e'),
          data: (cats) {
            final items = List<String>.from(cats);
            if (_selectedCategory != null &&
                _selectedCategory!.isNotEmpty &&
                !items.contains(_selectedCategory)) {
              items.add(_selectedCategory!);
            }
            return DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: items
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedCategory = v),
              validator: (v) => v == null ? 'Required' : null,
            );
          },
        );
  }

  Widget _buildGalleryPicker(bool isDark, ColorScheme cs) {
    final total = _existingUrls.length + _newImages.length;
    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: total + (total < 8 ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (ctx, i) {
          if (i == total) {
            return _AddPhotoCell(onTap: _pickGalleryImages, cs: cs);
          }
          final isExisting = i < _existingUrls.length;
          final imageWidget = isExisting
              ? AppNetworkImage(
                  imageUrl: _existingUrls[i],
                  width: 108,
                  height: 108,
                )
              : Image.memory(
                  _newImages[i - _existingUrls.length].bytes,
                  width: 108,
                  height: 108,
                  fit: BoxFit.cover,
                );
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageWidget,
              ),
              if (i == 0)
                Positioned(
                  bottom: 4,
                  left: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Cover',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                top: -6,
                right: -6,
                child: GestureDetector(
                  onTap: () {
                    if (isExisting) {
                      setState(() => _existingUrls.removeAt(i));
                    } else {
                      setState(
                        () => _newImages.removeAt(i - _existingUrls.length),
                      );
                    }
                  },
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.cancel,
                      color: Colors.redAccent,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildVariantToggle(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _hasVariants
              ? AppColors.primary.withValues(alpha: 0.4)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        children: [
          _VariantToggleTile(
            title: 'No, single product',
            subtitle: 'One price, one stock — no variations',
            icon: Icons.inventory_2_outlined,
            selected: !_hasVariants,
            onTap: () {
              if (_hasVariants) setState(() => _hasVariants = false);
            },
          ),
          Divider(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          _VariantToggleTile(
            title: 'Yes, has variants',
            subtitle: 'Different sizes, colors, etc.',
            icon: Icons.tune_outlined,
            selected: _hasVariants,
            onTap: () {
              if (!_hasVariants) setState(() => _hasVariants = true);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVariantAttributeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Variant Types',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _showAddAttributeDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Type'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_variantAttributes.isEmpty)
          _EmptyHint(
            icon: Icons.layers_outlined,
            message: 'No variant types. Tap "Add Type" to begin.',
          )
        else ...[
          ..._variantAttributes.asMap().entries.map((entry) {
            final i = entry.key;
            final attr = entry.value;
            return _AttributeCard(
              attr: attr,
              onEdit: () => _showAddAttributeDialog(editIndex: i),
              onDelete: () {
                setState(() => _variantAttributes.removeAt(i));
                _rebuildSkuRows();
              },
            );
          }),
          if (_skuRows.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.success.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_skuRows.length} combinations — set price & stock below',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildSkuTable(bool isDark) {
    if (_skuRows.isEmpty) {
      return _EmptyHint(
        icon: Icons.grid_view_outlined,
        message: 'Add variant types above to generate SKU combinations.',
      );
    }
    return Column(
      children: _skuRows.asMap().entries.map((entry) {
        final i = entry.key;
        final row = entry.value;
        return _EditSkuCard(
          row: row,
          index: i,
          isDark: isDark,
          onPickImage: () => _pickSkuImage(i),
          onRemoveImage: () => setState(() {
            _skuRows[i].newSkuImage = null;
            _skuRows[i].existingImageUrl = null;
          }),
        );
      }).toList(),
    );
  }

  Widget _buildSimplePricing() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _simplePriceCtrl,
                label: 'Selling Price (₹) *',
                hint: '999',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icons.currency_rupee,
                validator: (v) {
                  final n = double.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid price';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextField(
                controller: _simpleCompareCtrl,
                label: 'MRP (₹)',
                hint: '1299',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: Icons.sell_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppTextField(
          controller: _simpleStockCtrl,
          label: 'Stock Quantity *',
          keyboardType: TextInputType.number,
          prefixIcon: Icons.inventory_2_outlined,
          validator: (v) {
            final n = int.tryParse(v ?? '');
            if (n == null || n < 0) return 'Enter a valid quantity';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AppPrimaryButton(
        text: 'Save Changes',
        isLoading: _isSaving,
        onPressed: _save,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Per-SKU edit card (edit variant)
// ─────────────────────────────────────────────────────────────────────────────

class _EditSkuCard extends StatefulWidget {
  final _EditSkuRow row;
  final int index;
  final bool isDark;
  final VoidCallback onPickImage;
  final VoidCallback onRemoveImage;

  const _EditSkuCard({
    required this.row,
    required this.index,
    required this.isDark,
    required this.onPickImage,
    required this.onRemoveImage,
  });

  @override
  State<_EditSkuCard> createState() => _EditSkuCardState();
}

class _EditSkuCardState extends State<_EditSkuCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final isDark = widget.isDark;
    final hasImage =
        row.newSkuImage != null || (row.existingImageUrl?.isNotEmpty == true);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: row.combination.entries.map((e) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${e.key}: ${e.value}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _CompactField(
                          controller: row.priceCtrl,
                          label: 'Price (₹) *',
                          hint: '999',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefix: '₹',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _CompactField(
                          controller: row.compareCtrl,
                          label: 'MRP (₹)',
                          hint: '1299',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          prefix: '₹',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _CompactField(
                          controller: row.stockCtrl,
                          label: 'Stock *',
                          hint: '0',
                          keyboardType: TextInputType.number,
                          prefix: '#',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 3,
                        child: _CompactField(
                          controller: row.skuCodeCtrl,
                          label: 'SKU Code',
                          hint: 'SHIRT-RED-M',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Variant Image',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(optional)',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                      const Spacer(),
                      if (hasImage)
                        TextButton.icon(
                          onPressed: widget.onRemoveImage,
                          icon: const Icon(
                            Icons.close,
                            size: 14,
                            color: AppColors.error,
                          ),
                          label: const Text(
                            'Remove',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: widget.onPickImage,
                    child: Container(
                      height: 80,
                      width: 80,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: isDark
                            ? AppColors.darkBgPrimary
                            : AppColors.lightBgPrimary,
                        border: Border.all(
                          color: hasImage
                              ? AppColors.primary.withValues(alpha: 0.4)
                              : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.borderLight),
                          width: hasImage ? 2 : 1,
                        ),
                      ),
                      child: hasImage
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: row.newSkuImage != null
                                  ? Image.memory(
                                      row.newSkuImage!.bytes,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.network(
                                      row.existingImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 24,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets (same as add_product_screen)
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String number;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.number,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 1,
      color: isDark
          ? AppColors.borderDark.withValues(alpha: 0.5)
          : AppColors.borderLight,
    );
  }
}

class _VariantToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _VariantToggleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? AppColors.primary : Colors.grey,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: selected ? AppColors.primary : null,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? AppColors.primary : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

class _AttributeCard extends StatelessWidget {
  final VariantAttribute attr;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AttributeCard({
    required this.attr,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        title: Text(
          attr.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: attr.options
              .map(
                (o) => Chip(
                  avatar: o.colorHex != null
                      ? CircleAvatar(backgroundColor: _hexToColor(o.colorHex!))
                      : null,
                  label: Text(o.value, style: const TextStyle(fontSize: 12)),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 0,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              )
              .toList(),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                size: 18,
                color: Colors.redAccent,
              ),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPhotoCell extends StatelessWidget {
  final VoidCallback onTap;
  final ColorScheme cs;

  const _AddPhotoCell({required this.onTap, required this.cs});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.35),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: cs.primary,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              'Add Photo',
              style: TextStyle(
                fontSize: 11,
                color: cs.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyHint({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : AppColors.lightBgPrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: AppColors.primary.withValues(alpha: 0.4)),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final String? prefix;

  const _CompactField({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        prefixText: prefix != null ? '$prefix ' : null,
        prefixStyle: const TextStyle(fontSize: 14),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 12,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

class _BottomSheetContainer extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetContainer({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBgSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
