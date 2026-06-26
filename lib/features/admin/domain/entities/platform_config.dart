class PlatformConfig {
  final double defaultCommissionRate;
  final Map<String, double> categoryCommissionOverrides;
  final bool maintenanceModeActive;
  final int globalRateLimitPerMinute;
  final String razorpayKey;
  final String announcementText;
  final String featuredCategory;

  const PlatformConfig({
    required this.defaultCommissionRate,
    required this.categoryCommissionOverrides,
    required this.maintenanceModeActive,
    required this.globalRateLimitPerMinute,
    required this.razorpayKey,
    required this.announcementText,
    required this.featuredCategory,
  });
}