// lib/screens/filler_word_detection_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';

class FillerWordDetectionScreen extends StatelessWidget {
  const FillerWordDetectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Filler Word Analysis')),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
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
                            'About Filler Words',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Filler words like "um", "uh", "like", and "you know" can distract your audience and make you sound less confident.',
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Your Filler Word Summary',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Filler Words',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '15',
                          style: AppTextStyles.heading2.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Speech Duration', style: AppTextStyles.body2),
                        Text('5:45', style: AppTextStyles.body1),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Filler Words Per Minute',
                          style: AppTextStyles.body2,
                        ),
                        Text(
                          '2.6',
                          style: AppTextStyles.body1.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Comparison to Average',
                      style: AppTextStyles.body1.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: AppColors.success.withOpacity(0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.warning,
                      ),
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('0', style: AppTextStyles.body2),
                        Text(
                          'Your usage',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                        const Text('5+', style: AppTextStyles.body2),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Filler Word Breakdown',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              _buildFillerWordItem(
                word: 'Um',
                count: 7,
                color: AppColors.error,
              ),
              const SizedBox(height: 12),
              _buildFillerWordItem(
                word: 'Like',
                count: 4,
                color: AppColors.warning,
              ),
              const SizedBox(height: 12),
              _buildFillerWordItem(
                word: 'You know',
                count: 2,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 12),
              _buildFillerWordItem(
                word: 'So',
                count: 2,
                color: AppColors.primaryBlue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Highlighted Transcript',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              CardLayout(
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.body1.copyWith(height: 1.5),
                    children: [
                      const TextSpan(
                        text:
                            'Thank you for the opportunity to speak today. I wanted to discuss the importance of effective communication in our daily lives. ',
                      ),
                      TextSpan(
                        text: 'Um, ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                          backgroundColor: AppColors.error.withOpacity(0.1),
                        ),
                      ),
                      const TextSpan(
                        text:
                            'communication is key to building strong relationships both personally and professionally. ',
                      ),
                      TextSpan(
                        text: 'Like, ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                          backgroundColor: AppColors.warning.withOpacity(0.1),
                        ),
                      ),
                      const TextSpan(
                        text:
                            'when we communicate effectively, we can avoid misunderstandings and build trust. ',
                      ),
                      TextSpan(
                        text: 'Um, ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.error,
                          backgroundColor: AppColors.error.withOpacity(0.1),
                        ),
                      ),
                      const TextSpan(
                        text:
                            'I believe that improving our communication skills is one of the most valuable investments we can make in ourselves.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Tips to Reduce Filler Words',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              _buildTipItem(
                tip: 'Pause instead of using filler words',
                description:
                    'It is better to be silent briefly than to fill the space with "um" or "uh".',
              ),
              const SizedBox(height: 12),
              _buildTipItem(
                tip: 'Practice mindfulness',
                description:
                    'Be conscious of your speech patterns and catch yourself before using filler words.',
              ),
              const SizedBox(height: 12),
              _buildTipItem(
                tip: 'Record and review yourself',
                description:
                    'Regular practice and self-review can help identify and reduce filler word usage.',
              ),
              const SizedBox(height: 12),
              _buildTipItem(
                tip: 'Slow down your speech',
                description:
                    'Speaking more slowly gives you time to think and reduces the need for fillers.',
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFillerWordItem({
    required String word,
    required int count,
    required Color color,
  }) {
    double percentage = 0;
    // lib/screens/filler_word_detection_screen.dart (continued)
    if (count == 7) percentage = 0.47;
    if (count == 4) percentage = 0.27;
    if (count == 2) percentage = 0.13;

    return CardLayout(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                word,
                style: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$count occurrences',
                style: AppTextStyles.body1.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.lightBlue,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem({required String tip, required String description}) {
    return CardLayout(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.lightbulb_outline,
              color: AppColors.primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip,
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
}
