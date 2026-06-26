import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';




final bulkUploadControllerProvider = Provider((ref) => BulkUploadController());

class BulkUploadController {
  Future<Either<String, int>> uploadCsv() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result == null || result.files.isEmpty) {
        return left('No file selected');
      }

      final file = File(result.files.single.path!);
      final input = file.openRead();
      final fields = await input
          .transform(utf8.decoder)
          .transform(csv.decoder)
          .toList();

      if (fields.isEmpty || fields.length < 2) {
        return left('CSV is empty or invalid');
      }

      final headers = fields.first.map((e) => e.toString().trim().toLowerCase()).toList();
      final titleIndex = headers.indexOf('title');
      final descIndex = headers.indexOf('description');
      final priceIndex = headers.indexOf('price');
      final stockIndex = headers.indexOf('stock');
      final categoryIndex = headers.indexOf('category');

      if (titleIndex == -1 || priceIndex == -1 || stockIndex == -1) {
        return left('CSV must contain "title", "price", and "stock" columns');
      }

      final sellerId = FirebaseAuth.instance.currentUser?.uid;
      if (sellerId == null) {
        return left('User not authenticated');
      }

      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();
      int successCount = 0;

      for (int i = 1; i < fields.length; i++) {
        final row = fields[i];
        if (row.length < headers.length) continue;

        final title = row[titleIndex].toString().trim();
        final description = descIndex != -1 ? row[descIndex].toString().trim() : '';
        final price = double.tryParse(row[priceIndex].toString()) ?? 0.0;
        final stock = int.tryParse(row[stockIndex].toString()) ?? 0;
        final category = categoryIndex != -1 ? row[categoryIndex].toString().trim() : '';

        if (title.isEmpty || price <= 0) continue;

        final docRef = firestore.collection('catalog').doc();
        final now = FieldValue.serverTimestamp();

        final productData = {
          'id': docRef.id,
          'storeId': sellerId,
          'title': title,
          'description': description,
          'type': 'product',
          'status': 'active',
          'basePrice': price,
          'currency': 'INR',
          'imageUrls': <String>[],
          'metadata': {
            'category': category,
            'stock': stock,
          },
          'variants': <Map<String, dynamic>>[],
          'createdAt': now,
          'updatedAt': now,
        };

        batch.set(docRef, productData);
        batch.set(
          firestore
              .collection('stores')
              .doc(sellerId)
              .collection('products')
              .doc(docRef.id),
          productData,
        );
        successCount++;
      }

      if (successCount > 0) {
        await batch.commit();
        // Atomically increment totalProducts on the store doc
        await firestore.collection('stores').doc(sellerId).set({
          'totalProducts': FieldValue.increment(successCount),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return right(successCount);
    } catch (e) {
      return left(e.toString());
    }
  }
}
