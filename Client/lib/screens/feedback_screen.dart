import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';

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
                  child: Column(
                    children: [
                      Text(
                        'Overall Score',
                        style: AppTextStyles.body1.copyWith(
                          color: AppColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '82',
                        style: TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Great job! Your delivery is improving.',
                        style: AppTextStyles.body1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Speech Metrics Section
                const Text('Speech Metrics', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                CardLayout(
                  child: Column(
                    children: [
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
                        title: 'Volume Variation',
                        value: '68 dB',
                        description: 'Good volume, could be more dynamic',
                        progress: 0.75,
                        color: AppColors.success,
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.text_fields,
                        title: 'Filler Words',
                        value: '7 times',
                        description: 'Reduce "um" and "like" occurrences',
                        progress: 0.65,
                        color: AppColors.warning,
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
                _buildSuggestionItem(
                  'Work on reducing filler words like "um" and "like"',
                  AppColors.warning,
                ),
                const SizedBox(height: 12),
                _buildSuggestionItem(
                  'Try to vary your volume more for emphasis',
                  AppColors.success,
                ),
                const SizedBox(height: 12),
                _buildSuggestionItem(
                  'Your pace is excellent, keep it up!',
                  AppColors.primaryBlue,
                ),

                const SizedBox(height: 32),
                // Action Buttons
                CustomButton(
                  text: 'Save Results',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                const SizedBox(height: 12),
                CustomButton(
                  text: 'Try Again',
                  isOutlined: true,
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/analysis');
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

  Widget _buildSuggestionItem(String text, Color color) {
    return CardLayout(
      backgroundColor: color.withOpacity(0.1),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: color),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: AppTextStyles.body1)),
        ],
      ),
    );
  }
}
