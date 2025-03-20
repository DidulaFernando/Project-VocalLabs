import 'package:flutter/material.dart';
import 'dart:typed_data';
import 'dart:math'; // Import the dart:math library
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:audioplayers/audioplayers.dart';
// Ensure file_selector is imported
import 'package:http/http.dart' as http;
import 'dart:convert'; // Import dart:convert for JSON decoding
import 'feedback_screen.dart'; // Import FeedbackScreen
import 'package:vocallabs_flutter_app/screens/loading_screen.dart';

class SpeechPlaybackScreen extends StatefulWidget {
  final bool isFromHistory;

  const SpeechPlaybackScreen({super.key, this.isFromHistory = false});

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
  String? _transcription; // Add a variable to store the transcription

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudioPlayer();
    _audioPlayer.onPositionChanged.listen((Duration position) {
      setState(() {
        _currentPosition = _formatTime(position.inSeconds);
        _sliderValue =
            position.inSeconds /
            (_parseTimeToSeconds(_totalDuration) == 0
                ? 1
                : _parseTimeToSeconds(_totalDuration));
      });
    });
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      setState(() {
        _totalDuration = _formatTime(duration.inSeconds);
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only initialize if fileBytes is not yet set
    if (_fileBytes == null) {
      _fileBytes = ModalRoute.of(context)?.settings.arguments as Uint8List?;
      if (_fileBytes != null) {
        _initializeAudioPlayer();
      }
    }
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      if (_fileBytes != null) {
        // Use the audio data directly without creating a URL
        await _audioPlayer.setSourceBytes(_fileBytes!);
        print('Audio initialized in playback screen');
      }
    } catch (e) {
      print('Error initializing audio in playback screen: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<dynamic> _uploadFile() async {
    if (_fileBytes == null) return;

    final uri = Uri.parse('http://10.0.2.2:8000/upload/'); // Update the URL
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          _fileBytes!,
          filename: 'uploaded_audio.wav',
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      setState(() {
        _transcription = jsonResponse['transcription'];
      });
      return jsonResponse; // Return the full response
    } else {
      print('File upload failed');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Remove the fileBytes initialization from here since it's now in didChangeDependencies
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
          // Use ListView instead of Column for scrollable content
          child: ListView(
            children: [
              const SizedBox(height: 20),
              CardLayout(
                child: Column(
                  children: [
                    const Text(
                      'Speech Title',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Recorded Today at ${TimeOfDay.now().format(context)}',
                      style: AppTextStyles.body2,
                    ),
                    const SizedBox(height: 8),
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
                          'Duration: $_totalDuration',
                          style: AppTextStyles.body2,
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        const Text('Score: 82', style: AppTextStyles.body2),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Waveform visualization
              CardLayout(
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    const Text('Audio Waveform', style: AppTextStyles.body2),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 100,
                      child: CustomPaint(
                        painter: WaveformPainter(
                          progress: _sliderValue,
                          activeColor: AppColors.primaryBlue,
                          inactiveColor: Colors.grey.shade300,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Playback controls
              CardLayout(
                child: Column(
                  children: [
                    Slider(
                      value: _sliderValue.isNaN ? 0 : _sliderValue,
                      activeColor: AppColors.primaryBlue,
                      inactiveColor: Colors.grey.shade300,
                      onChanged: (value) {
                        setState(() {
                          _sliderValue = value;
                          // Calculate current position based on slider value
                          int totalSeconds = _parseTimeToSeconds(
                            _totalDuration,
                          );
                          int currentSeconds = (totalSeconds * value).round();
                          _currentPosition = _formatTime(currentSeconds);
                          _audioPlayer.seek(Duration(seconds: currentSeconds));
                        });
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_currentPosition),
                          Text(_totalDuration),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10, size: 36),
                          onPressed: () {
                            // Rewind 10 seconds
                            double newValue =
                                _sliderValue -
                                (10 / _parseTimeToSeconds(_totalDuration));
                            setState(() {
                              _sliderValue = newValue < 0 ? 0 : newValue;
                              int currentSeconds =
                                  (_parseTimeToSeconds(_totalDuration) *
                                          _sliderValue)
                                      .round();
                              _currentPosition = _formatTime(currentSeconds);
                              _audioPlayer.seek(
                                Duration(seconds: currentSeconds),
                              );
                            });
                          },
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 20),
                        ElevatedButton(
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryBlue,
                            shape: const CircleBorder(),
                            padding: const EdgeInsets.all(16),
                          ),
                          child: Icon(
                            _isPlaying ? Icons.pause : Icons.play_arrow,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          icon: const Icon(Icons.forward_10, size: 36),
                          onPressed: () {
                            // Forward 10 seconds
                            double newValue =
                                _sliderValue +
                                (10 / _parseTimeToSeconds(_totalDuration));
                            setState(() {
                              _sliderValue = newValue > 1 ? 1 : newValue;
                              int currentSeconds =
                                  (_parseTimeToSeconds(_totalDuration) *
                                          _sliderValue)
                                      .round();
                              _currentPosition = _formatTime(currentSeconds);
                              _audioPlayer.seek(
                                Duration(seconds: currentSeconds),
                              );
                            });
                          },
                          color: AppColors.primaryBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

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
                                      audioUrl: _fileUrl,
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
                          text: 'Save and Analyze',
                          onPressed: () async {
                            // Show loading screen first
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoadingScreen(),
                              ),
                            );

                            // Perform upload and analysis
                            final apiResponse = await _uploadFile();

                            if (_transcription != null &&
                                mounted &&
                                apiResponse != null) {
                              // Create a new URL for the feedback screen
                              String? audioUrl;
                              if (_fileBytes != null) {
                                audioUrl =
                                    'data:audio/wav;base64,${base64Encode(_fileBytes!)}';
                              }

                              // Replace loading screen with feedback screen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => FeedbackScreen(
                                        transcription: _transcription!,
                                        audioData: _fileBytes,
                                        audioUrl: audioUrl,
                                        apiResponse:
                                            apiResponse, // Add this parameter
                                      ),
                                ),
                              );
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: CustomButton(
                          text: 'Discard',
                          isOutlined: true,
                          backgroundColor: Colors.red,
                          onPressed: () {
                            _showDiscardDialog();
                          },
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
                            // View full transcript
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

  int _parseTimeToSeconds(String time) {
    List<String> parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
