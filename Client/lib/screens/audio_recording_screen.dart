import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

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

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
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
      print('Error initializing recorder: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        // Create a temporary file path for the recording
        final String path = 'temp_recording.wav';
        
        // Configure recording options
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
        });
        _updateRecordingTime();
      }
    } catch (e) {
      print('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _recordedPath = path;
        _hasRecording = true;
      });
    } catch (e) {
      print('Error stopping recording: $e');
    }
  }

  Future<void> _processAndUpload() async {
    if (_recordedPath == null) return;

    try {
      // Read the file as bytes
      final file = await html.HttpRequest.request(
        _recordedPath!,
        responseType: 'arraybuffer',
      );
      
      // Convert to Uint8List
      final bytes = (file.response as ByteBuffer).asUint8List();

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/playback',
          arguments: bytes,
        );
      }
    } catch (e) {
      print('Error processing recording: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error processing recording')),
      );
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

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                Text(
                  _isRecording ? 'Recording in Progress' : 'Ready to Record',
                  style: AppTextStyles.heading2,
                ),
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
                GestureDetector(
                  onTap: _isRecording ? _stopRecording : _startRecording,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? Colors.red : AppColors.primaryBlue,
                      boxShadow: [
                        BoxShadow(
                          color: (_isRecording ? Colors.red : AppColors.primaryBlue)
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
                      : 'Tap the microphone to start',
                  style: AppTextStyles.body1,
                ),
                if (_hasRecording && !_isRecording) ...[
                  const SizedBox(height: 40),
                  ElevatedButton(
                    onPressed: _processAndUpload,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Upload Recording'),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _hasRecording = false;
                        _recordedPath = null;
                      });
                    },
                    child: const Text('Discard and Record Again'),
                  ),
                ],
                if (!_hasRecording) const Spacer(),
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
