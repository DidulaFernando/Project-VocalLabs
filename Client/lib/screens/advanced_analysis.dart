import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'dart:math' as math;

class AdvancedAnalysisScreen extends StatefulWidget {
  final Map<String, dynamic>? proficiencyScores;
  
  const AdvancedAnalysisScreen({
    super.key,
    this.proficiencyScores,
  });

  @override
  State<AdvancedAnalysisScreen> createState() => _AdvancedAnalysisScreenState();
}

class _AdvancedAnalysisScreenState extends State<AdvancedAnalysisScreen> {
  final Map<String, bool> _expandedItems = {};
  late double finalScore;
  late double pauseScore;
  late double fillerScore;
  // Add new variables for voice modulation
  late double modulationScore;
  late double pitchVolumeScore;
  late double emphasisScore;

  @override
  void initState() {
    super.initState();
    // Initialize scores from widget parameters
    final scores = widget.proficiencyScores?['proficiency_scores'] ?? {};
    final modulation = widget.proficiencyScores?['modulation_analysis']?['scores'] ?? {};
    finalScore = (scores['final_score'] ?? 0.0).toDouble();
    pauseScore = (scores['pause_score'] ?? 0.0).toDouble();
    fillerScore = (scores['filler_score'] ?? 0.0).toDouble();
    modulationScore = (modulation['total_score'] ?? 0.0).toDouble();
    pitchVolumeScore = (modulation['pitch_and_volume_score'] ?? 0.0).toDouble();
    emphasisScore = (modulation['emphasis_score'] ?? 0.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Advanced Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppPadding.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text('Speech Dashboard', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                CardLayout(
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300, // Increased from 220 to 300
                        child: buildSimpleRadarChart()
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      _buildMetricItem(
                        icon: Icons.trending_up, // Growth/development icon
                        title: 'Speech Development',
                        value: '85%',
                        description: 'Excellent progress in speech patterns',
                        progress: 0.85,
                        color: AppColors.primaryBlue,
                        subMetrics: const [
                          SubMetric(
                            icon: Icons.architecture,
                            title: 'Structure of the Speech',
                            value: '83%',
                            progress: 0.83,
                          ),
                          SubMetric(
                            icon: Icons.timer,
                            title: 'Time Duration Utilization',
                            value: '87%',
                            progress: 0.87,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.menu_book, // Book/vocabulary icon
                        title: 'Vocabulary Evaluation',
                        value: 'Advanced',
                        description: 'Rich and varied word choice',
                        progress: 0.82,
                        color: AppColors.accent,
                        subMetrics: const [
                          SubMetric(
                            icon: Icons.spellcheck,
                            title: 'Grammar and Word Selection',
                            value: '80%',
                            progress: 0.80,
                          ),
                          SubMetric(
                            icon: Icons.record_voice_over,
                            title: 'Pronunciation',
                            value: '84%',
                            progress: 0.84,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.psychology_alt, // Brain/thinking icon
                        title: 'Effectiveness of the Speech',
                        value: 'Good',
                        description: 'Clear and impactful delivery',
                        progress: 0.78,
                        color: AppColors.success,
                        subMetrics: const [
                          SubMetric(
                            icon: Icons.lightbulb_outline,
                            title: 'Clear Purpose and Relevance',
                            value: '76%',
                            progress: 0.76,
                          ),
                          SubMetric(
                            icon: Icons.flag,
                            title: 'Achievement of Purpose',
                            value: '80%',
                            progress: 0.80,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.mic, // Microphone/voice icon
                        title: 'Voice Analysis',
                        value: '${modulationScore.toStringAsFixed(1)}/20',
                        description: 'Voice modulation analysis',
                        progress: modulationScore / 20,
                        color: AppColors.warning,
                        subMetrics: [
                          SubMetric(
                            icon: Icons.volume_up,
                            title: 'Volume and Pitch',
                            value: '${pitchVolumeScore.toStringAsFixed(1)}/10',
                            progress: pitchVolumeScore / 10,
                          ),
                          SubMetric(
                            icon: Icons.highlight,
                            title: 'Emphasizing Points',
                            value: '${emphasisScore.toStringAsFixed(1)}/10',
                            progress: emphasisScore / 10,
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.verified, // Checkmark/proficiency icon
                        title: 'Proficiency',
                        value: '${finalScore.toStringAsFixed(1)}/20',
                        description: _getProficiencyDescription(finalScore),
                        progress: finalScore / 20, // Convert to percentage for progress bar
                        color: _getProficiencyColor(finalScore),
                        subMetrics: [
                          SubMetric(
                            icon: Icons.timer_outlined,
                            title: 'Pause Detection',
                            value: '${pauseScore.toStringAsFixed(1)}/10',
                            progress: pauseScore / 10,
                          ),
                          SubMetric(
                            icon: Icons.error_outline,
                            title: 'Filler Word Detection',
                            value: '${fillerScore.toStringAsFixed(1)}/10',
                            progress: fillerScore / 10,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required double progress,
    required Color color,
    required List<SubMetric> subMetrics,
  }) {
    bool isExpanded = _expandedItems[title] ?? false;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedItems[title] = !isExpanded;
            });
          },
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              value,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              isExpanded 
                                ? Icons.keyboard_arrow_up 
                                : Icons.keyboard_arrow_down,
                              color: AppColors.lightText,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(description, style: AppTextStyles.body2),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: AppColors.lightBlue,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isExpanded) ...[
          const SizedBox(height: 16),
          ...subMetrics.map((subMetric) => Padding(
            padding: const EdgeInsets.only(left: 50),
            child: _buildSubMetricItem(
              icon: subMetric.icon,
              title: subMetric.title,
              value: subMetric.value,
              progress: subMetric.progress,
              color: color.withOpacity(0.8),
            ),
          )).toList(),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSubMetricItem({
    required IconData icon,
    required String title,
    required String value,
    required double progress,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body2.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.lightBlue.withOpacity(0.5),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getProficiencyDescription(double score) {
    if (score >= 16) return 'Excellent command over speech';
    if (score >= 12) return 'Strong command over speech';
    if (score >= 8) return 'Good command over speech';
    return 'Needs improvement';
  }

  Color _getProficiencyColor(double score) {
    if (score >= 16) return AppColors.success;
    if (score >= 12) return AppColors.primaryBlue;
    if (score >= 8) return AppColors.warning;
    return AppColors.error;
  }
}

class SubMetric {
  final IconData icon;
  final String title;
  final String value;
  final double progress;

  const SubMetric({
    required this.icon,
    required this.title,
    required this.value,
    required this.progress,
  });
}

Widget buildSimpleRadarChart() {
  const categories = [
    'Speech Development',
    'Vocabulary Evaluation',
    'Effectiveness of the Speech',
    'Voice Analysis',
    'Proficiency',
  ];
  final values = [0.85, 0.82, 0.78, 0.75, 0.88];

  return CustomPaint(
    size: const Size(double.infinity, 280), // Increased from 200 to 280
    painter: SimpleRadarChartPainter(
      values: values,
      categories: categories,
      fillColor: AppColors.primaryBlue.withOpacity(0.2),
      borderColor: AppColors.primaryBlue,
      textColor: AppColors.lightText,
    ),
  );
}

class SimpleRadarChartPainter extends CustomPainter {
  final List<double> values;
  final List<String> categories;
  final Color fillColor;
  final Color borderColor;
  final Color textColor;

  SimpleRadarChartPainter({
    required this.values,
    required this.categories,
    required this.fillColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width < size.height ? size.width / 2 - 40 : size.height / 2 - 40;
    final count = values.length;

    // Draw background grid
    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw grid circles
    for (int i = 1; i <= 4; i++) {
      final gridRadius = radius * i / 4;
      canvas.drawCircle(center, gridRadius, gridPaint);
    }

    // Draw spokes and labels
    for (int i = 0; i < count; i++) {
      final angle = 2 * math.pi * i / count - math.pi / 2;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);

      final labelX = center.dx + (radius + 20) * math.cos(angle);
      final labelY = center.dy + (radius + 20) * math.sin(angle);
      final textPainter = TextPainter(
        text: TextSpan(
          text: categories[i],
          style: TextStyle(color: textColor, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
      );
    }

    // Draw polygon
    final path = Path();
    for (int i = 0; i < count; i++) {
      final angle = 2 * math.pi * i / count - math.pi / 2;
      final x = center.dx + radius * values[i] * math.cos(angle);
      final y = center.dy + radius * values[i] * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // Draw points
    final pointPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    for (int i = 0; i < count; i++) {
      final angle = 2 * math.pi * i / count - math.pi / 2;
      final x = center.dx + radius * values[i] * math.cos(angle);
      final y = center.dy + radius * values[i] * math.sin(angle);
      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
