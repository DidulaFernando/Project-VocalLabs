// lib/screens/vocal_modulation_analysis_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:fl_chart/fl_chart.dart';

class VocalModulationAnalysisScreen extends StatefulWidget {
  const VocalModulationAnalysisScreen({super.key});

  @override
  State<VocalModulationAnalysisScreen> createState() =>
      _VocalModulationAnalysisScreenState();
}

class _VocalModulationAnalysisScreenState
    extends State<VocalModulationAnalysisScreen>
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
        title: const Text('Vocal Modulation'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: AppColors.lightText,
          indicatorColor: AppColors.primaryBlue,
          tabs: const [
            Tab(text: 'PITCH'),
            Tab(text: 'VOLUME'),
            Tab(text: 'PACE'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPitchTab(), _buildVolumeTab(), _buildPaceTab()],
      ),
    );
  }

  Widget _buildPitchTab() {
    return SingleChildScrollView(
      child: Padding(
        padding: AppPadding.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            CardLayout(
              backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.info_outline,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About Vocal Pitch',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Pitch refers to how high or low your voice sounds. Varying your pitch adds interest and emphasizes key points in your speech.',
                          style: AppTextStyles.body2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Your Pitch Analysis', style: AppTextStyles.heading2),
            const SizedBox(height: 16),
            CardLayout(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Pitch Variation',
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Moderate',
                          style: TextStyle(
                            color: AppColors.warning,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(height: 200, child: LineChart(_pitchChartData())),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildPitchMetric(
                        title: 'Average',
                        value: '110 Hz',
                        icon: Icons.arrow_right,
                        color: AppColors.primaryBlue,
                      ),
                      _buildPitchMetric(
                        title: 'Lowest',
                        value: '85 Hz',
                        icon: Icons.arrow_downward,
                        color: AppColors.accent,
                      ),
                      _buildPitchMetric(
                        title: 'Highest',
                        value: '145 Hz',
                        icon: Icons.arrow_upward,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Improvement Suggestions',
              style: AppTextStyles.heading2,
            ),
            const SizedBox(height: 16),
            _buildSuggestionItem(
              title: 'Increase Pitch Variety',
              description:
                  'Your pitch variation is moderate. Try using more highs and lows to emphasize important points.',
              icon: Icons.show_chart,
              color: AppColors.warning,
            ),
            const SizedBox(height: 12),
            _buildSuggestionItem(
              title: 'Match Pitch to Content',
              description:
                  'Use higher pitch for excitement or questions, and lower pitch for serious or conclusive statements.',
              icon: Icons.compare_arrows,
              color: AppColors.primaryBlue,
            ),
            const SizedBox(height: 12),
            _buildSuggestionItem(
              title: 'Practice Pitch Control',
              description:
                  'Try exercises like sliding from low to high pitch to improve your vocal range and control.',
              icon: Icons.fitness_center,
              color: AppColors.success,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeTab() {
    // Similar structure to pitch tab but with volume data
    return const Center(
      child: Text('Volume Analysis Coming Soon', style: AppTextStyles.heading2),
    );
  }

  Widget _buildPaceTab() {
    // Similar structure to pitch tab but with pace data
    return const Center(
      child: Text('Pace Analysis Coming Soon', style: AppTextStyles.heading2),
    );
  }

  Widget _buildPitchMetric({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(title, style: AppTextStyles.body2),
      ],
    );
  }

  Widget _buildSuggestionItem({
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return CardLayout(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
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
                Text(description, style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  LineChartData _pitchChartData() {
    final List<FlSpot> spots = [
      const FlSpot(0, 110),
      const FlSpot(1, 100),
      const FlSpot(2, 120),
      const FlSpot(3, 105),
      const FlSpot(4, 140),
      const FlSpot(5, 95),
      const FlSpot(6, 115),
      const FlSpot(7, 110),
      const FlSpot(8, 130),
      const FlSpot(9, 85),
      const FlSpot(10, 145),
    ];

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 20,
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
              // Show time markers (e.g., 0s, 10s, 20s...)
              if (value % 2 == 0) {
                return Text(
                  '${value.toInt()}s',
                  style: const TextStyle(
                    color: AppColors.lightText,
                    fontSize: 10,
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 20,
            reservedSize: 30,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: const TextStyle(
                  color: AppColors.lightText,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      minX: 0,
      maxX: 10,
      minY: 80,
      maxY: 150,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primaryBlue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.primaryBlue.withOpacity(0.1),
          ),
        ),
      ],
    );
  }
}
