// Requires these pubspec.yaml dependencies (add if missing):
//   image_picker: ^1.1.2
//   firebase_storage: ^12.3.0
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/widgets/app_primary_button.dart';
import 'package:ecom/core/widgets/app_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/services/cloudinary_service.dart';

class _PickedImage {
  final XFile file;
  final Uint8List bytes;

  const _PickedImage({required this.file, required this.bytes});
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _categoryController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  final List<_PickedImage> _images = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  bool _isPicking = false;

  Future<void> _pickImages() async {
    if (_isPicking || _images.length >= 5) return;
    _isPicking = true;
    try {
      final picker = ImagePicker();
      final files = await picker.pickMultiImage(imageQuality: 80);
      if (files.isEmpty) return;

      final remaining = 5 - _images.length;
      final loaded = <_PickedImage>[];
      for (final file in files) {
        if (loaded.length >= remaining) break;
        final bytes = await file.readAsBytes();
        final isDuplicate = _images.any(
          (existing) =>
              existing.file.name == file.name &&
              existing.bytes.length == bytes.length,
        );
        if (isDuplicate) continue;
        loaded.add(_PickedImage(file: file, bytes: bytes));
      }
      if (loaded.isNotEmpty) {
        setState(() => _images.addAll(loaded));
      }
    } finally {
      _isPicking = false;
    }
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  Future<List<String>> _uploadImages(String sellerId, String productId) async {
    return Future.wait(
      List.generate(
        _images.length,
        (index) => CloudinaryService.uploadImage(
          bytes: _images[index].bytes,
          fileName: '${productId}_$index.jpg',
          sellerId: sellerId,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product photo')),
      );
      return;
    }

    final sellerId = FirebaseAuth.instance.currentUser?.uid;
    if (sellerId == null) return;

    setState(() => _isSubmitting = true);

    try {
      final firestore = FirebaseFirestore.instance;
      final docRef = firestore.collection('catalog').doc();
      final imageUrls = await _uploadImages(sellerId, docRef.id);
      final now = FieldValue.serverTimestamp();

      final productData = {
        'id': docRef.id,
        'storeId': sellerId,
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': 'product',
        'status': 'active',
        'basePrice': double.parse(_priceController.text.trim()),
        'currency': 'INR',
        'imageUrls': imageUrls,
        'metadata': {
          'category': _categoryController.text.trim(),
          'stock': int.parse(_stockController.text.trim()),
        },
        'createdAt': now,
        'updatedAt': now,
      };

      final batch = firestore.batch();
      batch.set(docRef, productData);
      batch.set(
        firestore
            .collection('stores')
            .doc(sellerId)
            .collection('products')
            .doc(docRef.id),
        productData,
      );
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product published successfully')),
      );
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/seller/dashboard');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to add product: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/seller/dashboard');
            }
          },
        ),
        title: const Text('Add Product'),
      ),
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
            const SizedBox(height: 32),
            AppPrimaryButton(
              text: 'Publish Product',
              isLoading: _isSubmitting,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _images.length + (_images.length < 5 ? 1 : 0),
        separatorBuilder: (context, state) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == _images.length) {
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
          return Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  _images[index].bytes,
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                ),
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
                  onPressed: () => _removeImage(index),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
