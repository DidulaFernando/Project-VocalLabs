import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? _userProfile;
  int _speechesCount = 0;
  double _avgScore = 0.0;
  String _totalTime = "0h 0m";

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  void _fetchUserProfile() {
    final user = _auth.currentUser;
    if (user == null) {
      // Redirect to login if the user is not logged in
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Fetch user profile data
    _firestore.collection('users').doc(user.uid).snapshots().listen((snapshot) {
      if (!snapshot.exists) {
        // Handle missing user document
        setState(() {
          _userProfile = {'name': 'Unknown', 'email': 'Unknown'};
        });
        print('User document does not exist for UID: ${user.uid}');
        return;
      }

      final userData = snapshot.data();
      if (userData == null) {
        // Handle null data
        setState(() {
          _userProfile = {'name': 'Unknown', 'email': 'Unknown'};
        });
        print('User data is null for UID: ${user.uid}');
        return;
      }

      // Update the user profile
      setState(() {
        _userProfile = userData;
      });

      // Fetch speeches data in real-time
      _firestore
          .collection('users')
          .doc(user.uid)
          .collection('speeches')
          .snapshots()
          .listen((querySnapshot) {
        if (querySnapshot.docs.isEmpty) {
          // Handle empty speeches collection
          setState(() {
            _speechesCount = 0;
            _avgScore = 0.0;
            _totalTime = "0h 0m";
          });
          print('No speeches found for user: ${user.uid}');
          return;
        }

        // Map speeches data
        final speeches = querySnapshot.docs.map((doc) {
          final data = doc.data();
          print('Processing speech data: $data');

          // Parse expected_duration (e.g., "1–2 minutes")
          final duration = _parseExpectedDuration(data['expected_duration']);

          return {
            'score': data['overall_score'] ?? 0, // Use overall_score instead of proficiency_score
            'duration': duration,
          };
        }).toList();

        // Calculate total speeches, average score, and total time
        final totalSpeeches = speeches.length;
        final avgScore = speeches.map((s) => s['score'] as double).reduce((a, b) => a + b) / totalSpeeches;
        final totalTime = speeches.map((s) => s['duration'] as double).reduce((a, b) => a + b);

        // Log calculated values
        print('Total speeches: $totalSpeeches');
        print('Average score: $avgScore');
        print('Total time: $totalTime');

        // Update state with real-time data
        setState(() {
          _speechesCount = totalSpeeches;
          _avgScore = avgScore;
          _totalTime = _formatDuration(totalTime);
        });
      });
    });
  }

  // Helper method to format total time as "Xh Ym"
  String _formatDuration(double totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return '${hours}h ${minutes}m';
  }

  double _parseDuration(String? duration) {
    if (duration == null || duration.isEmpty) return 0.0;
    try {
      final parts = duration.split(':');
      final minutes = int.parse(parts[0]);
      final seconds = int.parse(parts[1]);
      return (minutes * 60 + seconds).toDouble(); // Convert to seconds as double
    } catch (e) {
      print('Error parsing duration: $e');
      return 0.0; // Return 0 if parsing fails
    }
  }

  double _parseExpectedDuration(String? duration) {
    if (duration == null || duration.isEmpty) return 0.0;
    try {
      // Split the range (e.g., "1–2 minutes")
      final parts = duration.split('–');
      if (parts.length == 2) {
        // Take the average of the range
        final minMinutes = double.parse(parts[0].trim());
        final maxMinutes = double.parse(parts[1].replaceAll(' minutes', '').trim());
        return ((minMinutes + maxMinutes) / 2) * 60; // Convert to seconds
      } else if (duration.contains('minute')) {
        // Handle single value (e.g., "1 minute")
        final minutes = double.parse(duration.replaceAll(' minutes', '').replaceAll(' minute', '').trim());
        return minutes * 60; // Convert to seconds
      }
    } catch (e) {
      print('Error parsing expected duration: $e');
    }
    return 0.0; // Return 0 if parsing fails
  }

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
                  child: Center(
                    child: Text(
                      _userProfile?['name']?.substring(0, 1) ?? '',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _userProfile?['name'] ?? 'Loading...',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _userProfile?['email'] ?? 'No email available',
                  style: AppTextStyles.body2,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatItem(value: '$_speechesCount', label: 'Speeches'),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStatItem(
                      value: '${_avgScore.toStringAsFixed(1)}',
                      label: 'Avg. Score',
                      color: AppColors.primaryBlue,
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey.shade300,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                    _buildStatItem(value: _totalTime, label: 'Total Time'),
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
                          );
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