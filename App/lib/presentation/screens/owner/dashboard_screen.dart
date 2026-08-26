import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/dashboard_summary.dart';
import '../../viewmodels/owner_view_model.dart';
import '../../widgets/async_state_widgets.dart';
import '../../widgets/amount_hero_card.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_card.dart';
import 'customers_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: context.read<OwnerViewModel>().refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: context.read<OwnerViewModel>().refreshDashboard,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _DashboardErrorBanner(),
            Text(
              'Welcome back',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Here is your shop ledger for today.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Selector<OwnerViewModel, DashboardSummary>(
              selector: (_, vm) => vm.dashboard,
              builder: (_, summary, __) => _DashboardHeroCard(summary: summary),
            ),
            const SizedBox(height: 16),
            Selector<OwnerViewModel, DashboardSummary>(
              selector: (_, vm) => vm.dashboard,
              builder: (_, summary, __) => _DashboardStatsGrid(summary: summary),
            ),
            const SizedBox(height: 16),
            Selector<OwnerViewModel, List<Map<String, dynamic>>>(
              selector: (_, vm) => vm.monthlyReport,
              shouldRebuild: (previous, next) => !identical(previous, next),
              builder: (_, monthlyReport, __) {
                final spots = [
                  for (var i = 0; i < monthlyReport.length; i++)
                    FlSpot(
                      i.toDouble(),
                      ((monthlyReport[i]['total'] as num?) ?? 0).toDouble(),
                    ),
                ];
                return _DashboardChart(
                  monthlyReport: monthlyReport,
                  spots: spots,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Selector<OwnerViewModel, String?>(
      selector: (_, vm) => vm.error,
      builder: (context, error, _) {
        return error == null
            ? const SizedBox.shrink()
            : ErrorBanner(
                message: error,
                onClose: context.read<OwnerViewModel>().clearError,
              );
      },
    );
  }
}

class _DashboardHeroCard extends StatelessWidget {
  const _DashboardHeroCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return AmountHeroCard(
      label: "Today's Outstanding",
      amount: CurrencyFormatter.format(summary.totalOutstanding),
      icon: Icons.account_balance_wallet,
      color: Colors.red.shade600,
      subtitle: '${summary.activeCustomers} active customers',
      actions: [
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CustomersScreen(),
            ),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Add Due'),
        ),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const CustomersScreen(),
            ),
          ),
          icon: const Icon(Icons.payments),
          label: const Text('Payment'),
        ),
      ],
    );
  }
}

class _DashboardStatsGrid extends StatelessWidget {
  const _DashboardStatsGrid({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth > 680;
        return GridView.count(
          crossAxisCount: wide ? 4 : 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: wide ? 1.7 : 1.12,
          children: [
            StatCard(
              title: 'Customers',
              value: '${summary.totalCustomers}',
              icon: Icons.groups,
              color: Colors.blue,
            ),
            StatCard(
              title: 'Total Due',
              value: CurrencyFormatter.format(summary.totalOutstanding),
              icon: Icons.receipt_long,
              color: Colors.red,
            ),
            StatCard(
              title: "Today's Collection",
              value: CurrencyFormatter.format(summary.todaysCollection),
              icon: Icons.payments,
              color: Colors.green,
            ),
            StatCard(
              title: 'Monthly Collection',
              value: CurrencyFormatter.format(summary.monthlyCollection),
              icon: Icons.calendar_month,
              color: Colors.teal,
            ),
          ],
        );
      },
    );
  }
}

class _DashboardChart extends StatelessWidget {
  const _DashboardChart({
    required this.monthlyReport,
    required this.spots,
  });

  final List<Map<String, dynamic>> monthlyReport;
  final List<FlSpot> spots;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Collections'),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Monthly trend',
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  height: 190,
                  child: monthlyReport.isEmpty
                      ? const EmptyState(
                          icon: Icons.insights,
                          title: 'No chart data',
                          message:
                              'Collections will appear after payments are recorded.',
                        )
                      : RepaintBoundary(
                          child: LineChart(
                            LineChartData(
                              gridData: const FlGridData(show: true),
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(),
                                topTitles: AxisTitles(),
                                rightTitles: AxisTitles(),
                              ),
                              borderData: FlBorderData(show: false),
                              lineBarsData: [
                                LineChartBarData(
                                  isCurved: true,
                                  barWidth: 3,
                                  color: Theme.of(context).colorScheme.primary,
                                  spots: spots,
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
