// Import necessary packages for audio recording, file handling, and UI
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart' as path_provider;

/// A screen widget that handles audio recording functionality.
/// Provides UI for recording, stopping, and managing audio recordings.
class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

/// State class for AudioRecordingScreen that manages recording logic and UI state
class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  // Audio recorder instance
  late final AudioRecorder _audioRecorder;
  
  // State variables to track recording status
  bool _isRecording = false;
  String _recordingTime = '00:00';
  DateTime? _startTime;
  String? _recordedPath;
  bool _hasRecording = false;
  bool _isWeb = false;
  bool _isProcessing = false;
  // Maximum recording duration in seconds (5 minutes)
  final int _maxRecordingDuration = 300;

  /// Initialize the recorder and check platform
  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _isWeb = identical(0, 0.0);
    _initializeRecorder();
  }

  /// Request and verify microphone permissions
  Future<void> _initializeRecorder() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Microphone permission denied')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error initializing recorder: $e');
    }
  }

  /// Start recording audio
  /// Sets up recording configuration and initializes timers
  Future<void> _startRecording() async {
    setState(() {
      _recordingTime = '00:00';
    });

    try {
      if (await _audioRecorder.hasPermission()) {
        String path;

        if (_isWeb) {
          path = 'temp_recording.wav';
        } else {
          final directory = await path_provider.getTemporaryDirectory();
          path = '${directory.path}/temp_recording.wav';
        }

        debugPrint('Recording path: $path');

        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.wav,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: path,
        );

        setState(() {
          _isRecording = true;
          _startTime = DateTime.now();
          _hasRecording = false;
        });
        _updateRecordingTime();
        _startMaxDurationTimer();
        debugPrint('Recording started successfully');
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error starting recording: $e')));
      }
    }
  }

  /// Timer to automatically stop recording after max duration
  void _startMaxDurationTimer() {
    Future.delayed(Duration(seconds: _maxRecordingDuration), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

  /// Stop the current recording and save the file
  Future<void> _stopRecording() async {
    try {
      debugPrint('Attempting to stop recording...');

      final isRecording = await _audioRecorder.isRecording();
      debugPrint('Is recorder actually recording? $isRecording');

      if (isRecording) {
        final finalTime = _recordingTime;

        final path = await _audioRecorder.stop();
        debugPrint('Recording stopped, path: $path');

        setState(() {
          _isRecording = false;
          _recordedPath = path;
          _hasRecording = path != null;
          _recordingTime = finalTime;
        });
      } else {
        debugPrint('Recorder was not actually recording');
        setState(() {
          _isRecording = false;
        });
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error stopping recording: $e')));
      }

      setState(() {
        _isRecording = false;
      });
    }
  }

  /// Process the recorded audio and navigate to playback screen
  /// Handles both web and mobile platforms differently
  Future<void> _processAndUpload() async {
    if (_recordedPath == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      Uint8List bytes;

      if (_isWeb) {
        final file = await html.HttpRequest.request(
          _recordedPath!,
          responseType: 'arraybuffer',
        );
        bytes = (file.response as ByteBuffer).asUint8List();
      } else {
        final file = io.File(_recordedPath!);
        bytes = await file.readAsBytes();
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/playback', arguments: bytes);
      }
    } catch (e) {
      debugPrint('Error processing recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing recording: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  /// Update the recording time display every second
  void _updateRecordingTime() {
    if (!_isRecording || _startTime == null) return;

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _isRecording) {
        final duration = DateTime.now().difference(_startTime!);
        setState(() {
          _recordingTime =
              '${duration.inMinutes.toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
        });
        _updateRecordingTime();
      }
    });
  }

  /// Clear the current recording and reset state
  void _discardRecording() {
    setState(() {
      _hasRecording = false;
      _recordedPath = null;
      _recordingTime = '00:00';
    });
  }

  /// Clean up resources when widget is disposed
  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  /// Build the UI for the recording screen
  /// Includes recording button, time display, and action buttons
  @override
  Widget build(BuildContext context) {
    // Determine the current status text based on recording state
    final String statusText;
    if (_isRecording) {
      statusText = 'Recording in Progress';
    } else if (_hasRecording) {
      statusText = 'Recording Complete';
    } else {
      statusText = 'Ready to Record';
    }

    return Scaffold(
      // AppBar with close button
      appBar: AppBar(
        title: const Text('Record Speech'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
      // Main body with recording controls
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: AppPadding.screenPadding,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Text(statusText, style: AppTextStyles.heading2),
                const SizedBox(height: 16),
                Text(
                  _recordingTime,
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                const SizedBox(height: 40),
                if (!_hasRecording || _isRecording)
                  InkWell(
                    onTap: _isRecording ? _stopRecording : _startRecording,
                    customBorder: const CircleBorder(),
                    child: Ink(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            _isRecording ? Colors.red : AppColors.primaryBlue,
                        boxShadow: [
                          BoxShadow(
                            color: (_isRecording
                                    ? Colors.red
                                    : AppColors.primaryBlue)
                                .withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isRecording ? Icons.stop : Icons.mic,
                        size: 48,
                        color: Colors.white,
                      ),
                    ),
                  ),
                const SizedBox(height: 40),
                Text(
                  _isRecording
                      ? 'Tap to stop recording'
                      : _hasRecording
                      ? 'Recording saved'
                      : 'Tap the microphone to start',
                  style: AppTextStyles.body1,
                ),
                if (_hasRecording && !_isRecording) ...[
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _isProcessing ? null : _processAndUpload,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child:
                        _isProcessing
                            ? const CircularProgressIndicator()
                            : const Text('Upload Recording'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _discardRecording,
                    child: const Text('Discard and Record Again'),
                  ),
                ],
                if (!_hasRecording && !_isRecording) const Spacer(),
                if (_isRecording)
                  const Text(
                    'Recording will automatically stop after 5 minutes',
                    style: AppTextStyles.body2,
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
