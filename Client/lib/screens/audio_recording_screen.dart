// lib/screens/audio_recording_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';

class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen>
    with SingleTickerProviderStateMixin {
  bool _isRecording = false;
  bool _isPaused = false;
  int _seconds = 0;
  Timer? _timer;

  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _isPaused = false;
      _seconds = 0;
    });

    _startTimer();
  }

  void _pauseRecording() {
    setState(() {
      _isPaused = true;
    });

    _timer?.cancel();
  }

  void _resumeRecording() {
    setState(() {
      _isPaused = false;
    });

    _startTimer();
  }

  void _stopRecording() {
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });

    _timer?.cancel();

    // Navigate to review screen
    Navigator.pushNamed(context, '/playback');
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
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
        title: const Text('Record Speech'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (_isRecording) {
              _showDiscardDialog();
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale:
                        _isRecording && !_isPaused
                            ? _pulseAnimation.value
                            : 1.0,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color:
                            _isRecording
                                ? _isPaused
                                    ? Colors.grey.shade300
                                    : AppColors.primaryBlue.withOpacity(0.2)
                                : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        boxShadow:
                            _isRecording && !_isPaused
                                ? [
                                  BoxShadow(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 20,
                                    spreadRadius: 10,
                                  ),
                                ]
                                : null,
                      ),
                      child: Center(
                        child: Icon(
                          _isRecording
                              ? _isPaused
                                  ? Icons.mic_off
                                  : Icons.mic
                              : Icons.mic_none,
                          size: 80,
                          color:
                              _isRecording
                                  ? _isPaused
                                      ? Colors.grey
                                      : Colors.red
                                  : AppColors.primaryBlue,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              Text(
                _formatTime(_seconds),
                style: const TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkText,
                  fontFamily: 'Courier',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _isRecording
                    ? _isPaused
                        ? 'Recording paused'
                        : 'Recording in progress...'
                    : 'Tap the microphone to start',
                style: AppTextStyles.body1.copyWith(color: AppColors.lightText),
              ),
              const Spacer(),
              if (_isRecording) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(
                      icon: Icons.stop,
                      color: Colors.red,
                      label: 'Stop',
                      onPressed: _stopRecording,
                    ),
                    _buildActionButton(
                      icon: _isPaused ? Icons.play_arrow : Icons.pause,
                      color: _isPaused ? AppColors.success : AppColors.warning,
                      label: _isPaused ? 'Resume' : 'Pause',
                      onPressed: _isPaused ? _resumeRecording : _pauseRecording,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                CustomButton(
                  text: 'Stop and Analyze',
                  backgroundColor: Colors.red,
                  onPressed: _stopRecording,
                ),
              ] else ...[
                CustomButton(
                  text: 'Start Recording',
                  icon: Icons.mic,
                  onPressed: _startRecording,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Speak clearly and at a natural pace for best results',
                  style: AppTextStyles.body2,
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          child: Icon(icon, size: 32),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTextStyles.body2),
      ],
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard Recording?'),
            content: const Text(
              'Are you sure you want to discard this recording? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Continue Recording'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Close recording screen
                },
                child: const Text(
                  'Discard',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
