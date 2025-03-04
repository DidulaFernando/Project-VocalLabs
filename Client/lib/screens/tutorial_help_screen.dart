// lib/screens/tutorial_help_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';

class TutorialHelpScreen extends StatefulWidget {
  const TutorialHelpScreen({super.key});

  @override
  State<TutorialHelpScreen> createState() => _TutorialHelpScreenState();
}

class _TutorialHelpScreenState extends State<TutorialHelpScreen> {
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'How does VocalLabs analyze my speech?',
      'answer':
          'VocalLabs uses advanced machine learning algorithms to analyze various aspects of your speech, including clarity, pace, filler words, and vocal modulation. Our technology processes your voice recording in real-time to provide instant, objective feedback.',
      'isExpanded': false,
    },
    {
      'question': 'How can I improve my scores?',
      'answer':
          'Regular practice is key! Focus on the specific areas highlighted in your feedback. Try recording shorter practice sessions daily, and gradually implement the suggested improvements. Review your progress over time to see how you are improving.',
      'isExpanded': false,
    },
    {
      'question': 'Is my speech data private?',
      'answer':
          'Yes, your privacy is important to us. All speech recordings and analysis data are stored securely and are only accessible to you. We do not share your data with third parties or use it for purposes other than providing you with feedback and tracking your progress.',
      'isExpanded': false,
    },
    {
      'question': 'Can I use VocalLabs offline?',
      'answer':
          'Some features of VocalLabs require an internet connection for analysis, but basic recording functionality works offline. Your recordings will be analyzed once your device reconnects to the internet.',
      'isExpanded': false,
    },
    {
      'question': 'How accurate is the analysis?',
      'answer':
          'VocalLabs has been trained on thousands of speech samples and provides highly accurate analysis. However, like any AI system, it may occasionally miss subtle nuances that a human coach might catch. We are constantly improving our algorithms to enhance accuracy.',
      'isExpanded': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Quick Start Guide', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              _buildTutorialStep(
                number: 1,
                title: 'Record Your Speech',
                description:
                    'Tap the microphone button in the center of the bottom navigation bar to start a new recording. Speak clearly and naturally.',
                icon: Icons.mic,
              ),
              _buildTutorialStep(
                number: 2,
                title: 'Review Analysis',
                description:
                    'After recording, VocalLabs will analyze your speech and provide detailed feedback on various aspects like clarity, pace, and filler words.',
                icon: Icons.analytics_outlined,
              ),
              _buildTutorialStep(
                number: 3,
                title: 'Track Progress',
                description:
                    'View your improvement over time in the Progress Dashboard. Set goals and work towards them with each practice session.',
                icon: Icons.trending_up,
              ),
              _buildTutorialStep(
                number: 4,
                title: 'Apply Suggestions',
                description:
                    'Implement the personalized suggestions provided after each analysis to gradually improve your speaking skills.',
                icon: Icons.lightbulb_outline,
              ),
              const SizedBox(height: 24),
              const Text('Video Tutorials', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              _buildVideoTutorialItem(
                title: 'Getting Started with VocalLabs',
                duration: '3:45',
                thumbnail: 'assets/images/tutorial_1.jpg',
                onTap: () {
                  // Play tutorial video
                },
              ),
              const SizedBox(height: 24),
              const Text(
                'Frequently Asked Questions',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              CardLayout(
                child: ExpansionPanelList(
                  elevation: 0,
                  expandedHeaderPadding: EdgeInsets.zero,
                  dividerColor: Colors.grey.shade200,
                  expansionCallback: (int index, bool isExpanded) {
                    setState(() {
                      _faqItems[index]['isExpanded'] = !isExpanded;
                    });
                  },
                  children:
                      _faqItems.map<ExpansionPanel>((
                        Map<String, dynamic> item,
                      ) {
                        return ExpansionPanel(
                          headerBuilder: (
                            BuildContext context,
                            bool isExpanded,
                          ) {
                            return ListTile(
                              title: Text(
                                item['question'],
                                style: AppTextStyles.body1.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                          body: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              item['answer'],
                              style: AppTextStyles.body2,
                            ),
                          ),
                          isExpanded: item['isExpanded'],
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Still Need Help?', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    _buildHelpOption(
                      icon: Icons.email_outlined,
                      title: 'Contact Us',
                      description: 'Get help via email within 24 hours',
                      onTap: () {
                        Navigator.pushNamed(context, '/contact');
                      },
                    ),
                    const Divider(),
                    _buildHelpOption(
                      icon: Icons.chat_bubble_outline,
                      title: 'Live Chat',
                      description: 'Chat with our support team',
                      onTap: () {
                        // Open live chat
                      },
                    ),
                    const Divider(),
                    _buildHelpOption(
                      icon: Icons.forum_outlined,
                      title: 'Community Forum',
                      description: 'Connect with other users',
                      onTap: () {
                        // Open community forum
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialStep({
    required int number,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: CardLayout(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: AppColors.primaryBlue, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: AppTextStyles.body1.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(description, style: AppTextStyles.body2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoTutorialItem({
    required String title,
    required String duration,
    required String thumbnail,
    required VoidCallback onTap,
  }) {
    return CardLayout(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 120,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Use Image.asset in a real app
                Container(color: AppColors.lightBlue),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Duration: $duration', style: AppTextStyles.body2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpOption({
    required IconData icon,
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(description, style: AppTextStyles.body2),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.lightText),
          ],
        ),
      ),
    );
  }
}
