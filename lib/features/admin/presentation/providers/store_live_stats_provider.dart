import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/core/providers/common_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Live statistics for a single store, computed directly from Firestore
/// instead of relying on the `totalProducts` / `totalOrders` / `rating` /
/// `totalReviews` counters stored on the `stores` document.
///
/// Those stored counters are unreliable: only `totalProducts` is ever kept
/// in sync by client code (in add/edit product screens). `totalOrders`,
/// `rating`, and `totalReviews` are written once as `0` at store-creation
/// time and never updated again anywhere in the app, so any screen reading
/// them directly (Sellers list, Stores list) shows permanently stale/fake
/// numbers. This provider recomputes the real values on demand.
class StoreLiveStats {
  final int totalProducts;
  final int totalOrders;
  final double rating;
  final int totalReviews;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> products;

  const StoreLiveStats({
    required this.totalProducts,
    required this.totalOrders,
    required this.rating,
    required this.totalReviews,
    required this.products,
  });

  static const empty = StoreLiveStats(
    totalProducts: 0,
    totalOrders: 0,
    rating: 0.0,
    totalReviews: 0,
    products: [],
  );
}

/// Cached per-store live stats, keyed by storeId.
///
/// `ref.keepAlive()` is called so the result is cached for the app's
/// lifetime instead of being an `autoDispose` provider — this is what stops
/// the Sellers/Stores/Store-Detail screens from re-querying Firestore (and
/// resetting scroll position) every time their widget tree rebuilds, e.g.
/// while scrolling. After an action that changes a store's counts (delete,
/// suspend, new product, new order), call
/// `ref.invalidate(storeLiveStatsProvider(storeId))` to force a refresh.
final storeLiveStatsProvider =
    FutureProvider.family<StoreLiveStats, String>((ref, storeId) async {
  ref.keepAlive();

  if (storeId.isEmpty) return StoreLiveStats.empty;

  final firestore = ref.watch(firebaseFirestoreProvider);

  final productsFuture = firestore
      .collection('catalog')
      .where('storeId', isEqualTo: storeId)
      .get();
  final orderCountFuture = firestore
      .collection('orders')
      .where('storeId', isEqualTo: storeId)
      .count()
      .get();
  final reviewsFuture = firestore
      .collection('reviews')
      .where('storeId', isEqualTo: storeId)
      .get();

  final results = await Future.wait([
    productsFuture,
    orderCountFuture,
    reviewsFuture,
  ]);

  final productsSnap = results[0] as QuerySnapshot<Map<String, dynamic>>;
  final orderCountSnap = results[1] as AggregateQuerySnapshot;
  final reviewsSnap = results[2] as QuerySnapshot<Map<String, dynamic>>;

  double avgRating = 0.0;
  final reviewCount = reviewsSnap.docs.length;
  if (reviewCount > 0) {
    double total = 0;
    for (final doc in reviewsSnap.docs) {
      total += (doc.data()['rating'] as num?)?.toDouble() ?? 0.0;
    }
    avgRating = total / reviewCount;
  } else if (productsSnap.docs.isNotEmpty) {
    // Fall back to averaging product-level ratings if there are no
    // store-level reviews yet.
    double total = 0;
    int counted = 0;
    for (final doc in productsSnap.docs) {
      final r = (doc.data()['avgRating'] as num?)?.toDouble() ?? 0.0;
      if (r > 0) {
        total += r;
        counted++;
      }
    }
    avgRating = counted > 0 ? total / counted : 0.0;
  }

  return StoreLiveStats(
    totalProducts: productsSnap.docs.length,
    totalOrders: orderCountSnap.count ?? 0,
    rating: avgRating,
    totalReviews: reviewCount,
    products: productsSnap.docs,
  );
});
