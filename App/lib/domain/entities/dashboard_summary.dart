class DashboardSummary {
  const DashboardSummary({
    required this.totalCustomers,
    required this.totalOutstanding,
    required this.todaysCollection,
    required this.monthlyCollection,
    required this.activeCustomers,
  });

  final int totalCustomers;
  final double totalOutstanding;
  final double todaysCollection;
  final double monthlyCollection;
  final int activeCustomers;

  factory DashboardSummary.empty() => const DashboardSummary(
        totalCustomers: 0,
        totalOutstanding: 0,
        todaysCollection: 0,
        monthlyCollection: 0,
        activeCustomers: 0,
      );

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalCustomers: (json['totalCustomers'] as num?)?.toInt() ?? 0,
      totalOutstanding: (json['totalOutstanding'] as num?)?.toDouble() ?? 0,
      todaysCollection: (json['todaysCollection'] as num?)?.toDouble() ?? 0,
      monthlyCollection: (json['monthlyCollection'] as num?)?.toDouble() ?? 0,
      activeCustomers: (json['activeCustomers'] as num?)?.toInt() ?? 0,
    );
  }
}
