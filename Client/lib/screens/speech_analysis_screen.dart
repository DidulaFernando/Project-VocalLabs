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

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
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

      if (_isRecording) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });
  }

  void _startTimer() {
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
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
      Navigator.pushReplacementNamed(context, '/feedback');
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: AppColors.darkText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isRecording ? 'Recording in progress...' : 'Tap to start recording',
          style: AppTextStyles.body1.copyWith(color: AppColors.lightText),
        ),
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
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressIndicator(color: AppColors.primaryBlue),
        SizedBox(height: 32),
        Text('Analyzing Your Speech', style: AppTextStyles.heading2),
        SizedBox(height: 16),
        Text(
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
