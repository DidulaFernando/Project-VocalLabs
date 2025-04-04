import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'dart:typed_data';
import 'dart:io' if (dart.library.html) 'dart:html' as io;
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart' as path_provider;

class AudioRecordingScreen extends StatefulWidget {
  const AudioRecordingScreen({super.key});

  @override
  State<AudioRecordingScreen> createState() => _AudioRecordingScreenState();
}

class _AudioRecordingScreenState extends State<AudioRecordingScreen> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  String _recordingTime = '00:00';
  DateTime? _startTime;
  String? _recordedPath;
  bool _hasRecording = false;
  bool _isWeb = false;
  bool _isProcessing = false;
  final int _maxRecordingDuration = 300; // 5 minutes in seconds

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
    _isWeb = identical(0, 0.0);
    _initializeRecorder();
  }

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

  void _startMaxDurationTimer() {
    Future.delayed(Duration(seconds: _maxRecordingDuration), () {
      if (_isRecording) {
        _stopRecording();
      }
    });
  }

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
        // Pass additional required fields along with the audio bytes
        Navigator.pushReplacementNamed(
          context, 
          '/playback',
          arguments: {
            'fileBytes': bytes,
            'topic': 'Untitled Speech', // Default topic
            'speechType': 'Prepared Speech', // Default type
            'duration': '5–7 minutes', // Default duration
          },
        );
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

  void _discardRecording() {
    setState(() {
      _hasRecording = false;
      _recordedPath = null;
      _recordingTime = '00:00';
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String statusText;
    if (_isRecording) {
      statusText = 'Recording in Progress';
    } else if (_hasRecording) {
      statusText = 'Recording Complete';
    } else {
      statusText = 'Ready to Record';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Speech'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
        ),
      ),
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
