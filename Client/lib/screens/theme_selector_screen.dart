// lib/screens/theme_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';

class ThemeSelectorScreen extends StatefulWidget {
  const ThemeSelectorScreen({super.key});

  @override
  State<ThemeSelectorScreen> createState() => _ThemeSelectorScreenState();
}

class _ThemeSelectorScreenState extends State<ThemeSelectorScreen> {
  String _selectedTheme = 'System';
  String _selectedAccentColor = 'Blue';
  double _textScaleFactor = 1.0;

  final List<Map<String, dynamic>> _accentColors = [
    {'name': 'Blue', 'color': const Color(0xFF87ACFF)},
    {'name': 'Purple', 'color': const Color(0xFFE284FF)},
    {'name': 'Green', 'color': const Color(0xFF4CAF50)},
    {'name': 'Orange', 'color': const Color(0xFFFFA726)},
    {'name': 'Pink', 'color': const Color(0xFFFF4081)},
    {'name': 'Teal', 'color': const Color(0xFF009688)},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theme Settings')),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text('Appearance', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    _buildThemeOption(
                      title: 'System',
                      subtitle: 'Follow system theme settings',
                      selected: _selectedTheme == 'System',
                      onTap: () {
                        setState(() {
                          _selectedTheme = 'System';
                        });
                      },
                    ),
                    const Divider(),
                    _buildThemeOption(
                      title: 'Light',
                      subtitle: 'Light background with dark text',
                      selected: _selectedTheme == 'Light',
                      onTap: () {
                        setState(() {
                          _selectedTheme = 'Light';
                        });
                      },
                    ),
                    const Divider(),
                    _buildThemeOption(
                      title: 'Dark',
                      subtitle: 'Dark background with light text',
                      selected: _selectedTheme == 'Dark',
                      onTap: () {
                        setState(() {
                          _selectedTheme = 'Dark';
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Accent Color', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select a color for buttons and highlights',
                        style: AppTextStyles.body2,
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children:
                            _accentColors.map((colorData) {
                              return _buildColorOption(
                                color: colorData['color'],
                                name: colorData['name'],
                                selected:
                                    _selectedAccentColor == colorData['name'],
                                onTap: () {
                                  setState(() {
                                    _selectedAccentColor = colorData['name'];
                                  });
                                },
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Text Size', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Adjust the text size throughout the app',
                        style: AppTextStyles.body2,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('A', style: TextStyle(fontSize: 14)),
                          Expanded(
                            child: Slider(
                              value: _textScaleFactor,
                              min: 0.8,
                              max: 1.4,
                              divisions: 6,
                              onChanged: (value) {
                                setState(() {
                                  _textScaleFactor = value;
                                });
                              },
                            ),
                          ),
                          const Text('A', style: TextStyle(fontSize: 24)),
                        ],
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            'Preview Text',
                            style: TextStyle(
                              fontSize: 16 * _textScaleFactor,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'This is how text will appear throughout the app.',
                          style: TextStyle(fontSize: 14 * _textScaleFactor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Additional Settings', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    _buildSwitchSetting(
                      title: 'Reduced Motion',
                      subtitle: 'Decrease animation effects',
                      value: false,
                      onChanged: (value) {
                        // Implement functionality
                      },
                    ),
                    const Divider(),
                    _buildSwitchSetting(
                      title: 'High Contrast',
                      subtitle: 'Improve text visibility',
                      value: false,
                      onChanged: (value) {
                        // Implement functionality
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

  Widget _buildThemeOption({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.body2),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (value) {
                onTap();
              },
              activeColor: AppColors.primaryBlue,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption({
    required Color color,
    required String name,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? Colors.black : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child:
                selected ? const Icon(Icons.check, color: Colors.white) : null,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: AppTextStyles.body2.copyWith(
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchSetting({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
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
}
