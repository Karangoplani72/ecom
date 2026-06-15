import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreSeed {
  static Future<void> run() async {
    final db = FirebaseFirestore.instance;

    await db.collection('users').doc('seller_001').set({
      'email': 'seller@example.com',
      'fullName': 'Anjali Shah',
      'isActive': true,
      'roles': ['seller'],
    });

    await db.collection('stores').doc('store_001').set({
      'sellerId': 'seller_001',
      'name': "Anjali's Elite Studio",
      'isActive': true,
    });

    await db.collection('products').doc('product_001').set({
      'storeId': 'store_001',
      'title': 'Matte Top Coat',
      'status': 'active',
      'basePrice': 450,
      'stockQuantity': 50,
    });

    print('SEED COMPLETE');
  }
}