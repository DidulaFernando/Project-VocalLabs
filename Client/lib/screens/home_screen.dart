import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:vocallabs_flutter_app/screens/profile_screen.dart';
import 'package:vocallabs_flutter_app/screens/speech_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const _DashboardTab(),
    const SpeechHistoryScreen(), // Use SpeechHistoryScreen instead of _HistoryTab
    const ProfileScreen(), // Use ProfileScreen instead of _ProfileTab
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: AppColors.lightText,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: AppPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, Alex', style: AppTextStyles.heading1),
                      Text(
                        'Let\'s improve your speaking skills today',
                        style: AppTextStyles.body2,
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: AppColors.lightBlue,
                    radius: 24,
                    child: Text(
                      'A',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              CardLayout(
                backgroundColor: AppColors.primaryBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start, // Changed to start
                  children: [
                    Text(
                      'Ready to Practice?',
                      style: AppTextStyles.heading2.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Record a speech and get instant feedback',
                      style: AppTextStyles.body2.copyWith(
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: 'Start Recording',
                      backgroundColor: Colors.white,
                      textColor: AppColors.primaryBlue,
                      icon: Icons.mic,
                      onPressed: () {
                        Navigator.pushNamed(context, '/analysis');
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Upload Speech',
                      backgroundColor: Colors.white,
                      textColor: AppColors.primaryBlue,
                      icon: Icons.upload,
                      onPressed: () {
                        Navigator.pushNamed(context, '/upload_confirmation');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Your Progress', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    _buildProgressItem(
                      label: 'Speech Development',
                      progress: 0.75,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem(
                      label: 'Proficiency',
                      progress: 0.60,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem(
                      label: 'Voice Analysis',
                      progress: 0.85,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem(
                      label: 'Speech Effectiveness',
                      progress: 0.56,
                      color: const Color.fromARGB(255, 149, 90, 148),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem(
                      label: 'Vocabulary Evaluation',
                      progress: 0.71,
                      color: const Color.fromARGB(255, 81, 161, 165),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent Speeches', style: AppTextStyles.heading2),
                  TextButton(
                    onPressed: () {
                      // Navigate to History tab
                      final homeState =
                          context.findAncestorStateOfType<_HomeScreenState>();
                      if (homeState != null) {
                        homeState.setState(() {
                          homeState._selectedIndex = 1;
                        });
                      }
                    },
                    child: const Text(
                      'View All',
                      style: TextStyle(color: AppColors.primaryBlue),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRecentSpeechItem(
                title: 'Toastmaster Introduction',
                date: 'Today, 2:30 PM',
                duration: '5:45',
                score: 82,
                context: context,
              ),
              const SizedBox(height: 12),
              _buildRecentSpeechItem(
                title: 'Project Presentation',
                date: 'Yesterday, 10:15 AM',
                duration: '12:20',
                score: 78,
                context: context,
              ),
              const SizedBox(height: 12),
              _buildRecentSpeechItem(
                title: 'Practice Session',
                date: 'Feb 24, 4:45 PM',
                duration: '3:10',
                score: 75,
                context: context,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressItem({
    required String label,
    required double progress,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTextStyles.body1),
            Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.lightBlue,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildRecentSpeechItem({
    required String title,
    required String date,
    required String duration,
    required int score,
    required BuildContext context,
  }) {
    return CardLayout(
      onTap: () {
        // Navigate to speech playback when tapping on history item
        Navigator.pushNamed(context, '/playback_history');
      },
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: AppColors.lightBlue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$score',
                style: const TextStyle(
                  color: AppColors.primaryBlue,
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
                Text(
                  title,
                  style: AppTextStyles.body1.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text('$date • $duration', style: AppTextStyles.body2),
              ],
            ),
          ),
          const Icon(
            Icons.play_arrow,
            color: AppColors.primaryBlue,
          ), // Changed from chevron_right
        ],
      ),
    );
  }
}
