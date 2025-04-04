import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:vocallabs_flutter_app/screens/profile_screen.dart';
import 'package:vocallabs_flutter_app/screens/speech_history_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocallabs_flutter_app/services/speech_storage_service.dart';
import 'package:vocallabs_flutter_app/screens/speech_history_information.dart';
import 'package:vocallabs_flutter_app/models/speech_model.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String _userName = 'User'; // Default to 'User'
  Map<String, double> _progressScores = {
    'speechDevelopment': 0.0,
    'proficiency': 0.0,
    'voiceAnalysis': 0.0,
    'effectiveness': 0.0,
    'vocabulary': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchUserProgress().then((scores) {
      setState(() {
        _progressScores = scores;
      });
    });
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            _userName = userDoc.data()?['name'] ?? 'User';
          });
        }
      }
    } catch (e) {
      print('Error fetching user name: $e');
    }
  }

  // Add method to prompt for speech topic
  Future<Map<String, String>?> _promptForSpeechTopic() async {
    final TextEditingController topicController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    
    // Speech type and duration options
    final List<Map<String, String>> speechTypes = [
      {'type': 'Ice Breaker Speech', 'duration': '4–6 minutes'},
      {'type': 'Prepared Speech', 'duration': '5–7 minutes'},
      {'type': 'Evaluation Speech', 'duration': '2–3 minutes'},
      {'type': 'Table Topics', 'duration': '1–2 minutes'},
    ];
    
    // Default to Prepared Speech (index 1)
    String selectedSpeechType = speechTypes[1]['type']!;
    String selectedDuration = speechTypes[1]['duration']!;
    bool isValidSelection = true; // Added validation state

    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Speech Details'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: topicController,
                  decoration: const InputDecoration(
                    labelText: 'Speech Topic *', // Added asterisk to indicate required
                    hintText: 'E.g., Introduction to Machine Learning',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a topic for your speech';
                    }
                    return null;
                  },
                  maxLength: 100,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Speech Type: *', // Added asterisk to indicate required
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkText,
                      ),
                    ),
                    const Spacer(),
                    if (!isValidSelection)
                      const Text(
                        'Required',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isValidSelection ? Colors.grey.shade300 : Colors.red,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedSpeechType,
                      items: speechTypes.map((item) {
                        return DropdownMenuItem<String>(
                          value: item['type'],
                          child: Text(
                            '${item['type']} (${item['duration']})',
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedSpeechType = value;
                            selectedDuration = speechTypes
                                .firstWhere((item) => item['type'] == value)['duration']!;
                            isValidSelection = true; // Reset error state when selection changes
                          });
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  '* Required fields',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.lightText,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Validate both form and selection
                if (formKey.currentState!.validate()) {
                  if (selectedSpeechType.isEmpty) {
                    setState(() {
                      isValidSelection = false;
                    });
                  } else {
                    Navigator.pop(context, {
                      'topic': topicController.text.trim(),
                      'speechType': selectedSpeechType,
                      'duration': selectedDuration,
                    });
                  }
                }
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  Future<Map<String, double>> _fetchUserProgress() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final speechesSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('speeches')
            .get();

        if (speechesSnapshot.docs.isNotEmpty) {
          // Initialize accumulators for each feature
          double totalSpeechDevelopment = 0.0;
          double totalProficiency = 0.0;
          double totalVoiceAnalysis = 0.0;
          double totalEffectiveness = 0.0;
          double totalVocabulary = 0.0;

          // Iterate through each speech and sum up the scores
          for (var doc in speechesSnapshot.docs) {
            final data = doc.data();
            totalSpeechDevelopment += data['speech_development_score'] ?? 0.0;
            totalProficiency += data['proficiency_score'] ?? 0.0;
            totalVoiceAnalysis += data['voice_analysis_score'] ?? 0.0;
            totalEffectiveness += data['effectiveness_score'] ?? 0.0;
            totalVocabulary += data['vocabulary_evaluation_score'] ?? 0.0;
          }

          // Calculate averages
          int speechCount = speechesSnapshot.docs.length;
          return {
            'speechDevelopment': totalSpeechDevelopment / speechCount,
            'proficiency': totalProficiency / speechCount,
            'voiceAnalysis': totalVoiceAnalysis / speechCount,
            'effectiveness': totalEffectiveness / speechCount,
            'vocabulary': totalVocabulary / speechCount,
          };
        }
      }
    } catch (e) {
      print('Error fetching user progress: $e');
    }

    // Return default values if no speeches or error occurs
    return {
      'speechDevelopment': 0.0,
      'proficiency': 0.0,
      'voiceAnalysis': 0.0,
      'effectiveness': 0.0,
      'vocabulary': 0.0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      _DashboardTab(
        userName: _userName, // Use the fetched userName
        promptForSpeechTopic: _promptForSpeechTopic, // Pass the method here
        progressScores: _progressScores, // Pass the progress scores here
      ),
      const SpeechHistoryScreen(),
      const ProfileScreen(), // ProfileScreen now handles progress data
    ];

    return Scaffold(
      body: screens[_selectedIndex],
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

class _DashboardTab extends StatefulWidget {  // Change to StatefulWidget
  final String userName;
  final Future<Map<String, String>?> Function() promptForSpeechTopic;
  final Map<String, double> progressScores;

  const _DashboardTab({
    required this.userName,
    required this.promptForSpeechTopic,
    required this.progressScores,
  });

  @override
  State<_DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<_DashboardTab> {
  List<SpeechModel> _recentSpeeches = [];
  bool _loadingSpeeches = true;

  @override
  void initState() {
    super.initState();
    _loadRecentSpeeches();
  }

  Future<void> _loadRecentSpeeches() async {
    try {
      final speeches = await SpeechStorageService.getSpeeches();
      setState(() {
        _recentSpeeches = speeches.take(3).toList(); // Get only the 3 most recent
        _loadingSpeeches = false;
      });
    } catch (e) {
      print('Error loading recent speeches: $e');
      setState(() => _loadingSpeeches = false);
    }
  }

  Widget _buildRecentSpeechesSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Recent Speeches', style: AppTextStyles.heading2),
            TextButton(
              onPressed: () {
                final homeState = context.findAncestorStateOfType<_HomeScreenState>();
                if (homeState != null) {
                  homeState.setState(() {
                    homeState._selectedIndex = 1; // Switch to History tab
                  });
                }
              },
              child: const Text('View All', style: TextStyle(color: AppColors.primaryBlue)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_loadingSpeeches)
          const Center(child: CircularProgressIndicator())
        else if (_recentSpeeches.isEmpty)
          const CardLayout(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No speeches recorded yet'),
            ),
          )
        else
          ..._recentSpeeches.map((speech) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CardLayout(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpeechHistoryInformation(speech: speech),
                  ),
                );
              },
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _getScoreColor(speech.score ?? 0).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${speech.score ?? 0}',
                        style: TextStyle(
                          color: _getScoreColor(speech.score ?? 0),
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
                          speech.topic,
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatDate(speech.recordedAt)} • ${_formatDuration(speech.duration ?? 0)}',
                          style: AppTextStyles.body2,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.lightText),
                ],
              ),
            ),
          )).toList(),
      ],
    );
  }

  // Helper methods for formatting
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (date.year == now.year && date.month == now.month && date.day == now.day - 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }

  String _formatDuration(double seconds) {
    final int totalSeconds = seconds.round();
    final int minutes = totalSeconds ~/ 60;
    final int remainingSeconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getScoreColor(int score) {
    if (score >= 85) return AppColors.success;
    if (score >= 70) return AppColors.primaryBlue;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello, ${widget.userName}', style: AppTextStyles.heading1),
                      const Text(
                        'Let\'s improve your speaking skills today',
                        style: AppTextStyles.body2,
                      ),
                    ],
                  ),
                  CircleAvatar(
                    backgroundColor: AppColors.lightBlue,
                    radius: 24,
                    child: Text(
                      widget.userName.isNotEmpty ? widget.userName[0] : 'U',
                      style: const TextStyle(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                      onPressed: () async {
                        // Call the passed callback
                        final result = await widget.promptForSpeechTopic();

                        // Only navigate if results are provided
                        if (result != null) {
                          Navigator.pushNamed(
                            context,
                            '/analysis',
                            arguments: result,
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    CustomButton(
                      text: 'Upload Speech',
                      backgroundColor: Colors.white,
                      textColor: AppColors.primaryBlue,
                      icon: Icons.upload,
                      onPressed: () async {
                        // Call the passed callback
                        final result = await widget.promptForSpeechTopic();

                        // Only navigate if results are provided
                        if (result != null) {
                          Navigator.pushNamed(
                            context,
                            '/upload_confirmation',
                            arguments: result,
                          );
                        }
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
                      progress: (widget.progressScores['speechDevelopment'] ?? 0.0) / 100,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem(
                      label: 'Proficiency',
                      progress: (widget.progressScores['proficiency'] ?? 0.0) / 100,
                      color: AppColors.warning,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem(
                      label: 'Voice Analysis',
                      progress: (widget.progressScores['voiceAnalysis'] ?? 0.0) / 100,
                      color: AppColors.success,
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem(
                      label: 'Speech Effectiveness',
                      progress: (widget.progressScores['effectiveness'] ?? 0.0) / 100,
                      color: const Color.fromARGB(255, 149, 90, 148),
                    ),
                    const SizedBox(height: 16),
                    _buildProgressItem(
                      label: 'Vocabulary Evaluation',
                      progress: (widget.progressScores['vocabulary'] ?? 0.0) / 100,
                      color: const Color.fromARGB(255, 81, 161, 165),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              _buildRecentSpeechesSection(), // Add this line
              const SizedBox(height: 24),
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
}
