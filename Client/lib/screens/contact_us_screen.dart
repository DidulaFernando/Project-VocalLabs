// lib/screens/contact_us_screen.dart
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';

class ContactUsScreen extends StatefulWidget {
  const ContactUsScreen({super.key});

  @override
  State<ContactUsScreen> createState() => _ContactUsScreenState();
}

class _ContactUsScreenState extends State<ContactUsScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General Inquiry';

  final List<String> _categories = [
    'General Inquiry',
    'Technical Support',
    'Feedback & Suggestions',
    'Billing Issues',
    'Bug Report',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Us')),
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
                            'We\'re Here to Help',
                            style: AppTextStyles.body1.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Our support team typically responds within 24 hours on business days.',
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text('Contact Form', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _subjectController,
                        label: 'Subject',
                        icon: Icons.subject,
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _messageController,
                        label: 'Message',
                        icon: Icons.message_outlined,
                        maxLines: 5,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: 'Send Message',
                        icon: Icons.send,
                        onPressed: _submitForm,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Alternative Contact Methods',
                style: AppTextStyles.heading2,
              ),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    _buildContactMethod(
                      icon: Icons.email_outlined,
                      title: 'Email',
                      value: 'support@vocallabs.com',
                      onTap: () {
                        // Open email app
                      },
                    ),
                    const Divider(),
                    _buildContactMethod(
                      icon: Icons.phone_outlined,
                      title: 'Phone',
                      value: '+1 (555) 123-4567',
                      onTap: () {
                        // Open phone app
                      },
                    ),
                    const Divider(),
                    _buildContactMethod(
                      icon: Icons.location_on_outlined,
                      title: 'Office Address',
                      value: '123 Innovation Way, Tech City, TC 12345',
                      onTap: () {
                        // Open maps app
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        prefixIcon: const Icon(Icons.category_outlined),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
      ),
      items:
          _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category),
            );
          }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          setState(() {
            _selectedCategory = newValue;
          });
        }
      },
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.body2),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: AppTextStyles.body1.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.lightText),
          ],
        ),
      ),
    );
  }

