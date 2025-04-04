import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'dart:math' as math;

class AdvancedAnalysisScreen extends StatefulWidget {
  final Map<String, dynamic>? proficiencyScores;

  const AdvancedAnalysisScreen({super.key, this.proficiencyScores});

  @override
  State<AdvancedAnalysisScreen> createState() => _AdvancedAnalysisScreenState();
}

class _AdvancedAnalysisScreenState extends State<AdvancedAnalysisScreen> {
  final Map<String, bool> _expandedItems = {};
  
  // Initialize all variables with default values
  late double finalScore = 0.0;
  late double pauseScore = 0.0;
  late double fillerScore = 0.0;
  
  // Voice modulation variables
  late double modulationScore = 0.0;
  late double pitchVolumeScore = 0.0;
  late double emphasisScore = 0.0;
  
  // Vocabulary evaluation variables - initialize with defaults
  late double vocabularyScore = 0.0;
  late double grammarWordSelectionScore = 0.0;
  late double pronunciationScore = 0.0;
  
  // Effectiveness variables
  late double effectivenessScore = 0.0;
  late double clearPurposeScore = 0.0;
  late double achievementScore = 0.0;
  late String effectivenessRating = 'Not Evaluated';
  
  // Speech development variables
  late double developmentScore = 0.0;
  late double structureScore = 0.0;
  late double timeUtilizationScore = 0.0;
  late String timeDistributionQuality = 'good';

  @override
  void initState() {
    super.initState();
    _initializeScores();
    
    // Add debug print for overall score
    print('Overall Score: ${calculateOverallScore()}');
  }

  void _initializeScores() {
    // Extract proficiency scores from the correct path in API response
    final proficiencyData = widget.proficiencyScores?['proficiency_scores'] ?? {};
    
    // Initialize proficiency scores
    finalScore = (proficiencyData['final_score'] ?? 0.0).toDouble();
    pauseScore = (proficiencyData['pause_score'] ?? 0.0).toDouble();
    fillerScore = (proficiencyData['filler_score'] ?? 0.0).toDouble();

    // Initialize voice modulation scores
    final modulation = widget.proficiencyScores?['modulation_analysis']?['scores'] ?? {};
    modulationScore = (modulation['total_score'] ?? 0.0).toDouble();
    pitchVolumeScore = (modulation['pitch_and_volume_score'] ?? 0.0).toDouble();
    emphasisScore = (modulation['emphasis_score'] ?? 0.0).toDouble();

    // Initialize effectiveness scores with proper null checking and type conversion
    final effectivenessData = widget.proficiencyScores?['speech_effectiveness'] ?? {};
    effectivenessScore = (effectivenessData['total_score'] ?? 0.0).toDouble();
    clearPurposeScore = (effectivenessData['relevance_score'] ?? 0.0).toDouble();
    achievementScore = (effectivenessData['purpose_score'] ?? 0.0).toDouble();
    
    // Ensure scores are within valid ranges
    effectivenessScore = effectivenessScore.clamp(0.0, 20.0);
    clearPurposeScore = clearPurposeScore.clamp(0.0, 10.0);
    achievementScore = achievementScore.clamp(0.0, 10.0);
    
    // Debug logging
    print('Effectiveness Scores:');
    print('Total Score: $effectivenessScore');
    print('Clear Purpose Score: $clearPurposeScore');
    print('Achievement Score: $achievementScore');
    
    effectivenessRating = _getEffectivenessRating(effectivenessScore);

    // Initialize speech development scores
    final speechDevelopment = widget.proficiencyScores?['speech_development'] ?? {};
    structureScore = ((speechDevelopment['structure'] ?? {})['score'] ?? 0.0).toDouble();
    timeUtilizationScore = ((speechDevelopment['time_utilization'] ?? {})['score'] ?? 0.0).toDouble();
    // Calculate total development score as sum of sub-scores
    developmentScore = structureScore + timeUtilizationScore;  // Will be out of 20 since each sub-score is out of 10

    // Debug logging for speech development
    print('Speech Development Scores:');
    print('Total Score (out of 20): $developmentScore');
    print('Structure Score (out of 10): $structureScore');
    print('Time Score (out of 10): $timeUtilizationScore');

    // Initialize vocabulary scores with debug logging
    final vocabularyData = widget.proficiencyScores?['vocabulary_evaluation'] ?? {};
    print('Raw Vocabulary Data:');
    print(vocabularyData);
    
    vocabularyScore = (vocabularyData['vocabulary_score'] ?? 0.0).toDouble();
    grammarWordSelectionScore = (vocabularyData['grammar_word_selection']?['score'] ?? 0.0).toDouble();
    pronunciationScore = (vocabularyData['pronunciation']?['score'] ?? 0.0).toDouble();

    // Debug log the received scores
    print('Vocabulary Scores After Processing:');
    print('Total Score: $vocabularyScore');
    print('Grammar Score: $grammarWordSelectionScore');
    print('Pronunciation Score: $pronunciationScore');

    // Validate scores are within correct ranges
    vocabularyScore = vocabularyScore.clamp(0.0, 20.0);
    grammarWordSelectionScore = grammarWordSelectionScore.clamp(0.0, 20.0);
    pronunciationScore = pronunciationScore.clamp(0.0, 20.0);

    // Debug logging
    print('Vocabulary Scores:');
    print('Total (0-20): $vocabularyScore');
    print('Grammar (0-20): $grammarWordSelectionScore');
    print('Pronunciation (0-20): $pronunciationScore');

    // Debug logging
    print('Initialized Scores:');
    print('Proficiency - Final: $finalScore, Pause: $pauseScore, Filler: $fillerScore');
    print('Effectiveness - Total: $effectivenessScore, Clear: $clearPurposeScore, Achievement: $achievementScore');
    print('Development - Total: $developmentScore, Structure: $structureScore, Time: $timeUtilizationScore');
    print('Vocabulary - Total: $vocabularyScore, Grammar: $grammarWordSelectionScore, Pronunciation: $pronunciationScore');
  }

  // Add this method to calculate overall score
  double calculateOverallScore() {
    // Each score is out of 20, so summing them up gives a score out of 100
    return developmentScore + vocabularyScore + effectivenessScore + modulationScore + finalScore;
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
                        child: buildSimpleRadarChart(),
                      ),
                      const SizedBox(height: 24),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                      _buildMetricItem(
                        icon: Icons.trending_up, // Growth/development icon
                        title: 'Speech Development',
                        value: '${developmentScore.toStringAsFixed(1)}/20',  // Changed to /20
                        description: _getSpeechDevelopmentDescription(
                          developmentScore * 5,
                        ), // Adjust scale for description
                        progress: developmentScore / 20,  // Adjust progress bar scale
                        color: AppColors.primaryBlue,
                        subMetrics: [
                          SubMetric(
                            icon: Icons.architecture,
                            title: 'Structure of the Speech',
                            value: '${structureScore.toStringAsFixed(1)}/10',
                            progress: structureScore / 10,  // Scale for progress bar (0-1)
                          ),
                          SubMetric(
                            icon: Icons.timer,
                            title: 'Time Duration Utilization',
                            value:
                                '${timeUtilizationScore.toStringAsFixed(1)}/10',  // Changed from /20 to /10
                            progress: timeUtilizationScore / 10,  // Changed from /20 to /10
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.menu_book, // Book/vocabulary icon
                        title: 'Vocabulary Evaluation',
                        value: '${vocabularyScore.toStringAsFixed(1)}/20',
                        description: _getVocabularyDescription(
                          vocabularyScore * 5,
                        ), // Scale back for description
                        progress: vocabularyScore / 20,
                        color: AppColors.accent,
                        subMetrics: [
                          SubMetric(
                            icon: Icons.spellcheck,
                            title: 'Grammar and Word Selection',
                            value:
                                '${grammarWordSelectionScore.toStringAsFixed(1)}/10',  // Changed to /10
                            progress: grammarWordSelectionScore / 10,  // Scale for 0-10
                          ),
                          SubMetric(
                            icon: Icons.record_voice_over,
                            title: 'Pronunciation',
                            value:
                                '${pronunciationScore.toStringAsFixed(1)}/10',  // Changed to /10
                            progress: pronunciationScore / 10,  // Scale for 0-10
                          ),
                        ],
                      ),
                      const Divider(height: 32),
                      _buildMetricItem(
                        icon: Icons.psychology_alt, // Brain/thinking icon
                        title: 'Effectiveness',
                        value: '${effectivenessScore.toStringAsFixed(1)}/20',
                        description: _getEffectivenessDescription(
                          effectivenessScore * 5,
                        ), // Scale back for description
                        progress: effectivenessScore / 20,
                        color: AppColors.success,
                        subMetrics: [
                          SubMetric(
                            icon: Icons.lightbulb_outline,
                            title: 'Clear Purpose and Relevance',
                            value: '${clearPurposeScore.toStringAsFixed(1)}/10', // Changed to /10
                            progress: clearPurposeScore / 10, // Changed to /10
                          ),
                          SubMetric(
                            icon: Icons.flag,
                            title: 'Achievement of Purpose',
                            value: '${achievementScore.toStringAsFixed(1)}/10', // Changed to /10
                            progress: achievementScore / 10, // Changed to /10
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
                        progress:
                            finalScore /
                            20, // Convert to percentage for progress bar
                        color: _getProficiencyColor(finalScore),
                        subMetrics: [
                          SubMetric(
                            icon: Icons.timer_outlined,
                            title: 'Pause Detection',
                            value: '${pauseScore.toStringAsFixed(1)}/10', // Now correctly out of 10
                            progress: pauseScore / 10,  // Now correctly scaled
                          ),
                          SubMetric(
                            icon: Icons.error_outline,
                            title: 'Filler Word Detection',
                            value: '${fillerScore.toStringAsFixed(1)}/10', // Now correctly out of 10
                            progress: fillerScore / 10,  // Now correctly scaled
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
          ...subMetrics.map(
            (subMetric) => Padding(
              padding: const EdgeInsets.only(left: 50),
              child: _buildSubMetricItem(
                icon: subMetric.icon,
                title: subMetric.title,
                value: subMetric.value,
                progress: subMetric.progress,
                color: color.withOpacity(0.8),
              ),
            ),
          ),
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

  String _getVocabularyDescription(double score) {
    if (score >= 17) return 'Advanced vocabulary usage';
    if (score >= 15) return 'Strong vocabulary range';
    if (score >= 13) return 'Good word selection';
    return 'Basic vocabulary usage';
  }

  String _getEffectivenessDescription(double score) {
    if (score >= 17) return 'Exceptional speech delivery';
    if (score >= 15) return 'Very effective communication';
    if (score >= 13) return 'Good speech structure';
    return 'Basic communication skills';
  }

  String _getSpeechDevelopmentDescription(double score) {
    // Score is now on 0-100 scale after multiplication by 10
    if (score >= 85) return 'Exceptionally well-developed speech';
    if (score >= 75) return 'Well-structured speech with effective timing';
    if (score >= 65) return 'Good speech development';
    return 'Basic speech structure';
  }

  Color _getProficiencyColor(double score) {
    if (score >= 16) return AppColors.success;
    if (score >= 12) return AppColors.primaryBlue;
    if (score >= 8) return AppColors.warning;
    return AppColors.error;
  }

  // Moved inside the class to access state variables
  Widget buildSimpleRadarChart() {
    const categories = [
      'Speech Development',
      'Vocabulary Evaluation',
      'Effectiveness of the Speech',
      'Voice Analysis',
      'Proficiency',
    ];

    // Use actual values from class variables where available
    final values = [
      developmentScore / 20, // Speech Development (normalize to 0-1)
      vocabularyScore / 20, // Vocabulary Evaluation (normalize to 0-1)
      effectivenessScore / 20, // Effectiveness of the Speech (normalize to 0-1)
      modulationScore / 20, // Voice Analysis (normalize to 0-1)
      finalScore / 20, // Proficiency (normalize to 0-1)
    ];

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

  // Add helper method to determine rating
  String _getEffectivenessRating(double score) {
    if (score >= 16) return 'Excellent';
    if (score >= 12) return 'Good';
    if (score >= 8) return 'Fair';
    return 'Needs Improvement';
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

    final fillPaint =
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
    canvas.drawPath(path, borderPaint);

    // Draw points
    final pointPaint =
        Paint()
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
