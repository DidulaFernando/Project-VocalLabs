// lib/screens/about_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About VocalLabs')),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: AppColors.lightBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mic,
                  size: 60,
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'VocalLabs',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('Version 1.0.0', style: AppTextStyles.body2),
              const SizedBox(height: 30),
              const CardLayout(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Our Mission', style: AppTextStyles.heading2),
                      SizedBox(height: 12),
                      Text(
                        'VocalLabs is dedicated to helping people become better public speakers through objective analysis, personalized feedback, and consistent practice. We believe that everyone has the potential to be an effective communicator, and our goal is to make professional-level speech coaching accessible to all.',
                        style: AppTextStyles.body1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CardLayout(
                child: Column(
                  children: [
                    _buildFeatureItem(
                      icon: Icons.analytics_outlined,
                      title: 'Objective Analysis',
                      description:
                          'Get detailed feedback on your speaking patterns without human bias.',
                    ),
                    const Divider(),
                    _buildFeatureItem(
                      icon: Icons.trending_up,
                      title: 'Progress Tracking',
                      description:
                          'Monitor your improvement over time with visual analytics.',
                    ),
                    const Divider(),
                    _buildFeatureItem(
                      icon: Icons.support_agent,
                      title: 'Personalized Coaching',
                      description:
                          'Receive tailored suggestions based on your unique speech patterns.',
                    ),
                    const Divider(),
                    _buildFeatureItem(
                      icon: Icons.shield_outlined,
                      title: 'Privacy First',
                      description:
                          'Your speech data is private and secure, always.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const CardLayout(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Our Team', style: AppTextStyles.heading2),
                      SizedBox(height: 12),
                      Text(
                        'VocalLabs was created by a dedicated team of speech therapists, AI researchers, and public speaking coaches who believe in the power of effective communication. Together, we\'ve built a tool that combines cutting-edge technology with proven speech improvement techniques.',
                        style: AppTextStyles.body1,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Connect With Us', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialButton(
                    icon: Icons.language,
                    onTap: () {
                      // Open website
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    icon: Icons.facebook,
                    onTap: () {
                      // Open Facebook
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    icon: Icons.alternate_email,
                    onTap: () {
                      // Open Twitter
                    },
                  ),
                  const SizedBox(width: 16),
                  _buildSocialButton(
                    icon: Icons.video_library,
                    onTap: () {
                      // Open YouTube
                    },
                  ),
                ],
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      // Show terms of service
                    },
                    child: const Text('Terms of Service'),
                  ),
                  const Text(' • '),
                  TextButton(
                    onPressed: () {
                      // Show privacy policy
                    },
                    child: const Text('Privacy Policy'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '© 2025 VocalLabs. All rights reserved.',
                style: AppTextStyles.body2.copyWith(color: AppColors.lightText),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
