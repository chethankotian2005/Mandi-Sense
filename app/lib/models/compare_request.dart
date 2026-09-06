/// Dart model for the request body of POST /api/compare.
class CompareRequest {
  final String cropName;
  final double quantityKg;
  final double farmerLatitude;
  final double farmerLongitude;
  final double radiusKm;
  final String? targetMarketName;

  CompareRequest({
    required this.cropName,
    required this.quantityKg,
    required this.farmerLatitude,
    required this.farmerLongitude,
    this.radiusKm = 50.0,
    this.targetMarketName,
  });

  Map<String, dynamic> toJson() {
    final data = {
      'crop_name': cropName,
      'quantity_kg': quantityKg,
      'farmer_latitude': farmerLatitude,
      'farmer_longitude': farmerLongitude,
      'radius_km': radiusKm,
    };
    if (targetMarketName != null) {
      data['target_market_name'] = targetMarketName!;
    }
    return data;
  }

  factory CompareRequest.fromJson(Map<String, dynamic> json) => CompareRequest(
        cropName: json['crop_name'] as String,
        quantityKg: (json['quantity_kg'] as num).toDouble(),
        farmerLatitude: (json['farmer_latitude'] as num).toDouble(),
        farmerLongitude: (json['farmer_longitude'] as num).toDouble(),
        radiusKm: (json['radius_km'] as num?)?.toDouble() ?? 50.0,
        targetMarketName: json['target_market_name'] as String?,
      );
}
