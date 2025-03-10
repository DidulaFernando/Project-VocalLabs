import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'dart:math' as math; // Import math for max function
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:vocallabs_flutter_app/screens/advanced_analysis.dart'; // Add this import

class FeedbackScreen extends StatefulWidget {
  final String transcription;
  final Uint8List? audioData; // Add this line
  final String? audioUrl; // Add this line
  final Map<String, dynamic>? apiResponse; // Add this line

  const FeedbackScreen({
    super.key, 
    required this.transcription,
    this.audioData, // Add this line
    this.audioUrl, // Add this line
    this.apiResponse, // Add this line
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _isPlaying = false;
  double _sliderValue = 0.0;
  String _currentPosition = '00:00';
  String _totalDuration = '05:45';
  late AudioPlayer _audioPlayer;
  Map<String, dynamic>? _apiResponse;  // Add this line to store API response

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio(); // Add this line
    _apiResponse = widget.apiResponse; // Initialize API response from widget
    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _currentPosition = _formatTime(position.inSeconds);
        _sliderValue = position.inSeconds / _parseTimeToSeconds(_totalDuration);
      });
    });
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _totalDuration = _formatTime(duration.inSeconds);
      });
    });
  }

  Future<void> _initializeAudio() async {
    try {
      if (widget.audioData != null) {
        // Create a temporary URL from the audio data
        final blob = html.Blob([widget.audioData!]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        await _audioPlayer.setSource(UrlSource(url));
        print('Audio initialized from data');
      } else if (widget.audioUrl != null) {
        await _audioPlayer.setSource(UrlSource(widget.audioUrl!));
        print('Audio initialized from URL');
      } else {
        print('No audio source available');
      }
    } catch (e) {
      print('Error initializing audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int _parseTimeToSeconds(String time) {
    List<String> parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech Analysis'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/home');
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: AppPadding.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Overall Score Card - Now clickable
                GestureDetector(
                  onTap: () {
                    if (_apiResponse != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AdvancedAnalysisScreen(
                            proficiencyScores: _apiResponse,
                          ),
                        ),
                      );
                    }
                  },
                  child: CardLayout(
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 32,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Overall Score',
                                style: AppTextStyles.body1.copyWith(
                                  color: AppColors.lightText,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                                color: AppColors.lightText,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '82',
                            style: TextStyle(
                              fontSize: 64,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Great job! Your delivery is improving.',
                            style: AppTextStyles.body1,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Playback Section
                const Text('Speech Playback', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                CardLayout(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.headphones,
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Listen to your speech',
                            style: AppTextStyles.body1,
                          ),
                          const Spacer(),
                          Text(
                            _totalDuration,
                            style: AppTextStyles.body2.copyWith(
                              color: AppColors.lightText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 5,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        ),
                        child: Slider(
                          value: _sliderValue,
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                              int totalSeconds = _parseTimeToSeconds(_totalDuration);
                              int currentSeconds = (totalSeconds * value).round();
                              _currentPosition = _formatTime(currentSeconds);
                              _audioPlayer.seek(Duration(seconds: currentSeconds));
                            });
                          },
                          activeColor: AppColors.primaryBlue,
                          inactiveColor: AppColors.lightBlue,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_currentPosition),
                            Text(_totalDuration),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.replay_10),
                            onPressed: () async {
                              final position = await _audioPlayer.getCurrentPosition();
                              if (position != null) {
                                final newPosition = position.inSeconds - 10;
                                _audioPlayer.seek(Duration(seconds: math.max(0, newPosition)));
                              }
                            },
                            color: AppColors.primaryBlue,
                          ),
                          const SizedBox(width: 16),
                          CircleAvatar(
                            backgroundColor: AppColors.primaryBlue,
                            radius: 24,
                            child: IconButton(
                              icon: Icon(
                                _isPlaying ? Icons.pause : Icons.play_arrow,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                try {
                                  setState(() {
                                    _isPlaying = !_isPlaying;
                                  });
                                  if (_isPlaying) {
                                    await _audioPlayer.resume();
                                  } else {
                                    await _audioPlayer.pause();
                                  }
                                } catch (e) {
                                  print('Error playing audio: $e');
                                  setState(() {
                                    _isPlaying = false;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          IconButton(
                            icon: const Icon(Icons.forward_10),
                            onPressed: () async {
                              final position = await _audioPlayer.getCurrentPosition();
                              if (position != null) {
                                final newPosition = position.inSeconds + 10;
                                _audioPlayer.seek(Duration(seconds: newPosition));
                              }
                            },
                            color: AppColors.primaryBlue,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Transcription Section
                const Text('Transcription', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                CardLayout(
                  child: SizedBox(
                    height: 100,
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          widget.transcription, // Use the actual transcription here
                          style: AppTextStyles.body1.copyWith(height: 1.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Suggestions Section
                const Text('Suggestions', style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                CardLayout(
                  backgroundColor: AppColors.warning.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppColors.warning),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Work on reducing filler words like "um" and "like"',
                          style: AppTextStyles.body1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CardLayout(
                  backgroundColor: AppColors.success.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: AppColors.success),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Try to vary your volume more for emphasis',
                          style: AppTextStyles.body1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                CardLayout(
                  backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        color: AppColors.primaryBlue,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Your pace is excellent, keep it up!',
                          style: AppTextStyles.body1,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
                // Action Buttons
                CustomButton(
                  text: 'Save Results',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/home');
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
