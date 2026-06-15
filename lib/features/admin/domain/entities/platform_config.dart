class PlatformConfig {
  final double defaultCommissionRate;
  final Map<String, double> categoryCommissionOverrides;
  final bool maintenanceModeActive;
  final int globalRateLimitPerMinute;

  const PlatformConfig({
    required this.defaultCommissionRate,
    required this.categoryCommissionOverrides,
    required this.maintenanceModeActive,
    required this.globalRateLimitPerMinute,
  });
}