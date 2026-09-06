class DecisionTimingResponse {
  final double todayNetReturn;
  final double projectedNetReturnIn2Days;
  final String recommendation; // "sell_now" or "wait_2_days"
  final String rationaleKey;
  final double gainPercent;

  DecisionTimingResponse({
    required this.todayNetReturn,
    required this.projectedNetReturnIn2Days,
    required this.recommendation,
    required this.rationaleKey,
    required this.gainPercent,
  });

  factory DecisionTimingResponse.fromJson(Map<String, dynamic> json) =>
      DecisionTimingResponse(
        todayNetReturn: (json['today_net_return'] as num).toDouble(),
        projectedNetReturnIn2Days: (json['projected_net_return_in_2_days'] as num).toDouble(),
        recommendation: json['recommendation'] as String,
        rationaleKey: json['rationale_key'] as String,
        gainPercent: (json['gain_percent'] as num).toDouble(),
      );
}
