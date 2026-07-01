import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../viewmodels/owner_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OwnerViewModel>(
      builder: (context, vm, _) {
        final summary = vm.dashboard;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Dashboard'),
            actions: [
              IconButton(
                tooltip: 'Refresh',
                onPressed: vm.refreshDashboard,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: vm.refreshDashboard,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (vm.error != null) ErrorBanner(message: vm.error!, onClose: vm.clearError),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth > 680;
                    return GridView.count(
                      crossAxisCount: wide ? 3 : 1,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: wide ? 2.6 : 3.6,
                      children: [
                        StatCard(title: 'Total Customers', value: '${summary.totalCustomers}', icon: Icons.groups, color: Colors.blue),
                        StatCard(title: 'Total Outstanding', value: CurrencyFormatter.format(summary.totalOutstanding), icon: Icons.account_balance_wallet, color: Colors.red),
                        StatCard(title: "Today's Collection", value: CurrencyFormatter.format(summary.todaysCollection), icon: Icons.payments, color: Colors.green),
                        StatCard(title: 'Monthly Collection', value: CurrencyFormatter.format(summary.monthlyCollection), icon: Icons.calendar_month, color: Colors.teal),
                        StatCard(title: 'Active Customers', value: '${summary.activeCustomers}', icon: Icons.verified_user, color: Colors.indigo),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Monthly Collection', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 18),
                        SizedBox(
                          height: 220,
                          child: vm.monthlyReport.isEmpty
                              ? const EmptyState(
                                  icon: Icons.insights,
                                  title: 'No chart data',
                                  message: 'Collections will appear after payments are recorded.',
                                )
                              : LineChart(
                                  LineChartData(
                                    gridData: const FlGridData(show: true),
                                    titlesData: const FlTitlesData(leftTitles: AxisTitles(), topTitles: AxisTitles(), rightTitles: AxisTitles()),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        isCurved: true,
                                        barWidth: 3,
                                        color: Theme.of(context).colorScheme.primary,
                                        spots: [
                                          for (var i = 0; i < vm.monthlyReport.length; i++)
                                            FlSpot(i.toDouble(), ((vm.monthlyReport[i]['total'] as num?) ?? 0).toDouble()),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
