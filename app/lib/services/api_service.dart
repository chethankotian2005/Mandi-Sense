import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/compare_request.dart';
import '../models/market_result.dart';
import '../models/decision_timing_response.dart';

class CompareResult {
  final List<MarketComparisonResult> markets;
  final bool isOffline;
  final String? bestMarketName;
  final double? netReturnDifference;
  final String? topTrend;

  CompareResult({
    required this.markets,
    this.isOffline = false,
    this.bestMarketName,
    this.netReturnDifference,
    this.topTrend,
  });
}

/// Service for communicating with the MandiSense backend API.
///
/// Base URL configuration:
///   - Android emulator:  http://10.0.2.2:8000  (maps to host localhost)
///   - iOS simulator:     http://localhost:8000
///   - Physical device:   http://your-computer-ip:8000
///                        (ensure phone and laptop are on the same WiFi)
class ApiService {
  // Change this to match your setup:
  // Android emulator: http://10.0.2.2:8000
  // Browser / iOS sim: http://localhost:8000
  static const String baseUrl = 'http://localhost:8000';

  static const Duration _timeout = Duration(seconds: 10);

  // ── Compare Markets ─────────────────────────────────────────────

  /// Calls POST /api/compare.  On success, caches the result locally.
  /// On network failure, returns the last cached result (if any) with
  /// [CompareResult.isOffline] = true.
  Future<CompareResult> compareMarkets(CompareRequest request) async {
    final cacheKey = 'compare_cache_${request.cropName}';

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/compare'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        // Cache the raw JSON body
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(cacheKey, response.body);

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (data['results'] as List)
            .map((e) =>
                MarketComparisonResult.fromJson(e as Map<String, dynamic>))
            .toList();

        final bestMarketName = data['best_market_name'] as String?;
        final netReturnDifference = (data['net_return_difference'] as num?)?.toDouble();
        final topTrend = data['trend'] as String?;

        return CompareResult(
          markets: results,
          isOffline: false,
          bestMarketName: bestMarketName,
          netReturnDifference: netReturnDifference,
          topTrend: topTrend,
        );
      } else {
        // Non-200 — try cache
        return _loadFromCache(cacheKey);
      }
    } catch (_) {
      // Network error — try cache
      return _loadFromCache(cacheKey);
    }
  }

  /// Reads the cached compare response for a given crop.
  Future<CompareResult> _loadFromCache(String cacheKey) async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(cacheKey);

    if (cached != null) {
      final data = jsonDecode(cached) as Map<String, dynamic>;
      final results = (data['results'] as List)
          .map((e) =>
              MarketComparisonResult.fromJson(e as Map<String, dynamic>))
          .toList();
      final bestMarketName = data['best_market_name'] as String?;
      final netReturnDifference = (data['net_return_difference'] as num?)?.toDouble();
      final topTrend = data['trend'] as String?;
      return CompareResult(
        markets: results,
        isOffline: true,
        bestMarketName: bestMarketName,
        netReturnDifference: netReturnDifference,
        topTrend: topTrend,
      );
    }

    // No cache available either
    throw Exception('No network and no cached data available.');
  }

  // ── Available Crops ─────────────────────────────────────────────

  /// Calls GET /api/crops and returns the list of crop names.
  Future<List<String>> fetchCrops() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/crops'))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<String>.from(data['crops'] as List);
      }
    } catch (_) {
      // Silently fail — caller handles empty list
    }
    return [];
  }

  // ── Decision Timing ─────────────────────────────────────────────

  /// Calls POST /api/decision-timing to get a sell now vs wait recommendation.
  Future<DecisionTimingResponse?> fetchDecisionTiming(CompareRequest request) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/api/decision-timing'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return DecisionTimingResponse.fromJson(data);
      }
    } catch (_) {
      // Return null on failure so the UI can gracefully hide the widget
    }
    return null;
  }
}
