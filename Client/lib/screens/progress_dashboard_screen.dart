// lib/screens/progress_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:fl_chart/fl_chart.dart';

class ProgressDashboardScreen extends StatefulWidget {
  const ProgressDashboardScreen({super.key});

  @override
  State<ProgressDashboardScreen> createState() =>
      _ProgressDashboardScreenState();
}

class _ProgressDashboardScreenState extends State<ProgressDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.lightText,
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(text: 'WEEKLY'),
            Tab(text: 'MONTHLY'),
            Tab(text: 'YEARLY'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildWeeklyView(), _buildMonthlyView(), _buildYearlyView()],
      ),
    );
  }

  Widget _buildWeeklyView() {
    return SingleChildScrollView(
      child: Padding(
        padding: AppPadding.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'This Week\'s Performance',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 20),
            CardLayout(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Score Trend',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(height: 200, child: LineChart(_weeklyScoreData())),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Speech Metrics', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Speeches',
                    value: '5',
                    icon: Icons.mic,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg. Duration',
                    value: '4:30',
                    icon: Icons.timer,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Filler Words',
                    value: '12',
                    icon: Icons.text_fields,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg. Pace',
                    value: '140 wpm',
                    icon: Icons.speed,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Areas for Improvement', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            CardLayout(
              child: Column(
                children: [
                  _buildImprovementItem(
                    title: 'Reduce Filler Words',
                    subtitle: 'Your filler word usage is higher than optimal',
                    icon: Icons.text_fields,
                    color: AppColors.error,
                    percentage: 30,
                  ),
                  const Divider(height: 24),
                  _buildImprovementItem(
                    title: 'Improve Vocal Variety',
                    subtitle: 'Try varying your pitch and volume more',
                    icon: Icons.graphic_eq,
                    color: AppColors.warning,
                    percentage: 65,
                  ),
                  const Divider(height: 24),
                  _buildImprovementItem(
                    title: 'Consistent Pace',
                    subtitle: 'Your average pace is good, but varies too much',
                    icon: Icons.speed,
                    color: AppColors.accent,
                    percentage: 78,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyView() {
    return SingleChildScrollView(
      child: Padding(
        padding: AppPadding.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'This Month\'s Performance',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 20),
            CardLayout(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Score Trend',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(height: 200, child: LineChart(_monthlyScoreData())),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Monthly Metrics', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Speeches',
                    value: '23',
                    icon: Icons.mic,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg. Duration',
                    value: '5:15',
                    icon: Icons.timer,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Filler Words',
                    value: '85',
                    icon: Icons.text_fields,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg. Pace',
                    value: '145 wpm',
                    icon: Icons.speed,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Areas for Improvement', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            CardLayout(
              child: Column(
                children: [
                  _buildImprovementItem(
                    title: 'Volume Consistency',
                    subtitle: 'Work on maintaining consistent volume levels',
                    icon: Icons.volume_up,
                    color: AppColors.warning,
                    percentage: 68,
                  ),
                  const Divider(height: 24),
                  _buildImprovementItem(
                    title: 'Speech Duration',
                    subtitle: 'Try to keep speeches within target duration',
                    icon: Icons.timer,
                    color: AppColors.error,
                    percentage: 45,
                  ),
                  const Divider(height: 24),
                  _buildImprovementItem(
                    title: 'Pronunciation',
                    subtitle: 'Overall pronunciation clarity is improving',
                    icon: Icons.record_voice_over,
                    color: AppColors.success,
                    percentage: 82,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildYearlyView() {
    return SingleChildScrollView(
      child: Padding(
        padding: AppPadding.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'This Year\'s Performance',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 20),
            CardLayout(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Overall Score Trend',
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(height: 200, child: LineChart(_yearlyScoreData())),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text('Yearly Metrics', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Total Speeches',
                    value: '245',
                    icon: Icons.mic,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Avg. Duration',
                    value: '6:00',
                    icon: Icons.timer,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: 'Improvement Rate',
                    value: '+15%',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    title: 'Best Score',
                    value: '92',
                    icon: Icons.star,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Yearly Progress Highlights',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 16),
            CardLayout(
              child: Column(
                children: [
                  _buildImprovementItem(
                    title: 'Overall Performance',
                    subtitle: 'Significant improvement in speaking confidence',
                    icon: Icons.trending_up,
                    color: AppColors.success,
                    percentage: 88,
                  ),
                  const Divider(height: 24),
                  _buildImprovementItem(
                    title: 'Consistent Practice',
                    subtitle: 'Maintained regular practice schedule',
                    icon: Icons.calendar_today,
                    color: AppColors.primaryBlue,
                    percentage: 92,
                  ),
                  const Divider(height: 24),
                  _buildImprovementItem(
                    title: 'Speech Quality',
                    subtitle: 'Enhanced overall delivery and content structure',
                    icon: Icons.assessment,
                    color: AppColors.accent,
                    percentage: 85,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return CardLayout(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.body2),
              Icon(icon, color: color, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovementItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required int percentage,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: AppTextStyles.body2),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: AppColors.lightBlue,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 5,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
          ),
        ),
      ],
    );
  }

  LineChartData _weeklyScoreData() {
    List<FlSpot> spots = [
      const FlSpot(0, 75),
      const FlSpot(1, 78),
      const FlSpot(2, 76),
      const FlSpot(3, 80),
      const FlSpot(4, 82),
      const FlSpot(5, 85),
      const FlSpot(6, 83),
    ];

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const style = TextStyle(color: AppColors.lightText, fontSize: 12);
              String text;
              switch (value.toInt()) {
                case 0:
                  text = 'Mon';
                  break;
                case 1:
                  text = 'Tue';
                  break;
                case 2:
                  text = 'Wed';
                  break;
                case 3:
                  text = 'Thu';
                  break;
                case 4:
                  text = 'Fri';
                  break;
                case 5:
                  text = 'Sat';
                  break;
                case 6:
                  text = 'Sun';
                  break;
                default:
                  text = '';
              }
              return Text(text, style: style);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 10,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 6,
      minY: 60,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primaryBlue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.primaryBlue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primaryBlue.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  LineChartData _monthlyScoreData() {
    List<FlSpot> spots = [
      const FlSpot(0, 77),
      const FlSpot(1, 80),
      const FlSpot(2, 82),
      const FlSpot(3, 85),
    ];

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const style = TextStyle(color: AppColors.lightText, fontSize: 12);
              String text;
              switch (value.toInt()) {
                case 0:
                  text = 'Week 1';
                  break;
                case 1:
                  text = 'Week 2';
                  break;
                case 2:
                  text = 'Week 3';
                  break;
                case 3:
                  text = 'Week 4';
                  break;
                default:
                  text = '';
              }
              return Text(text, style: style);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 10,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 3,
      minY: 60,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primaryBlue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.primaryBlue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primaryBlue.withOpacity(0.2),
          ),
        ),
      ],
    );
  }

  LineChartData _yearlyScoreData() {
    List<FlSpot> spots = [
      const FlSpot(0, 70),
      const FlSpot(1, 72),
      const FlSpot(2, 75),
      const FlSpot(3, 78),
      const FlSpot(4, 80),
      const FlSpot(5, 82),
      const FlSpot(6, 81),
      const FlSpot(7, 83),
      const FlSpot(8, 85),
      const FlSpot(9, 84),
      const FlSpot(10, 86),
      const FlSpot(11, 85),
    ];

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 10,
        getDrawingHorizontalLine: (value) {
          return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              const style = TextStyle(color: AppColors.lightText, fontSize: 12);
              String text;
              switch (value.toInt()) {
                case 0:
                  text = 'Jan';
                  break;
                case 3:
                  text = 'Apr';
                  break;
                case 6:
                  text = 'Jul';
                  break;
                case 9:
                  text = 'Oct';
                  break;
                default:
                  text = '';
              }
              return Text(text, style: style);
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 10,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 12,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 11,
      minY: 60,
      maxY: 100,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primaryBlue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppColors.primaryBlue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primaryBlue.withOpacity(0.2),
          ),
        ),
      ],
    );
  }
}
