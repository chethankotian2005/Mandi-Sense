import 'package:flutter/material.dart';
import '../models/compare_request.dart';
import '../models/market_result.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/voice_read_button.dart';
import '../widgets/decision_timing_card.dart';
import '../widgets/share_button.dart';
import '../widgets/market_map_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
/// Displays market comparison results, sorted by net return.
class ResultsScreen extends StatefulWidget {
  final CompareRequest request;

  const ResultsScreen({super.key, required this.request});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _apiService = ApiService();

  CompareResult? _compareResult;
  List<MarketComparisonResult>? _results;
  bool _isLoading = true;
  bool _isOffline = false;
  bool _showMap = false;
  String? _error;
  final Set<int> _expandedIndexes = {};

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _apiService.compareMarkets(widget.request);
      setState(() {
        _compareResult = result;
        _results = result.markets;
        _isOffline = result.isOffline;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Could not load market data. Check your connection and try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${'crops.${widget.request.cropName}'.tr()} ${'results.title_suffix'.tr()}'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isSimpleMode = context.watch<SettingsProvider>().isSimpleMode;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('home.loading'.tr()),
          ],
        ),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_results == null || _results!.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        // Offline banner
        if (_isOffline)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: AppTheme.offlineBanner,
            child: Row(
              children: [
                const Icon(Icons.wifi_off, size: 18, color: AppTheme.offlineBannerText),
                const SizedBox(width: 8),
                Text(
                  'results.offline_banner'.tr(),
                  style: AppTheme.caption.copyWith(
                    color: AppTheme.offlineBannerText,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Results list
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 12),
            children: [
              if (_results!.isNotEmpty) ...[
                if (_buildSavingsBanner() != null) _buildSavingsBanner()!,
                
                // Map toggle button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _showMap = !_showMap;
                      });
                    },
                    icon: Icon(_showMap ? Icons.map_outlined : Icons.map),
                    label: Text(_showMap ? 'Hide Map View' : 'Show Map View'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryGreen,
                      side: const BorderSide(color: AppTheme.primaryGreen),
                    ),
                  ),
                ),

                // Collapsible Map View
                if (_showMap)
                  Container(
                    height: 250,
                    margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.dividerColor),
                    ),
                    child: MarketMapView(
                      farmerLat: widget.request.farmerLatitude,
                      farmerLng: widget.request.farmerLongitude,
                      markets: _results!,
                    ),
                  ),

                for (int i = 0; i < _results!.length; i++)
                  _buildMarketCard(_results![i], i, isSimpleMode),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMarketCard(MarketComparisonResult market, int index, bool isSimpleMode) {
    final isBest = index == 0;

    String rationale = market.rationale; // fallback
    if (_compareResult != null) {
      if (isBest) {
        if (_results!.length == 1) {
          rationale = 'rationale.only'.tr(namedArgs: {'trend': 'trends.${market.trend}'.tr().toLowerCase()});
        } else {
          rationale = 'rationale.best'.tr(namedArgs: {
            'amount': _compareResult!.netReturnDifference?.toStringAsFixed(0) ?? '0',
            'trend': 'trends.${market.trend}'.tr().toLowerCase()
          });
        }
      } else {
        final diff = (_results![0].netReturn - market.netReturn).toStringAsFixed(0);
        rationale = 'rationale.lower'.tr(namedArgs: {
          'amount': diff,
          'trend': 'trends.${market.trend}'.tr().toLowerCase()
        });
      }
    }

    final isExpanded = _expandedIndexes.contains(index);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isExpanded) {
            _expandedIndexes.remove(index);
          } else {
            _expandedIndexes.add(index);
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: AppTheme.cardDecoration(
          borderColor: isBest ? AppTheme.primaryGreen : null,
        ),
        child: Padding(
          padding: AppTheme.cardPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // ── Header row: name + badge ──────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(market.marketName, style: AppTheme.title),
                      const SizedBox(height: 2),
                      Text(
                        'results.km_away'.tr(namedArgs: {'dist': market.distanceKm.toStringAsFixed(1)}),
                        style: AppTheme.caption,
                      ),
                    ],
                  ),
                ),
                if (isBest)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              'results.best_option'.tr(),
                              style: AppTheme.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VoiceReadButton(text: rationale),
                      ShareButton(
                        cropName: widget.request.cropName,
                        quantityKg: widget.request.quantityKg,
                        market: market,
                        differenceAmount: _results!.length > 1 
                            ? _compareResult!.netReturnDifference?.toStringAsFixed(0)
                            : null,
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // ── Net return — the hero number ─────────────────
            Text(
              'results.net_return'.tr(),
              style: AppTheme.caption,
            ),
            Text(
              '\u20B9${market.netReturn.toStringAsFixed(0)}',
              style: AppTheme.bigNumber.copyWith(
                color: isBest
                    ? AppTheme.primaryGreen
                    : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            // ── Price + trend row ────────────────────────────
            Row(
              children: [
                // Price
                _infoChip(
                  Icons.currency_rupee,
                  '${market.currentPricePerKg.toStringAsFixed(1)}/kg',
                  AppTheme.textSecondary,
                ),
                const SizedBox(width: 12),
                // Trend chip
                _trendChip(market.trend, isSimpleMode),
                const Spacer(),
                // Transport cost
                _infoChip(
                  Icons.local_shipping_outlined,
                  '\u20B9${market.transportCost.toStringAsFixed(0)}',
                  AppTheme.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Rationale ────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isBest
                    ? AppTheme.primaryGreen.withValues(alpha: 0.06)
                    : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                rationale,
                style: AppTheme.caption.copyWith(
                  color: isBest
                      ? AppTheme.primaryGreenDark
                      : AppTheme.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            if (isExpanded)
              DecisionTimingCard(
                request: widget.request,
                marketName: market.marketName,
              ),
          ],
        ),
      ),
    ));
  }

  Widget _trendChip(String trend, bool isSimpleMode) {
    IconData icon;
    Color color;
    String label;

    switch (trend) {
      case 'rising':
        icon = Icons.trending_up;
        color = AppTheme.trendRising;
        break;
      case 'falling':
        icon = Icons.trending_down;
        color = AppTheme.trendFalling;
        break;
      default:
        icon = Icons.trending_flat;
        color = AppTheme.trendStable;
    }

    if (isSimpleMode) {
      IconData simpleIcon;
      if (trend == 'rising') simpleIcon = Icons.arrow_upward;
      else if (trend == 'falling') simpleIcon = Icons.arrow_downward;
      else simpleIcon = Icons.arrow_forward;

      return Icon(simpleIcon, size: 36, color: color);
    }
    
    label = 'trends.$trend'.tr();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: AppTheme.caption),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'results.error_title'.tr(),
              style: AppTheme.title,
            ),
            const SizedBox(height: 8),
            Text(
              'results.error_msg'.tr(),
              textAlign: TextAlign.center,
              style: AppTheme.bodySecondary,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchResults,
              icon: const Icon(Icons.refresh),
              label: Text('results.retry'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text('results.empty_title'.tr(), style: AppTheme.title),
            const SizedBox(height: 8),
            Text(
              'results.empty_msg'.tr(),
              textAlign: TextAlign.center,
              style: AppTheme.bodySecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSavingsBanner() {
    if (_results == null || _results!.length < 2) return null;

    final bestMarket = _results![0];
    MarketComparisonResult? nearestMarket;

    for (final m in _results!) {
      if (nearestMarket == null || m.distanceKm < nearestMarket.distanceKm) {
        nearestMarket = m;
      }
    }

    if (nearestMarket == null || bestMarket.marketName == nearestMarket.marketName) {
      return null;
    }

    final savings = bestMarket.netReturn - nearestMarket.netReturn;
    if (savings <= 0) return null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentAmber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.accentAmber, width: 2),
      ),
      child: Column(
        children: [
          Text('results.you_saved'.tr(), style: AppTheme.title),
          const SizedBox(height: 8),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: savings),
            duration: const Duration(milliseconds: 1500),
            builder: (context, value, child) {
              return Text(
                '\u20B9${value.toStringAsFixed(0)}',
                style: AppTheme.bigNumber.copyWith(
                  color: AppTheme.accentAmber,
                  fontSize: 32,
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'results.savings_subtitle'.tr(namedArgs: {
              'best': bestMarket.marketName,
              'nearest': nearestMarket.marketName,
            }),
            style: AppTheme.bodySecondary.copyWith(
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
