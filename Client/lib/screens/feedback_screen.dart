import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'dart:math' as math; // Import math for max function
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'package:vocallabs_flutter_app/screens/advanced_analysis.dart'; // Add this import
import 'package:vocallabs_flutter_app/models/speech_model.dart';

class FeedbackScreen extends StatefulWidget {
  final String transcription;
  final Uint8List? audioData; // Add this line
  final String? audioUrl; // Add this line
  final Map<String, dynamic>? apiResponse; // Add this line
  final SpeechModel? speechModel; // Add speech model parameter

  const FeedbackScreen({
    super.key,
    required this.transcription,
    this.audioData, // Add this line
    this.audioUrl, // Add this line
    this.apiResponse, // Add this line
    this.speechModel, // Add this parameter
  });

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  bool _isPlaying = false;
  double _sliderValue = 0.0;
  String _currentPosition = '00:00';
  String _totalDuration =
      '00:00'; // Initialize with 00:00 instead of fixed 05:45
  late AudioPlayer _audioPlayer;
  Map<String, dynamic>? _apiResponse; // Add this line to store API response
  late SpeechModel _speechModel;
  bool _isWithinDuration = true;
  String _durationFeedback = '';
  int _recordingSeconds = 0;
  int _minDurationSeconds = 300; // Default 5 minutes
  int _maxDurationSeconds = 420; // Default 7 minutes
  bool _audioInitialized = false; // Track if audio was successfully initialized

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Initialize API response from widget
    _apiResponse = widget.apiResponse;

    // Initialize speech model safely
    if (widget.speechModel != null) {
      _speechModel = widget.speechModel!;
    } else {
      // Create default model with safe values
      _speechModel = SpeechModel(
        topic: 'Speech Analysis',
        transcription: widget.transcription,
        analysis: widget.apiResponse,
        audioData: widget.audioData,
        // Initialize with defaults that can be overridden later
        speechType: 'Prepared Speech',
        expectedDuration: '5–7 minutes',
      );
    }

    // Extract duration information if available in apiResponse
    if (_apiResponse != null) {
      try {
        _recordingSeconds = _apiResponse!['recordingSeconds'] as int? ?? 0;
        _isWithinDuration = _apiResponse!['isWithinDuration'] as bool? ?? true;
        _durationFeedback = _apiResponse!['durationFeedback'] as String? ?? '';
        _minDurationSeconds =
            _apiResponse!['minDurationSeconds'] as int? ?? 300;
        _maxDurationSeconds =
            _apiResponse!['maxDurationSeconds'] as int? ?? 420;

        // Ensure we have the expected duration in the model
        if (_apiResponse!.containsKey('duration')) {
          _speechModel.expectedDuration =
              _apiResponse!['duration'] as String? ??
              _speechModel.expectedDuration;
        }
      } catch (e) {
        print('Error parsing API response durations: $e');
        // Keep default values if parsing failed
      }
    }

    _initializeAudio(); // Initialize audio playback

    // Set up listeners for audio player
    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _currentPosition = _formatTime(position.inSeconds);
          final totalDurationSeconds = _parseTimeToSeconds(_totalDuration);
          if (totalDurationSeconds > 0) {
            _sliderValue = position.inSeconds / totalDurationSeconds;
          } else {
            _sliderValue = 0;
          }
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _totalDuration = _formatTime(duration.inSeconds);
        });
      }
    });

    // Handle player completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _sliderValue = 0.0;
          _currentPosition = '00:00';
        });
      }
    });
  }

  Future<void> _initializeAudio() async {
    try {
      if (widget.audioData != null && widget.audioData!.isNotEmpty) {
        // Use the audio data directly without creating a URL
        await _audioPlayer.setSourceBytes(widget.audioData!);
        print('Audio initialized from data');
        _audioInitialized = true;
      } else if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _audioPlayer.setSource(UrlSource(widget.audioUrl!));
        print('Audio initialized from URL');
        _audioInitialized = true;
      } else {
        print('No audio source available');
      }
    } catch (e) {
      print('Error initializing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load audio: $e')));
      }
    }
  }

  @override
  void dispose() {
    // Make sure to release resources
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  int _parseTimeToSeconds(String time) {
    try {
      List<String> parts = time.split(':');
      if (parts.length != 2) return 0;
      return int.parse(parts[0]) * 60 + int.parse(parts[1]);
    } catch (e) {
      print('Error parsing time: $e');
      return 0;
    }
  }

  // Helper method to format seconds into mm:ss
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // Helper method to get color based on duration compliance
  Color _getDurationComplianceColor() {
    if (_isWithinDuration) {
      return AppColors.success;
    } else if (_recordingSeconds < _minDurationSeconds) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  // Helper method to get icon based on duration compliance
  IconData _getDurationComplianceIcon() {
    if (_isWithinDuration) {
      return Icons.check_circle;
    } else if (_recordingSeconds < _minDurationSeconds) {
      return Icons.warning;
    } else {
      return Icons.error;
    }
  }

  // Helper to safely access topic relevance data
  bool hasTopicRelevance() {
    return _apiResponse != null &&
        _apiResponse!.containsKey('speech_development') &&
        _apiResponse!['speech_development'] is Map<String, dynamic> &&
        _apiResponse!['speech_development'].containsKey('topic_relevance');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_speechModel.topic), // Use speech topic in app bar
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
                // Display speech topic
                CardLayout(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Speech Topic:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.lightText,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _speechModel.topic,
                                    style: AppTextStyles.body1.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primaryBlue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _speechModel.speechType,
                                  style: AppTextStyles.body2.copyWith(
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _speechModel.expectedDuration,
                                  style: AppTextStyles.body2.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Add duration compliance indicator
                        if (_recordingSeconds > 0) ...[
                          const Divider(height: 32),
                          Row(
                            children: [
                              Icon(
                                _getDurationComplianceIcon(),
                                color: _getDurationComplianceColor(),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Duration: ${_formatDuration(_recordingSeconds)}',
                                      style: AppTextStyles.body2.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _durationFeedback,
                                      style: AppTextStyles.body2.copyWith(
                                        color: _getDurationComplianceColor(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Overall Score Card - Now clickable
                GestureDetector(
                  onTap: () {
                    // Navigate to Advanced Analysis with the full API response
                    if (_apiResponse != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) => AdvancedAnalysisScreen(
                                proficiencyScores: _apiResponse,
                              ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Analysis data is not available'),
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
                        data: const SliderThemeData(
                          trackHeight: 5,
                          thumbShape: RoundSliderThumbShape(
                            enabledThumbRadius: 6,
                          ),
                        ),
                        child: Slider(
                          value: _sliderValue,
                          onChanged: (value) {
                            setState(() {
                              _sliderValue = value;
                              int totalSeconds = _parseTimeToSeconds(
                                _totalDuration,
                              );
                              int currentSeconds =
                                  (totalSeconds * value).round();
                              _currentPosition = _formatTime(currentSeconds);
                              _audioPlayer.seek(
                                Duration(seconds: currentSeconds),
                              );
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
                              final position =
                                  await _audioPlayer.getCurrentPosition();
                              if (position != null) {
                                final newPosition = position.inSeconds - 10;
                                _audioPlayer.seek(
                                  Duration(seconds: math.max(0, newPosition)),
                                );
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
                              final position =
                                  await _audioPlayer.getCurrentPosition();
                              if (position != null) {
                                final newPosition = position.inSeconds + 10;
                                _audioPlayer.seek(
                                  Duration(seconds: newPosition),
                                );
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
                          widget
                              .transcription, // Use the actual transcription here
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

                // Add Topic Relevance section
                if (hasTopicRelevance()) ...[
                  const SizedBox(height: 24),
                  const Text('Topic Relevance', style: AppTextStyles.heading2),
                  const SizedBox(height: 16),
                  CardLayout(
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Topic: "${_speechModel.topic}"',
                          style: AppTextStyles.body1.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.topic_outlined,
                              color: AppColors.primaryBlue,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Topic Relevance Score',
                                    style: AppTextStyles.body1,
                                  ),
                                  const SizedBox(height: 8),
                                  LinearProgressIndicator(
                                    value:
                                        _apiResponse!['speech_development']['topic_relevance']['score'] /
                                        100,
                                    backgroundColor: AppColors.lightBlue,
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                          AppColors.primaryBlue,
                                        ),
                                    minHeight: 8,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_apiResponse!['speech_development']['topic_relevance']['score']}%',
                                    style: AppTextStyles.body2.copyWith(
                                      color: AppColors.primaryBlue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        if (_apiResponse!['speech_development']['topic_relevance']
                            .containsKey('feedback')) ...[
                          const Text(
                            'Topic Relevance Feedback:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ...(_apiResponse!['speech_development']['topic_relevance']['feedback']
                                  as List)
                              .map(
                                (feedback) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: AppColors.primaryBlue,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          feedback as String,
                                          style: AppTextStyles.body2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

//feedback doc