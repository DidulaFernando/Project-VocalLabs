import 'dart:io';
import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocallabs_flutter_app/services/auth.dart'; // Import the auth service

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedPlan = 'Free';
  String? _profileImagePath;
  bool _isLoading = true;

  // Auth service instance
  final AuthService _authService = AuthService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current user
      final User? currentUser = _auth.currentUser;

      if (currentUser != null) {
        // Get user profile from Firestore
        final userProfile = await _authService.getUserProfile(currentUser.uid);

        if (userProfile != null) {
          setState(() {
            _nameController.text = userProfile['name'] ?? '';
            _emailController.text = userProfile['email'] ?? '';

            // You can also load additional user data here
            // For example, subscription plan if you have it stored
            // _selectedPlan = userProfile['subscriptionPlan'] ?? 'Free';
          });
        } else {
          // If profile not found, use current user auth data
          setState(() {
            _nameController.text = currentUser.displayName ?? '';
            _emailController.text = currentUser.email ?? '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load profile data')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _profileImagePath = image.path;
      });
      // TODO: Upload image to backend
    }
  }

  void _handlePlanSelection(String plan) {
    setState(() {
      _selectedPlan = plan;
    });
  }

  Future<void> _saveUserProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        setState(() {
          _isLoading = true;
        });

        final User? currentUser = _auth.currentUser;
        if (currentUser != null) {
          // Update user profile in Firestore
          await _firestore.collection('users').doc(currentUser.uid).update({
            'name': _nameController.text,
            'email': _emailController.text,
            'updatedAt': FieldValue.serverTimestamp(),
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully!')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print('Error updating profile: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update profile')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get first letter of name for the avatar
    final firstLetter =
        _nameController.text.isNotEmpty
            ? _nameController.text.substring(0, 1).toUpperCase()
            : 'A';

    return Scaffold(
      appBar: AppBar(title: const Text('Account Settings')),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: AppPadding.screenPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Section
                      Center(
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppColors.lightBlue,
                              backgroundImage:
                                  _profileImagePath != null
                                      ? FileImage(File(_profileImagePath!))
                                      : null,
                              child:
                                  _profileImagePath == null
                                      ? Text(
                                        firstLetter,
                                        style: const TextStyle(
                                          fontSize: 40,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.primaryBlue,
                                        ),
                                      )
                                      : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: AppColors.primaryBlue,
                                radius: 18,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  onPressed: _pickImage,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Personal Details Form
                      const Text(
                        'Personal Details',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              validator: (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Please enter your email';
                                }
                                if (!value!.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),
                            // Save Changes Button
                            CustomButton(
                              text: 'Save Changes',
                              onPressed: _saveUserProfile,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Subscription Plans
                      const Text(
                        'Subscription Plan',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 16),

                      // Free Plan
                      _buildPlanCard(
                        title: 'Free Plan',
                        price: '\$0',
                        period: 'forever',
                        features: const [
                          '5 speech analyses per month',
                          'Basic metrics and feedback',
                          'Limited feature access',
                        ],
                        isSelected: _selectedPlan == 'Free',
                        onSelect: () => _handlePlanSelection('Free'),
                      ),
                      const SizedBox(height: 16),

                      // Pro Monthly Plan
                      _buildPlanCard(
                        title: 'Pro Monthly',
                        price: '\$9.99',
                        period: 'per month',
                        features: const [
                          'Unlimited speech analyses',
                          'Advanced metrics & insights',
                          'Priority support',
                          'No ads',
                        ],
                        isPro: true,
                        isSelected: _selectedPlan == 'Monthly',
                        onSelect: () => _handlePlanSelection('Monthly'),
                      ),
                      const SizedBox(height: 16),

                      // Pro Annual Plan
                      _buildPlanCard(
                        title: 'Pro Annual',
                        price: '\$79.99',
                        period: 'per year',
                        features: const [
                          'Save 33% vs monthly',
                          'Unlimited speech analyses',
                          'Advanced metrics & insights',
                          'Priority support',
                          'No ads',
                          'Export reports',
                        ],
                        isPro: true,
                        isSelected: _selectedPlan == 'Annual',
                        onSelect: () => _handlePlanSelection('Annual'),
                        badgeText: 'BEST VALUE',
                      ),
                      const SizedBox(height: 32),

                      // Pay to Subscribe Button
                      CustomButton(
                        text: 'Pay to Subscribe',
                        onPressed: () {
                          if (_selectedPlan != 'Free') {
                            Navigator.pushNamed(
                              context,
                              '/payment',
                              arguments: {
                                'plan': _selectedPlan,
                                'price':
                                    _selectedPlan == 'Monthly' ? 9.99 : 79.99,
                              },
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required List<String> features,
    bool isPro = false,
    bool isSelected = false,
    required VoidCallback onSelect,
    String? badgeText,
  }) {
    return GestureDetector(
      onTap: onSelect,
      child: CardLayout(
        padding: EdgeInsets.zero,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected ? AppColors.primaryBlue : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.heading2.copyWith(fontSize: 18),
                        ),
                        if (isPro)
                          Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'PRO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(period, style: AppTextStyles.body2),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...features.map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color:
                                  isPro
                                      ? AppColors.primaryBlue
                                      : AppColors.success,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(feature, style: AppTextStyles.body2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (badgeText != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}