enum VerificationStatus { applied, underReview, verified, suspended }

class StoreProfile {
  final String id;
  final String sellerId;
  final String name;
  final String description;
  final String logoUrl;
  final double averageRating;
  final VerificationStatus status;
  final Map<String, List<String>> operationalHours; // e.g., {"Monday": ["09:00", "18:00"]}
  final List<String> fallbackCategoryTags;

  const StoreProfile({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.description,
    required this.logoUrl,
    required this.averageRating,
    required this.status,
    required this.operationalHours,
    required this.fallbackCategoryTags,
  });

  bool isStoreOpen(String day, String militaryTime) {
    if (status != VerificationStatus.verified) return false;
    final slots = operationalHours[day];
    if (slots == null || slots.length < 2) return false;
    return militaryTime.compareTo(slots[0]) >= 0 && militaryTime.compareTo(slots[1]) <= 0;
  }
}