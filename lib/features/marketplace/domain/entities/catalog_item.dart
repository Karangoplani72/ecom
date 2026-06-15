enum CatalogType { product, service }
enum ListingStatus { active, outOfStock, paused, draft }

class CatalogItem {
  final String id;
  final String storeId;
  final String title;
  final String description;
  final CatalogType type;
  final ListingStatus status;
  final double basePrice;
  final String currency;
  final List<String> imageUrls;
  final Map<String, dynamic> metadata; // Handles flexible cross-domain structural variance

  const CatalogItem({
    required this.id,
    required this.storeId,
    required this.title,
    required this.description,
    required this.type,
    required this.status,
    required this.basePrice,
    required this.currency,
    required this.imageUrls,
    required this.metadata,
  });

  // Domain-level helper check for scheduling vs shipping rules
  bool get isAppointmentBased => type == CatalogType.service;
}