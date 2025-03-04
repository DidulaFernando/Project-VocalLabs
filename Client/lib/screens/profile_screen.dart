// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppPadding.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.settings_outlined),
                      onPressed: () {
                        Navigator.pushNamed(context, '/settings');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryBlue, width: 3),
                  ),
                  child: const Center(
                    child: Text(
                      'A',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Alex Johnson',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'alex.johnson@example.com',
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem(value: '24', label: 'Speeches'),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStatItem(
                      value: '82',
                      label: 'Avg. Score',
                      color: AppColors.primaryBlue,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStatItem(value: '3h 45m', label: 'Total Time'),
                  ],
                ),
                const SizedBox(height: 30),
                CardLayout(
                  child: Column(
                    children: [
                      _buildProfileMenuItem(
                        icon: Icons.person_outline,
                        title: 'My Account',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/account',
                          ); // Update this line
                        },
                      ),
                      const Divider(),
                      _buildProfileMenuItem(
                        icon: Icons.show_chart,
                        title: 'My Progress',
                        onTap: () {
                          Navigator.pushNamed(context, '/progress');
                        },
                      ),
                      const Divider(),
                      _buildProfileMenuItem(
                        icon: Icons.history,
                        title: 'Speech History',
                        onTap: () {
                          Navigator.pushNamed(context, '/history');
                        },
                      ),
                      const Divider(),
                      _buildProfileMenuItem(
                        icon: Icons.notifications_none,
                        title: 'Notifications',
                        onTap: () {
                          Navigator.pushNamed(context, '/notifications');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                CardLayout(
                  child: Column(
                    children: [
                      _buildProfileMenuItem(
                        icon: Icons.help_outline,
                        title: 'Help & Support',
                        onTap: () {
                          Navigator.pushNamed(context, '/tutorial');
                        },
                      ),
                      const Divider(),
                      _buildProfileMenuItem(
                        icon: Icons.info_outline,
                        title: 'About VocalLabs',
                        onTap: () {
                          Navigator.pushNamed(context, '/about');
                        },
                      ),
                      const Divider(),
                      _buildProfileMenuItem(
                        icon: Icons.mail_outline,
                        title: 'Contact Us',
                        onTap: () {
                          Navigator.pushNamed(context, '/contact');
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                CustomButton(
                  text: 'Logout',
                  isOutlined: true,
                  backgroundColor: Colors.red,
                  onPressed: () {
                    _showLogoutConfirmationDialog(context);
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required String value,
    required String label,
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color ?? AppColors.darkText,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.body2),
      ],
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primaryBlue, size: 24),
            const SizedBox(width: 16),
            Expanded(child: Text(title, style: AppTextStyles.body1)),
            trailing ??
                const Icon(Icons.chevron_right, color: AppColors.lightText),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
