import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import '../theme/app_theme.dart';
import '../models/market_result.dart';

class ShareButton extends StatelessWidget {
  final String cropName;
  final double quantityKg;
  final MarketComparisonResult market;
  final String? differenceAmount;

  const ShareButton({
    super.key,
    required this.cropName,
    required this.quantityKg,
    required this.market,
    this.differenceAmount,
  });

  void _shareContent() {
    final qtyStr = quantityKg.toStringAsFixed(0);
    final cropTrans = 'crops.$cropName'.tr();
    final trendTrans = 'trends.${market.trend}'.tr();

    String emoji = "➡️";
    if (market.trend == "rising") emoji = "📈";
    if (market.trend == "falling") emoji = "📉";

    String message;
    if (differenceAmount != null && differenceAmount != '0') {
      message = 'decision.share_message_best'.tr(namedArgs: {
        'qty': qtyStr,
        'crop': cropTrans,
        'market': market.marketName,
        'amount': differenceAmount!,
        'trend': trendTrans,
        'emoji': emoji,
      });
    } else {
      message = 'decision.share_message_only'.tr(namedArgs: {
        'qty': qtyStr,
        'crop': cropTrans,
        'market': market.marketName,
        'trend': trendTrans,
        'emoji': emoji,
      });
    }

    Share.share(message);
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.share, size: 20),
      color: AppTheme.primaryGreen,
      onPressed: _shareContent,
      tooltip: 'Share on WhatsApp',
    );
  }
}
