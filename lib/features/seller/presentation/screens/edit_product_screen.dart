// Requires these pubspec.yaml dependencies (add if missing):
//   image_picker: ^1.1.2
//   firebase_storage: ^12.3.0
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/widgets/app_error_view.dart';
import 'package:ecom/core/widgets/app_loading_view.dart';
import 'package:ecom/core/widgets/app_network_image.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/app_scaffold.dart';
import 'package:ecom/core/widgets/app_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/cloudinary_service.dart';

class _NewImage {
  final XFile file;
  final Uint8List bytes;

  const _NewImage({required this.file, required this.bytes});
}

class EditProductScreen extends StatefulWidget {
  final String productId;

  const EditProductScreen({super.key, required this.productId});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  static const _statusOptions = ['active', 'paused', 'outOfStock', 'draft'];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String _status = 'active';
  String? _storeId;
  List<String> _existingImageUrls = [];
  final List<_NewImage> _newImages = [];

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

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

      final metadata = (data['metadata'] as Map<String, dynamic>?) ?? {};

      _storeId = data['storeId'] as String;
      _titleController.text = (data['title'] as String?) ?? '';
      _descriptionController.text = (data['description'] as String?) ?? '';
      _categoryController.text = (metadata['category'] as String?) ?? '';
      _priceController.text = ((data['basePrice'] as num?) ?? 0).toString();
      _stockController.text = ((metadata['stock'] as num?) ?? 0).toString();
      _status = (data['status'] as String?) ?? 'active';
      _existingImageUrls = List<String>.from(
        (data['imageUrls'] as List?) ?? [],
      );

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load product: $e';
      });
    }
  }

  bool _isPicking = false;

  Future<void> _pickImages() async {
    final totalCount = _existingImageUrls.length + _newImages.length;
    if (_isPicking || totalCount >= 5) return;
    _isPicking = true;
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 80);
      if (files.isEmpty) return;

      final remaining = 5 - totalCount;
      final loaded = <_NewImage>[];
      for (final file in files) {
        if (loaded.length >= remaining) break;
        final bytes = await file.readAsBytes();
        final isDuplicate = _newImages.any(
          (existing) =>
              existing.file.name == file.name &&
              existing.bytes.length == bytes.length,
        );
        if (isDuplicate) continue;
        loaded.add(_NewImage(file: file, bytes: bytes));
      }
      if (loaded.isNotEmpty) {
        setState(() => _newImages.addAll(loaded));
      }
    } finally {
      _isPicking = false;
    }
  }

  void _removeExistingImage(int index) =>
      setState(() => _existingImageUrls.removeAt(index));

  void _removeNewImage(int index) => setState(() => _newImages.removeAt(index));

  Future<List<String>> _uploadNewImages(String storeId) async {
    return Future.wait(
      List.generate(
        _newImages.length,
        (index) => CloudinaryService.uploadImage(
          bytes: _newImages[index].bytes,
          fileName:
              '${widget.productId}_${DateTime.now().millisecondsSinceEpoch}_$index.jpg',
          sellerId: storeId,
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_existingImageUrls.isEmpty && _newImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product photo')),
      );
      return;
    }

    final storeId = _storeId;
    if (storeId == null) return;

    setState(() => _isSaving = true);
    try {
      final uploadedUrls = await _uploadNewImages(storeId);
      final allImageUrls = [..._existingImageUrls, ...uploadedUrls];

      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'status': _status,
        'basePrice': double.parse(_priceController.text.trim()),
        'imageUrls': allImageUrls,
        'metadata': {
          'category': _categoryController.text.trim(),
          'stock': int.parse(_stockController.text.trim()),
        },
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.update(
        firestore.collection('catalog').doc(widget.productId),
        updateData,
      );
      batch.set(
        firestore
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
        const SnackBar(content: Text('Product updated successfully')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/seller/inventory');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update product: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: const Text(
          'This will remove the listing from your store permanently.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final storeId = _storeId;
    if (storeId == null) return;

    setState(() => _isSaving = true);
    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      batch.delete(firestore.collection('catalog').doc(widget.productId));
      batch.delete(
        firestore
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
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/seller/inventory');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete product: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(title: 'Edit Product', body: AppLoadingView());
    }
    if (_loadError != null) {
      return AppScaffold(
        title: 'Edit Product',
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/seller/inventory');
            }
          },
        ),
        body: AppErrorView(message: _loadError!, onRetry: _loadProduct),
      );
    }

    return AppScaffold(
      title: 'Edit Product',
      actions: [
        IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _isSaving ? null : _confirmDelete,
        ),
      ],
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Photos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            _buildImagePicker(context),
            const SizedBox(height: 24),

            AppTextField(
              controller: _titleController,
              label: 'Product title',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _descriptionController,
              label: 'Description',
              maxLines: 4,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Description is required'
                  : null,
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _categoryController,
              label: 'Category',
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Category is required'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _priceController,
                    label: 'Price (₹)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      final parsed = double.tryParse(v ?? '');
                      if (parsed == null || parsed <= 0) {
                        return 'Enter a valid price';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: AppTextField(
                    controller: _stockController,
                    label: 'Stock quantity',
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final parsed = int.tryParse(v ?? '');
                      if (parsed == null || parsed < 0) {
                        return 'Enter a valid quantity';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Listing status'),
              items: _statusOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (value) => setState(() => _status = value ?? _status),
            ),
            const SizedBox(height: 32),

            AppPrimaryButton(
              text: 'Save Changes',
              isLoading: _isSaving,
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalCount = _existingImageUrls.length + _newImages.length;

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: totalCount + (totalCount < 5 ? 1 : 0),
        separatorBuilder: (context, state) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == totalCount) {
            return GestureDetector(
              onTap: _pickImages,
              child: Container(
                width: 90,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  Icons.add_a_photo_outlined,
                  color: colorScheme.primary,
                ),
              ),
            );
          }

          final isExisting = index < _existingImageUrls.length;
          final imageWidget = isExisting
              ? AppNetworkImage(
                  imageUrl: _existingImageUrls[index],
                  width: 90,
                  height: 90,
                )
              : Image.memory(
                  _newImages[index - _existingImageUrls.length].bytes,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                );

          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageWidget,
              ),
              Positioned(
                top: -8,
                right: -8,
                child: IconButton(
                  icon: const Icon(
                    Icons.cancel,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  onPressed: () => isExisting
                      ? _removeExistingImage(index)
                      : _removeNewImage(index - _existingImageUrls.length),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
