import 'package:cloud_firestore/cloud_firestore.dart';

class SeedDatabase {
  static final _db = FirebaseFirestore.instance;

  static Future<void> seed() async {
    await _createUsers();
    await _createProducts();
    await _createOrders();
  }

  static Future<void> _createUsers() async {
    final users = [
      {
        'id': 'admin_1',
        'name': 'Admin User',
        'email': 'admin@test.com',
        'role': 'admin',
      },
      {
        'id': 'seller_1',
        'name': 'John Seller',
        'email': 'seller1@test.com',
        'role': 'seller',
      },
      {
        'id': 'seller_2',
        'name': 'Mike Seller',
        'email': 'seller2@test.com',
        'role': 'seller',
      },
      {
        'id': 'buyer_1',
        'name': 'Alex Buyer',
        'email': 'buyer1@test.com',
        'role': 'buyer',
      },
    ];

    for (final user in users) {
      await _db.collection('users').doc(user['id'] as String).set(user);
    }
  }

  static Future<void> _createProducts() async {
    final products = [
      {
        'id': 'product_1',
        'name': 'iPhone 15',
        'price': 79999,
        'sellerId': 'seller_1',
      },
      {
        'id': 'product_2',
        'name': 'Samsung S24',
        'price': 69999,
        'sellerId': 'seller_1',
      },
    ];

    for (final product in products) {
      await _db
          .collection('products')
          .doc(product['id'] as String)
          .set(product);
    }
  }

  static Future<void> _createOrders() async {
    final orders = [
      {
        'id': 'order_1',
        'buyerId': 'buyer_1',
        'productId': 'product_1',
        'quantity': 1,
        'status': 'delivered',
      },
    ];

    for (final order in orders) {
      await _db.collection('orders').doc(order['id'] as String).set(order);
    }
  }
}