// lib/screens/landing_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'Welcome to VocalLabs',
      'subtitle': 'Your personal speech coach',
      'description':
          'Improve your public speaking skills with objective analysis and personalized feedback.',
      'image': 'assets/images/onboarding_1.png',
      'color': const Color(0xFF87ACFF),
    },
    {
      'title': 'Speech Analysis',
      'subtitle': 'Get detailed insights',
      'description':
          'Our AI technology analyzes your speech patterns, pace, filler words, and more to help you become a better speaker.',
      'image': 'assets/images/onboarding_2.png',
      'color': const Color(0xFF5C86E6),
    },
    {
      'title': 'Track Your Progress',
      'subtitle': 'See your improvement over time',
      'description':
          'Monitor your speaking skills development with visual progress tracking and detailed analytics.',
      'image': 'assets/images/onboarding_3.png',
      'color': const Color(0xFF3B5EC2),
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient that changes with page
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  _pages[_currentPage]['color'],
                  _pages[_currentPage]['color'].withOpacity(0.8),
                  _pages[_currentPage]['color'].withOpacity(0.6),
                  Colors.white,
                ],
                stops: const [0.0, 0.4, 0.6, 0.9],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  flex: 6,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (int page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    itemBuilder: (context, index) {
                      return _buildOnboardingPage(
                        title: _pages[index]['title'],
                        subtitle: _pages[index]['subtitle'],
                        description: _pages[index]['description'],
                        imagePath: _pages[index]['image'],
                      );
                    },
                  ),
                ),

                // Page indicator
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentPage ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color:
                              index == _currentPage
                                  ? AppColors.primaryBlue
                                  : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),

                // Buttons
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        CustomButton(
                          text:
                              _currentPage == _pages.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                          onPressed: () {
                            if (_currentPage == _pages.length - 1) {
                              // On last page, navigate to login
                              Navigator.pushReplacementNamed(context, '/login');
                            } else {
                              // Go to next page
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        if (_currentPage < _pages.length - 1)
                          TextButton(
                            onPressed: () {
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: AppColors.darkText.withOpacity(0.7),
                                fontSize: 16,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingPage({
    required String title,
    required String subtitle,
    required String description,
    required String imagePath,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image Placeholder (replace with actual image )
          Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Icon(
                _getIconForPage(title),
                size: 100,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  IconData _getIconForPage(String title) {
    if (title.contains('Welcome')) {
      return Icons.record_voice_over;
    } else if (title.contains('Analysis')) {
      return Icons.analytics_outlined;
    } else {
      return Icons.trending_up;
    }
  }
}
