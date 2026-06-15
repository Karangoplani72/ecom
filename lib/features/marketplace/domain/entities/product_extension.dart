// Domain wrapper for explicit type validation safety
class ProductExtension {
  final int stockLevel;
  final String sku;
  final Map<String, String> physicalAttributes; // e.g., {"volume": "15ml", "color": "Clear"}

  const ProductExtension({
    required this.stockLevel,
    required this.sku,
    required this.physicalAttributes,
  });
}