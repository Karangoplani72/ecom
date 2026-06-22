class PlatformConfig {
  final double defaultCommissionRate;
  final Map<String, double> categoryCommissionOverrides;
  final bool maintenanceModeActive;
  final int globalRateLimitPerMinute;
  final String razorpayKey;

  const PlatformConfig({
    required this.defaultCommissionRate,
    required this.categoryCommissionOverrides,
    required this.maintenanceModeActive,
    required this.globalRateLimitPerMinute,
    required this.razorpayKey,
  });
}