/// Dart model for a single market comparison result from POST /api/compare.
class MarketComparisonResult {
  final String marketName;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final double currentPricePerKg;
  final String trend; // "rising", "falling", "stable"
  final double transportCost;
  final double netReturn;
  final String rationale;

  MarketComparisonResult({
    required this.marketName,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.currentPricePerKg,
    required this.trend,
    required this.transportCost,
    required this.netReturn,
    required this.rationale,
  });

  factory MarketComparisonResult.fromJson(Map<String, dynamic> json) =>
      MarketComparisonResult(
        marketName: json['market_name'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        distanceKm: (json['distance_km'] as num).toDouble(),
        currentPricePerKg: (json['current_price_per_kg'] as num).toDouble(),
        trend: json['trend'] as String,
        transportCost: (json['transport_cost'] as num).toDouble(),
        netReturn: (json['net_return'] as num).toDouble(),
        rationale: json['rationale'] as String,
      );

  Map<String, dynamic> toJson() => {
        'market_name': marketName,
        'latitude': latitude,
        'longitude': longitude,
        'distance_km': distanceKm,
        'current_price_per_kg': currentPricePerKg,
        'trend': trend,
        'transport_cost': transportCost,
        'net_return': netReturn,
        'rationale': rationale,
      };
}
