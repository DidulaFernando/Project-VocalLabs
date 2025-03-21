// lib/screens/speech_analysis_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';

class SpeechAnalysisScreen extends StatefulWidget {
  const SpeechAnalysisScreen({super.key});

  @override
  State<SpeechAnalysisScreen> createState() => _SpeechAnalysisScreenState();
}

class _SpeechAnalysisScreenState extends State<SpeechAnalysisScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  int _seconds = 0;
  Timer? _timer;
  bool _isAnalyzing = false;
  String _speechTopic = '';
  String _speechType = 'Prepared Speech';
  String _expectedDuration = '5–7 minutes';
  bool _showTopicDialog = false;

  late AnimationController _animationController;

  // Add new timing-related variables
  int _minDurationSeconds = 300; // Default: 5 minutes
  int _maxDurationSeconds = 420; // Default: 7 minutes
  bool _isWithinTimeRange = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get details from arguments
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null) {
      setState(() {
        _speechTopic = args['topic'] as String? ?? '';
        _speechType = args['speechType'] as String? ?? 'Prepared Speech';
        _expectedDuration = args['duration'] as String? ?? '5–7 minutes';

        // Parse the duration range
        _parseDurationRange(_expectedDuration);
      });
    }
  }

  Future<void> _promptForSpeechTopic() async {
    final TextEditingController topicController = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Speech Topic'),
            content: Form(
              key: formKey,
              child: TextFormField(
                controller: topicController,
                maxLength: 100, // Moved outside of InputDecoration
                decoration: const InputDecoration(
                  labelText: 'Speech Topic',
                  hintText: 'E.g., Introduction to Machine Learning',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a topic for your speech';
                  }
                  return null;
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.pop(context, topicController.text.trim());
                  }
                },
                child: const Text('Continue'),
              ),
            ],
          ),
    );

    if (result == null) {
      // User cancelled the dialog, go back to previous screen
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        _speechTopic = result;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });

    if (_isRecording) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  void _startTimer() {
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _isWithinTimeRange = _isWithinExpectedRange(_seconds);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _analyzeResults() {
    setState(() {
      _isRecording = false;
      _isAnalyzing = true;
    });

    _stopTimer();

    // Simulate analysis delay
    Timer(const Duration(seconds: 3), () {
      // Add timing compliance to the analysis results
      final bool isWithinDuration = _isWithinExpectedRange(_seconds);
      final String durationFeedback = _getDurationStatusMessage(_seconds);

      Navigator.pushReplacementNamed(
        context,
        '/feedback',
        arguments: {
          'topic': _speechTopic,
          'speechType': _speechType,
          'duration': _expectedDuration,
          'recordingSeconds': _seconds,
          'isWithinDuration': isWithinDuration,
          'durationFeedback': durationFeedback,
          'minDurationSeconds': _minDurationSeconds,
          'maxDurationSeconds': _maxDurationSeconds,
        },
      );
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Parse the expected duration to get min and max seconds
  void _parseDurationRange(String durationRange) {
    // Handle formats like "5-7 minutes" or "4–6 minutes"
    final pattern = RegExp(r'(\d+)[\s\-–]+(\d+)');
    final match = pattern.firstMatch(durationRange);

    if (match != null && match.groupCount >= 2) {
      try {
        final minMinutes = int.parse(match.group(1)!);
        final maxMinutes = int.parse(match.group(2)!);

        _minDurationSeconds = minMinutes * 60;
        _maxDurationSeconds = maxMinutes * 60;
      } catch (e) {
        print('Error parsing duration range: $e');
      }
    }
  }

  // Calculate if current duration is within expected range
  bool _isWithinExpectedRange(int seconds) {
    return seconds >= _minDurationSeconds && seconds <= _maxDurationSeconds;
  }

  // Get color based on duration status
  Color _getDurationStatusColor(int seconds) {
    if (seconds < _minDurationSeconds) {
      return AppColors.lightText; // Not reached minimum yet
    } else if (seconds <= _maxDurationSeconds) {
      return AppColors.success; // Within range
    } else {
      return AppColors.warning; // Exceeded maximum
    }
  }

  // Get duration status message
  String _getDurationStatusMessage(int seconds) {
    if (seconds < _minDurationSeconds) {
      final remaining = _minDurationSeconds - seconds;
      final mins = remaining ~/ 60;
      final secs = remaining % 60;
      return 'Minimum: ${mins}m ${secs}s remaining';
    } else if (seconds <= _maxDurationSeconds) {
      return 'Within time range';
    } else {
      final exceeded = seconds - _maxDurationSeconds;
      final mins = exceeded ~/ 60;
      final secs = exceeded % 60;
      return 'Exceeded by ${mins}m ${secs}s';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Recording'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppPadding.screenPadding,
          child: _isAnalyzing ? _buildAnalyzingView() : _buildRecordingView(),
        ),
      ),
    );
  }

  Widget _buildRecordingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(flex: 1),
        // Display speech details
        if (_speechTopic.isNotEmpty) ...[
          CardLayout(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Speech Details:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.darkText,
                    ),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.subject,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _speechTopic,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.category,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _speechType,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.lightText,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.timer,
                        size: 16,
                        color: AppColors.primaryBlue,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _expectedDuration,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.lightText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.lightBlue,
                boxShadow:
                    _isRecording
                        ? [
                          BoxShadow(
                            color: AppColors.primaryBlue.withOpacity(
                              0.5 * _animationController.value,
                            ),
                            spreadRadius: 20 * _animationController.value,
                            blurRadius: 30,
                          ),
                        ]
                        : [],
              ),
              child: Icon(
                _isRecording ? Icons.mic : Icons.mic_none,
                size: 70,
                color: _isRecording ? Colors.red : AppColors.primaryBlue,
              ),
            );
          },
        ),
        const SizedBox(height: 40),
        Text(
          _formatTime(_seconds),
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color:
                _isRecording
                    ? _getDurationStatusColor(_seconds)
                    : AppColors.darkText,
          ),
        ),

        // Add duration progress indicator when recording
        if (_isRecording) ...[
          const SizedBox(height: 8),
          Text(
            _getDurationStatusMessage(_seconds),
            style: TextStyle(
              fontSize: 14,
              color: _getDurationStatusColor(_seconds),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 240,
            child: Stack(
              children: [
                // Background bar
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                // Minimum duration marker
                Positioned(
                  left:
                      240 * (_minDurationSeconds / (_maxDurationSeconds * 1.2)),
                  child: Container(
                    width: 2,
                    height: 8,
                    color: AppColors.success,
                  ),
                ),
                // Maximum duration marker
                Positioned(
                  left:
                      240 * (_maxDurationSeconds / (_maxDurationSeconds * 1.2)),
                  child: Container(
                    width: 2,
                    height: 8,
                    color: AppColors.warning,
                  ),
                ),
                // Progress bar
                Container(
                  height: 8,
                  width: 240 * (_seconds / (_maxDurationSeconds * 1.2)),
                  decoration: BoxDecoration(
                    color: _getDurationStatusColor(_seconds),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          const SizedBox(height: 8),
          Text(
            'Tap to start recording',
            style: AppTextStyles.body1.copyWith(color: AppColors.lightText),
          ),
        ],
        const Spacer(flex: 1),
        if (_isRecording) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(
                icon: Icons.stop,
                color: Colors.red,
                onPressed: _toggleRecording,
              ),
              const SizedBox(width: 32),
              _buildControlButton(
                icon: Icons.pause,
                color: AppColors.warning,
                onPressed: () {
                  // Implement pause functionality
                },
              ),
            ],
          ),
          const SizedBox(height: 32),
          CustomButton(
            text: 'Stop and Analyze',
            backgroundColor: Colors.red,
            onPressed: _analyzeResults,
          ),
        ] else ...[
          _buildControlButton(
            icon: Icons.mic,
            color: AppColors.primaryBlue,
            onPressed: _toggleRecording,
            size: 80,
          ),
          const SizedBox(height: 32),
          CardLayout(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.lightBlue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.lightbulb_outline,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tips for Better Results',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Speak clearly and at a natural pace. Try to minimize background noise.',
                          style: AppTextStyles.body2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAnalyzingView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const CircularProgressIndicator(color: AppColors.primaryBlue),
        const SizedBox(height: 32),
        const Text('Analyzing Your Speech', style: AppTextStyles.heading2),
        const SizedBox(height: 16),
        Text(
          _speechType,
          style: AppTextStyles.body2.copyWith(color: AppColors.lightText),
        ),
        const SizedBox(height: 8),
        Text(
          _speechTopic,
          style: AppTextStyles.body1.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primaryBlue,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'Please wait while we process your recording...',
          style: AppTextStyles.body2,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    double size = 64,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }
}
