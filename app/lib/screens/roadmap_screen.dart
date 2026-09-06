import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';

/// Lightweight roadmap screen showing planned Week 2/3 features.
class RoadmapScreen extends StatelessWidget {
  const RoadmapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('roadmap.title'.tr()),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('roadmap.title'.tr(), style: AppTheme.headline),
              const SizedBox(height: 4),
              // We'll reuse coming_soon for the subtitle since it's just a label
              Text(
                'roadmap.coming_soon'.tr(),
                style: AppTheme.bodySecondary,
              ),
              const SizedBox(height: 24),

              _featureCard(
                icon: Icons.auto_graph,
                title: 'roadmap.feature_forecast'.tr(),
                description: 'roadmap.desc_forecast'.tr(),
              ),
              const SizedBox(height: 12),

              _featureCard(
                icon: Icons.group,
                title: 'roadmap.feature_pooling'.tr(),
                description: 'roadmap.desc_pooling'.tr(),
              ),
              const SizedBox(height: 12),

              _featureCard(
                icon: Icons.timer_outlined,
                title: 'roadmap.feature_spoilage'.tr(),
                description: 'roadmap.desc_spoilage'.tr(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _featureCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: AppTheme.cardPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primaryGreen, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppTheme.title),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentAmber.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'roadmap.coming_soon'.tr(),
                        style: AppTheme.caption.copyWith(
                          color: AppTheme.accentAmber,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: AppTheme.bodySecondary.copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
