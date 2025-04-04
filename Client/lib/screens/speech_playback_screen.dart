import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:math'; // Import the dart:math library
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import dart:convert for JSON decoding
import 'package:vocallabs_flutter_app/screens/feedback_screen.dart'; // Import FeedbackScreen
import 'package:vocallabs_flutter_app/screens/loading_screen.dart';
import 'package:vocallabs_flutter_app/models/speech_model.dart';
import 'package:vocallabs_flutter_app/services/speech_storage_service.dart';
import 'package:vocallabs_flutter_app/services/audio_analysis_service.dart'; // Import the service
import 'package:firebase_auth/firebase_auth.dart';

class SpeechPlaybackScreen extends StatefulWidget {
  final bool isFromHistory;
  final String? audioUrl; // Add audioUrl as a parameter

  const SpeechPlaybackScreen({
    super.key,
    this.isFromHistory = false,
    this.audioUrl,
  });

  @override
  State<SpeechPlaybackScreen> createState() => _SpeechPlaybackScreenState();
}

class _SpeechPlaybackScreenState extends State<SpeechPlaybackScreen> {
  bool _isPlaying = false;
  double _sliderValue = 0.0;
  String _currentPosition = '00:00';
  String _totalDuration = '00:00';
  late AudioPlayer _audioPlayer;
  Uint8List? _fileBytes;
  String? _fileUrl;
  String? _transcription;
  String _speechTopic = '';
  String _speechType = 'Prepared Speech';
  String _expectedDuration = '5–7 minutes';
  late SpeechModel _speechModel;
  bool _isProcessing = false;
  bool _audioInitialized = false;
  Map<String, dynamic>? _apiResponse;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Initialize with default speech model
    _speechModel = SpeechModel(
      topic: _speechTopic,
      speechType: _speechType,
      expectedDuration: _expectedDuration,
      recordedAt: DateTime.now(),
    );

    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    // Set up audio position listener with error handling
    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _currentPosition = _formatTime(position.inSeconds);
          final totalDurationSeconds = _parseTimeToSeconds(_totalDuration);
          // Avoid division by zero or NaN issues
          if (totalDurationSeconds > 0) {
            _sliderValue = position.inSeconds / totalDurationSeconds;
            // Ensure value is within 0-1 bounds
            _sliderValue = _sliderValue.clamp(0.0, 1.0);
          } else {
            _sliderValue = 0.0;
          }
        });
      }
    }, onError: (e) => print('Error in position listener: $e'));

    // Set up audio duration listener
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      if (mounted) {
        setState(() {
          _totalDuration = _formatTime(duration.inSeconds);
        });
      }
    }, onError: (e) => print('Error in duration listener: $e'));

    // Handle player completion
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _sliderValue = 0.0;
          _currentPosition = '00:00';
        });
      }
    }, onError: (e) => print('Error in completion listener: $e'));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Get URL from widget if available
    _fileUrl = widget.audioUrl;

    // Check if arguments is a Map (new format) or Uint8List (old format)
    final args = ModalRoute.of(context)?.settings.arguments;

    if (args is Map<String, dynamic>) {
      // Extract data from arguments Map
      _fileBytes = args['fileBytes'] as Uint8List?;
      _speechTopic = args['topic'] as String? ?? '';
      _speechType = args['speechType'] as String? ?? 'Prepared Speech';
      _expectedDuration = args['duration'] as String? ?? '5–7 minutes';

      // Update the speech model with new data
      _speechModel = SpeechModel(
        topic: _speechTopic,
        audioData: _fileBytes,
        speechType: _speechType,
        expectedDuration: _expectedDuration,
        recordedAt: DateTime.now(),
      );
    } else if (args is Uint8List) {
      // Legacy support for when only audio data is passed
      _fileBytes = args;
    }

    // Initialize audio after arguments are processed
    if (!_audioInitialized) {
      _initializeAudioPlayer();
    }
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      if (_fileBytes != null && _fileBytes!.isNotEmpty) {
        // Use the audio data directly without creating a URL
        await _audioPlayer.setSourceBytes(_fileBytes!);
        _audioInitialized = true;
        print('Audio initialized from data');
      } else if (_fileUrl != null && _fileUrl!.isNotEmpty) {
        await _audioPlayer.setSource(UrlSource(_fileUrl!));
        _audioInitialized = true;
        print('Audio initialized from URL');
      } else if (widget.audioUrl != null && widget.audioUrl!.isNotEmpty) {
        await _audioPlayer.setSource(UrlSource(widget.audioUrl!));
        _audioInitialized = true;
        print('Audio initialized from widget URL');
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
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>?> _uploadFile() async {
    if (_fileBytes == null) return null;

    setState(() {
      _isProcessing = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser; // Get the logged-in user
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Use the service to analyze the audio
      final response = await AudioAnalysisService.analyzeAudio(
        audioData: _fileBytes!,
        fileName: 'speech_recording.wav',
        topic: _speechTopic,
        speechType: _speechType,
        expectedDuration: _expectedDuration,
        actualDuration: _totalDuration,
        userId: user.uid, // Pass the user ID to the backend
      );

      setState(() {
        _transcription = response['transcription'] as String?;

        // Update speech model with transcription and analysis
        _speechModel.transcription = _transcription;
        _speechModel.analysis = response;

        // Extract duration and score
        if (_totalDuration.isNotEmpty) {
          _speechModel.duration =
              _parseTimeToSeconds(_totalDuration).toDouble();
        }

        // Try to extract score or use default
        try {
          final proficiencyScores = response['proficiency_scores'];
          if (proficiencyScores != null) {
            _speechModel.score =
                (proficiencyScores['final_score'] as num).toInt() *
                5; // Scale to 0-100
          } else {
            _speechModel.score = 82; // Default score
          }
        } catch (e) {
          print('Error extracting score: $e');
          _speechModel.score = 82; // Default score if extraction fails
        }
      });

      return response;
    } catch (e) {
      print('Error uploading file: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error analyzing speech: $e')));
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
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

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Discard Recording?'),
            content: const Text(
              'Are you sure you want to discard this recording and start over?',
            ),
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
                  Navigator.pushReplacementNamed(context, '/analysis');
                },
                child: const Text(
                  'Discard and Re-record',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _saveSpeechToHistory(Map<String, dynamic>? apiResponse) async {
    try {
      // Update speech model with final data
      _speechModel.analysis = apiResponse;
      _speechModel.transcription = _transcription;

      if (_totalDuration.isNotEmpty) {
        _speechModel.duration = _parseTimeToSeconds(_totalDuration).toDouble();
      }

      _speechModel.speechType = _speechType;
      _speechModel.expectedDuration = _expectedDuration;
      _speechModel.audioData = _fileBytes;

      // Save to storage
      await SpeechStorageService.saveSpeech(_speechModel);
      print('Speech saved to history');
    } catch (e) {
      print('Error saving speech to history: $e');
    }
  }

  void _handleSaveAndAnalyze() async {
    if (!mounted) return;

    // Keep track of the current loading screen
    late BuildContext loadingContext;

    // Show initial loading screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          loadingContext = context;
          return LoadingScreen(
            apiResponse: null,
            onAnalysisButtonPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => FeedbackScreen(
                    transcription: _transcription ?? '',
                    audioData: widget.isFromHistory ? null : _fileBytes,
                    audioUrl: widget.isFromHistory ? (_fileUrl ?? widget.audioUrl) : null,
                    apiResponse: _apiResponse,
                    speechModel: _speechModel,
                  ),
                ),
              );
            },
          );
        },
      ),
    );

    // Perform upload and analysis
    final apiResponse = await _uploadFile();

    if (!mounted) return;

    if (apiResponse != null) {
      // Save speech data to history
      await _saveSpeechToHistory(apiResponse);
      
      // Store the API response
      _apiResponse = apiResponse;

      // Update loading screen with the API response
      if (mounted) {
        Navigator.pushReplacement(
          loadingContext,
          MaterialPageRoute(
            builder: (context) => LoadingScreen(
              apiResponse: apiResponse,
              onAnalysisButtonPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FeedbackScreen(
                      transcription: _transcription ?? '',
                      audioData: widget.isFromHistory ? null : _fileBytes,
                      audioUrl: widget.isFromHistory ? (_fileUrl ?? widget.audioUrl) : null,
                      apiResponse: apiResponse,
                      speechModel: _speechModel,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    } else {
      // Handle error
      if (mounted) {
        Navigator.pop(context); // Pop loading screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to analyze speech. Please try again.'),
          ),
        );
      }
    }
  }

  void _navigateToFeedback(Map<String, dynamic>? apiResponse) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder:
            (context) => FeedbackScreen(
              transcription: _transcription ?? '',
              audioData: widget.isFromHistory ? null : _fileBytes,
              audioUrl:
                  widget.isFromHistory ? (_fileUrl ?? widget.audioUrl) : null,
              apiResponse: apiResponse,
              speechModel: _speechModel,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFromHistory ? 'Speech Playback' : 'Review Recording',
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            children: [
              const SizedBox(height: 20),
              // Speech info card
              CardLayout(
                child: Column(
                  children: [
                    Text(
                      _speechTopic.isNotEmpty
                          ? _speechTopic
                          : 'Speech Recording',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _speechType,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    if (_totalDuration !=
                        '00:00') // Only show duration if available
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer,
                            size: 16,
                            color: AppColors.lightText,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Duration: $_totalDuration (Expected: $_expectedDuration)',
                            style: AppTextStyles.body2,
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // ... existing code ...

              // Fixed spacing instead of Spacer()
              const SizedBox(height: 40),

              // Buttons section with conditional rendering
              widget.isFromHistory
                  ? Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text: 'View Analysis',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => FeedbackScreen(
                                      transcription: _transcription ?? '',
                                      audioData: _fileBytes,
                                      audioUrl: _fileUrl ?? widget.audioUrl,
                                      speechModel: _speechModel,
                                    ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Share',
                          isOutlined: true,
                          onPressed: () {
                            // Implement share functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Sharing speech recording...'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  )
                  : Row(
                    children: [
                      Expanded(
                        child: CustomButton(
                          text:
                              _isProcessing
                                  ? 'Processing...'
                                  : 'Save and Analyze',
                          // Ensure onPressed is properly handled
                          onPressed:
                              _isProcessing ? () {} : _handleSaveAndAnalyze,
                          // Disable the button visually when processing
                          isDisabled: _isProcessing,
                          // Add icon if supported by CustomButton
                          icon: Icons.save,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Discard',
                          isOutlined: true,
                          // Ensure onPressed is properly handled
                          onPressed: _isProcessing ? () {} : _showDiscardDialog,
                          // Disable the button visually when processing
                          isDisabled: _isProcessing,
                          backgroundColor: Colors.red,
                          textColor: Colors.red,
                        ),
                      ),
                    ],
                  ),

              // Transcript preview with sufficient bottom padding
              if (_transcription != null) ...[
                const SizedBox(height: 20),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Transcript Preview',
                    style: AppTextStyles.heading2,
                  ),
                ),
                const SizedBox(height: 8),
                CardLayout(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _transcription!,
                        style: AppTextStyles.body2.copyWith(height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            // View full transcript in a dialog
                            showDialog(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: const Text('Full Transcript'),
                                    content: SingleChildScrollView(
                                      child: Text(_transcription!),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text('Close'),
                                      ),
                                    ],
                                  ),
                            );
                          },
                          child: const Text('View Full Transcript →'),
                        ),
                      ),
                    ],
                  ),
                ),
                // Extra bottom padding to prevent overflow
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class WaveformPainter extends CustomPainter {
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  WaveformPainter({
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint activePaint =
        Paint()
          ..color = activeColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    final Paint inactivePaint =
        Paint()
          ..color = inactiveColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round;

    const double barWidth = 3;
    const double gap = 3;

    // Draw a simulated waveform
    final int numBars = (size.width / (barWidth + gap)).floor();
    final double progressX = size.width * progress;

    // Generate random but consistent heights using sine function
    for (int i = 0; i < numBars; i++) {
      double x = i * (barWidth + gap);
      double normalizedHeight = 0.1 + 0.8 * (0.5 + 0.5 * sin(i * 0.2));
      double height = size.height * normalizedHeight;
      double top = (size.height - height) / 2;

      canvas.drawLine(
        Offset(x, top),
        Offset(x, top + height),
        x < progressX ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
