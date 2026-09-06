import 'package:flutter/material.dart';
import '../models/compare_request.dart';
import '../models/decision_timing_response.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

class DecisionTimingCard extends StatefulWidget {
  final CompareRequest request;
  final String marketName;

  const DecisionTimingCard({super.key, required this.request, required this.marketName});

  @override
  State<DecisionTimingCard> createState() => _DecisionTimingCardState();
}

class _DecisionTimingCardState extends State<DecisionTimingCard> {
  final _apiService = ApiService();
  late Future<DecisionTimingResponse?> _future;

  @override
  void initState() {
    super.initState();
    // Clone request and set target market
    final req = CompareRequest(
      cropName: widget.request.cropName,
      quantityKg: widget.request.quantityKg,
      farmerLatitude: widget.request.farmerLatitude,
      farmerLongitude: widget.request.farmerLongitude,
      radiusKm: widget.request.radiusKm,
      targetMarketName: widget.marketName,
    );
    _future = _apiService.fetchDecisionTiming(req);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DecisionTimingResponse?>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink(); // hide while loading (or show a small shimmer)
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink(); // fail gracefully
        }

        final data = snapshot.data!;
        final sellNowRec = data.recommendation == "sell_now";
        
        final rationaleText = 'decision.${data.rationaleKey}'.tr(
          namedArgs: {'gain': data.gainPercent.toStringAsFixed(1)},
        );

        return Container(
          margin: const EdgeInsets.only(top: 12),
          decoration: AppTheme.cardDecoration(
            borderColor: AppTheme.primaryGreen.withValues(alpha: 0.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.timeline, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'decision.title'.tr(),
                      style: AppTheme.title.copyWith(color: AppTheme.primaryGreenDark),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildOption(
                            title: 'decision.sell_today'.tr(),
                            value: data.todayNetReturn,
                            isRecommended: sellNowRec,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildOption(
                            title: 'decision.wait_2_days'.tr(),
                            value: data.projectedNetReturnIn2Days,
                            isRecommended: !sellNowRec,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppTheme.accentAmber, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              rationaleText,
                              style: AppTheme.caption.copyWith(
                                color: Colors.black87,
                                height: 1.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOption({
    required String title,
    required double value,
    required bool isRecommended,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRecommended ? AppTheme.accentAmber.withValues(alpha: 0.15) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isRecommended ? AppTheme.accentAmber : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTheme.caption.copyWith(
                    fontWeight: isRecommended ? FontWeight.w700 : FontWeight.w500,
                    color: isRecommended ? AppTheme.accentAmber : Colors.grey.shade600,
                  ),
                ),
              ),
              if (isRecommended)
                Icon(Icons.check_circle, color: AppTheme.accentAmber, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${value.toStringAsFixed(0)}',
            style: AppTheme.title.copyWith(
              fontSize: 18,
              color: isRecommended ? Colors.black87 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
