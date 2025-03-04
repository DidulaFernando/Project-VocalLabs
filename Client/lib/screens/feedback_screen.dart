import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class FeedbackScreen extends StatelessWidget {
  const FeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppPadding.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Overall Score Card
                CardLayout(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Overall Score',
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.lightText,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '82',
                          style: TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Great job! Your delivery is improving.',
                          style: AppTextStyles.body1,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Speech Dashboard
                const Text('Speech Dashboard', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                CardLayout(
                  child: Column(
                    children: [
                      // Speech radar chart
                      const SizedBox(height: 16),
                      SizedBox(height: 220, child: buildSimpleRadarChart()),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      // Speech metrics
                      _buildMetricItem(
                        icon: Icons.speed,
                        title: 'Pace',
                        value: '142 wpm',
                        description: 'Excellent pace, very natural',
                        progress: 0.85,
                        color: AppColors.primaryBlue,
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.volume_up,
                        title: 'Voice Modulation',
                        value: '68 dB',
                        description: 'Good volume, could be more dynamic',
                        progress: 0.75,
                        color: AppColors.success,
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.text_fields,
                        title: 'Vocabulary Level',
                        value: 'Advanced',
                        description: 'Varied word choice with specific terms',
                        progress: 0.82,
                        color: AppColors.accent,
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.safety_divider,
                        title: 'Filler Words',
                        value: '7 times',
                        description: 'Reduce "um" and "like" occurrences',
                        progress: 0.65,
                        color: AppColors.warning,
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.psychology,
                        title: 'Speech Effectiveness',
                        value: 'Good',
                        description: 'Clear organization and delivery',
                        progress: 0.78,
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Playback Section
                const Text('Speech Playback', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                CardLayout(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.headphones,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Listen to your speech',
                            style: AppTextStyles.body1,
                          ),
                          const Spacer(),
                          Text(
                            '5:45',
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.lightText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(
                        value: 0.3,
                        backgroundColor: AppColors.lightBlue,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryBlue,
                        ),
                        minHeight: 5,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10),
                            onPressed: () {},
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            backgroundColor: AppColors.primaryBlue,
                            radius: 24,
                            child: IconButton(
                              icon: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () {},
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.forward_10),
                            onPressed: () {},
                            color: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Transcription Section
                const Text('Transcription', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                CardLayout(
                  child: SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'Thank you for the opportunity to speak today. I wanted to discuss the importance of effective communication in our daily lives. As we all know, um, communication is key to building strong relationships both personally and professionally...',
                          style: AppTextStyles.body1.copyWith(height: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Suggestions Section
                const Text('Suggestions', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                CardLayout(
                  backgroundColor: AppColors.warning.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppColors.warning),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Work on reducing filler words like "um" and "like"',
                          style: AppTextStyles.body1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CardLayout(
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppColors.success),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Try to vary your volume more for emphasis',
                          style: AppTextStyles.body1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CardLayout(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primaryBlue,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Your pace is excellent, keep it up!',
                          style: AppTextStyles.body1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                // Action Buttons
                CustomButton(
                  text: 'Save Results',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSimpleRadarChart() {
    const categories = [
      'Speech Development',
      'Proficiency',
      'Voice Analysis',
      'Speech Effectiveness',
      'Vocabulary Evaluation',
    ];
    final values = [0.85, 0.75, 0.82, 0.65, 0.78];

    return CustomPaint(
      size: const Size(double.infinity, 200),
      painter: SimpleRadarChartPainter(
        values: values,
        categories: categories,
        fillColor: AppColors.primaryBlue.withOpacity(0.2),
        borderColor: AppColors.primaryBlue,
        textColor: AppColors.lightText,
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
  }) {
    return Row(
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
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
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
    );
  }
}

// Custom radar chart painter that doesn't rely on fl_chart's specific API
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
    final radius =
        size.width < size.height ? size.width / 2 - 40 : size.height / 2 - 40;
    final count = values.length;

    // Draw background grid
    final gridPaint =
        Paint()
          ..color = Colors.grey.shade300
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    // Draw grid circles
    for (int i = 1; i <= 4; i++) {
      final gridRadius = radius * i / 4;
      canvas.drawCircle(center, gridRadius, gridPaint);
    }

    // Draw spokes
    for (int i = 0; i < count; i++) {
      final angle = 2 * 3.14159 * i / count - 3.14159 / 2;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);
      canvas.drawLine(center, Offset(x, y), gridPaint);

      // Draw category labels
      final labelX = center.dx + (radius + 20) * cos(angle);
      final labelY = center.dy + (radius + 20) * sin(angle);

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
    final fillPaint =
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill;

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    final path = Path();
    for (int i = 0; i < count; i++) {
      final value = values[i];
      final angle = 2 * 3.14159 * i / count - 3.14159 / 2;
      final x = center.dx + radius * value * cos(angle);
      final y = center.dy + radius * value * sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);

    // Draw data points
    final pointPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final value = values[i];
      final angle = 2 * 3.14159 * i / count - 3.14159 / 2;
      final x = center.dx + radius * value * cos(angle);
      final y = center.dy + radius * value * sin(angle);

      canvas.drawCircle(Offset(x, y), 3, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }

  // Helper for angle calculations
  double cos(double angle) {
    return math.cos(angle);
  }

  double sin(double angle) {
    return math.sin(angle);
  }
}
