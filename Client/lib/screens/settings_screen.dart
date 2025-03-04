// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _automaticAnalysis = true;
  bool _darkModeEnabled = false;
  String _selectedLanguage = 'English';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('App Preferences', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    _buildSwitchSetting(
                      icon: Icons.notifications_none,
                      title: 'Notifications',
                      subtitle: 'Receive speech reminders and tips',
                      value: _notificationsEnabled,
                      onChanged: (value) {
                        setState(() {
                          _notificationsEnabled = value;
                        });
                      },
                    ),
                    const Divider(),
                    _buildSwitchSetting(
                      icon: Icons.volume_up,
                      title: 'Sound Effects',
                      subtitle: 'Play sounds during recording and analysis',
                      value: _soundEnabled,
                      onChanged: (value) {
                        setState(() {
                          _soundEnabled = value;
                        });
                      },
                    ),
                    const Divider(),
                    _buildSwitchSetting(
                      icon: Icons.auto_awesome,
                      title: 'Automatic Analysis',
                      subtitle: 'Analyze speeches as soon as recording stops',
                      value: _automaticAnalysis,
                      onChanged: (value) {
                        setState(() {
                          _automaticAnalysis = value;
                        });
                      },
                    ),
                    const Divider(),
                    _buildSwitchSetting(
                      icon: Icons.dark_mode,
                      title: 'Dark Mode',
                      subtitle: 'Switch to dark theme',
                      value: _darkModeEnabled,
                      onChanged: (value) {
                        setState(() {
                          _darkModeEnabled = value;
                        });
                        // Apply theme change
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Speech Settings', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    _buildDropdownSetting(
                      icon: Icons.language,
                      title: 'Language',
                      subtitle: 'Set your primary speech language',
                      value: _selectedLanguage,
                      options: const [
                        'English',
                        'Spanish',
                        'French',
                        'German',
                        'Mandarin',
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedLanguage = value;
                          });
                        }
                      },
                    ),
                    const Divider(),
                    _buildNavigationSetting(
                      icon: Icons.text_fields,
                      title: 'Filler Word Detection',
                      subtitle: 'Customize detected filler words',
                      value: '8 words',
                      onTap: () {
                        // Navigate to filler word settings
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Account', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    _buildNavigationSetting(
                      icon: Icons.person_outline,
                      title: 'Edit Profile',
                      subtitle: 'Update your personal information',
                      onTap: () {
                        // Navigate to profile editor
                      },
                    ),
                    const Divider(),
                    _buildNavigationSetting(
                      icon: Icons.password,
                      title: 'Change Password',
                      subtitle: 'Update your account password',
                      onTap: () {
                        // Navigate to password change
                      },
                    ),
                    const Divider(),
                    _buildNavigationSetting(
                      icon: Icons.backup,
                      title: 'Data Backup',
                      subtitle: 'Backup and restore your speech data',
                      onTap: () {
                        // Navigate to backup settings
                      },
                    ),
                    const Divider(),
                    _buildNavigationSetting(
                      icon: Icons.delete_outline,
                      title: 'Delete Account',
                      subtitle: 'Permanently remove your account and data',
                      textColor: Colors.red,
                      onTap: () {
                        _showDeleteAccountDialog();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('About', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    _buildNavigationSetting(
                      icon: Icons.info_outline,
                      title: 'App Version',
                      subtitle: 'VocalLabs v1.0.0',
                      showArrow: false,
                      onTap: () {
                        // Show version details
                      },
                    ),
                    const Divider(),
                    _buildNavigationSetting(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      onTap: () {
                        // Show terms of service
                      },
                    ),
                    const Divider(),
                    _buildNavigationSetting(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      onTap: () {
                        // Show privacy policy
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

  Widget _buildSwitchSetting({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body1),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.body2),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting<T>({
    required IconData icon,
    required String title,
    String? subtitle,
    required T value,
    required List<T> options,
    required ValueChanged<T?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body1),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.body2),
                ],
              ],
            ),
          ),
          DropdownButton<T>(
            value: value,
            icon: const Icon(Icons.arrow_drop_down),
            elevation: 16,
            style: AppTextStyles.body1,
            underline: Container(height: 0),
            onChanged: onChanged,
            items:
                options.map<DropdownMenuItem<T>>((T value) {
                  return DropdownMenuItem<T>(
                    value: value,
                    child: Text(value.toString()),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationSetting({
    required IconData icon,
    required String title,
    String? subtitle,
    String? value,
    Color? textColor,
    bool showArrow = true,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? AppColors.primaryBlue, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(color: textColor),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(subtitle, style: AppTextStyles.body2),
                  ],
                ],
              ),
            ),
            if (value != null)
              Text(
                value,
                style: AppTextStyles.body2.copyWith(
                  color: AppColors.primaryBlue,
                ),
              ),
            if (showArrow)
              const Icon(Icons.chevron_right, color: AppColors.lightText),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Account'),
            content: const Text(
              'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently lost.',
            ),
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
                  // Implement account deletion
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
