import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ecom/features/marketplace/domain/entities/catalog_item.dart';

class PriceHelper {
  static double getEffectivePrice(CatalogItem item) {
    if (!isFlashSaleActive(item)) return item.basePrice;
    final percent = (item.metadata['flashSaleDiscountPercent'] as num?)?.toDouble() ?? 0.0;
    return item.basePrice * (1.0 - percent);
  }

  static double getDiscountPercent(CatalogItem item) {
    if (!isFlashSaleActive(item)) return 0.0;
    return (item.metadata['flashSaleDiscountPercent'] as num?)?.toDouble() ?? 0.0;
  }

  static bool isFlashSaleActive(CatalogItem item) {
    final isFlash = item.metadata['isFlashDeal'] == true;
    if (!isFlash) return false;

    final flashSaleStatus = item.metadata['flashSaleStatus'] as String? ?? 'active';
    if (flashSaleStatus != 'active') return false;

    final startsAt = item.metadata['flashSaleStartsAt'];
    final endsAt = item.metadata['flashSaleEndsAt'];
    if (startsAt == null || endsAt == null) return false;

    DateTime startDateTime;
    DateTime endDateTime;

    if (startsAt is Timestamp) {
      startDateTime = startsAt.toDate();
    } else if (startsAt is DateTime) {
      startDateTime = startsAt;
    } else {
      startDateTime = DateTime.tryParse(startsAt.toString()) ?? DateTime.now();
    }

    if (endsAt is Timestamp) {
      endDateTime = endsAt.toDate();
    } else if (endsAt is DateTime) {
      endDateTime = endsAt;
    } else {
      endDateTime = DateTime.tryParse(endsAt.toString()) ?? DateTime.now();
    }

    final now = DateTime.now();
    return now.isAfter(startDateTime) && now.isBefore(endDateTime);
  }
}
