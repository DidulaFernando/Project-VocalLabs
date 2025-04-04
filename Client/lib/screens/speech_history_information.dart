import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';
import 'package:vocallabs_flutter_app/widgets/custom_button.dart';
import 'package:vocallabs_flutter_app/widgets/card_layout.dart';
import 'package:vocallabs_flutter_app/models/speech_model.dart';
import 'package:audioplayers/audioplayers.dart';

class SpeechHistoryInformation extends StatefulWidget {
  final SpeechModel speech;

  const SpeechHistoryInformation({
    super.key,
    required this.speech,
  });

  @override
  State<SpeechHistoryInformation> createState() => _SpeechHistoryInformationState();
}

class _SpeechHistoryInformationState extends State<SpeechHistoryInformation> {
  bool _isPlaying = false;
  double _sliderValue = 0.0;
  String _currentPosition = '00:00';
  String _totalDuration = '00:00';
  late AudioPlayer _audioPlayer;
  bool _audioInitialized = false;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializeAudio();
    _setupAudioListeners();
  }

  void _setupAudioListeners() {
    _audioPlayer.onPositionChanged.listen((Duration position) {
      if (mounted) {
        setState(() {
          _currentPosition = _formatTime(position.inSeconds);
          final totalDurationSeconds = _parseTimeToSeconds(_totalDuration);
          if (totalDurationSeconds > 0) {
            _sliderValue = position.inSeconds / totalDurationSeconds;
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
      if (widget.speech.audioUrl != null) {
        print('Initializing audio from URL: ${widget.speech.audioUrl}');
        await _audioPlayer.setSource(UrlSource(widget.speech.audioUrl!));
        _audioInitialized = true;
      } else if (widget.speech.audioData != null) {
        print('Initializing audio from binary data');
        await _audioPlayer.setSourceBytes(widget.speech.audioData!);
        _audioInitialized = true;
      } else {
        print('No audio source available');
      }
    } catch (e) {
      print('Error initializing audio: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load audio: $e')),
        );
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
      return 0;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 85) return AppColors.success;
    if (score >= 70) return AppColors.primaryBlue;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.speech.topic),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: AppPadding.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // Speech Information Card
              CardLayout(
                child: Padding(
                  padding: const EdgeInsets.all(16),
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
                                  widget.speech.topic,
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
                                widget.speech.speechType,
                                style: AppTextStyles.body2.copyWith(
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.speech.expectedDuration,
                                style: AppTextStyles.body2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Overall Score Card
              CardLayout(
                backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Overall Score',
                        style: AppTextStyles.heading2,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${(widget.speech.score ?? 0).round()}',
                        style: const TextStyle(
                          fontSize: 64,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Analysis Metrics
              ..._buildAnalysisMetrics(),
              const SizedBox(height: 24),

              // Audio Playback Section
              const Text('Speech Playback', style: AppTextStyles.heading2),
              const SizedBox(height: 16),
              CardLayout(
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.headphones, color: AppColors.primaryBlue),
                        const SizedBox(width: 12),
                        const Text('Listen to your speech', style: AppTextStyles.body1),
                        const Spacer(),
                        Text(_totalDuration, style: AppTextStyles.body2),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: const SliderThemeData(
                        trackHeight: 5,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      ),
                      child: Slider(
                        value: _sliderValue,
                        onChanged: (value) async {
                          setState(() => _sliderValue = value);
                          final seconds = (_parseTimeToSeconds(_totalDuration) * value).round();
                          await _audioPlayer.seek(Duration(seconds: seconds));
                        },
                        activeColor: AppColors.primaryBlue,
                        inactiveColor: AppColors.lightBlue,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.replay_10),
                          onPressed: () async {
                            final position = await _audioPlayer.getCurrentPosition();
                            if (position != null) {
                              await _audioPlayer.seek(
                                Duration(seconds: position.inSeconds - 10),
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
                              if (!_audioInitialized) {
                                print('Audio not initialized, attempting to initialize...');
                                await _initializeAudio();
                              }
                              
                              try {
                                setState(() => _isPlaying = !_isPlaying);
                                if (_isPlaying) {
                                  await _audioPlayer.resume();
                                  print('Audio playback started');
                                } else {
                                  await _audioPlayer.pause();
                                  print('Audio playback paused');
                                }
                              } catch (e) {
                                print('Error controlling audio playback: $e');
                                setState(() => _isPlaying = false);
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
                              await _audioPlayer.seek(
                                Duration(seconds: position.inSeconds + 10),
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
                        widget.speech.transcription ?? 'No transcription available',
                        style: AppTextStyles.body1.copyWith(height: 1.5),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Return Home Button
              CustomButton(
                text: 'Return Home',
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildAnalysisMetrics() {
    // Debug print to verify received data
    print('Building analysis metrics with data:');
    print('Analysis data: ${widget.speech.analysis}');

    // Extract scores from the analysis data
    final speechDevelopment = widget.speech.analysis?['speech_development'] ?? {};
    final vocabularyData = widget.speech.analysis?['vocabulary_evaluation'] ?? {};
    final effectivenessData = widget.speech.analysis?['speech_effectiveness'] ?? {};
    final modulationData = widget.speech.analysis?['modulation_analysis'] ?? {};
    final proficiencyData = widget.speech.analysis?['proficiency_scores'] ?? {};

    // Debug print for individual sections
    print('Speech Development data: $speechDevelopment');
    print('Vocabulary data: $vocabularyData');
    print('Effectiveness data: $effectivenessData');
    print('Modulation data: $modulationData');
    print('Proficiency data: $proficiencyData');

    // Calculate total scores with proper null checking
    final developmentScore = (
      (speechDevelopment['structure']?['score']?.toDouble() ?? 0.0) +
      (speechDevelopment['time_utilization']?['score']?.toDouble() ?? 0.0)
    );

    final vocabularyScore = vocabularyData['vocabulary_score']?.toDouble() ?? 0.0;
    final effectivenessScore = effectivenessData['total_score']?.toDouble() ?? 0.0;
    final modulationScore = modulationData['scores']?['total_score']?.toDouble() ?? 0.0;
    final proficiencyScore = proficiencyData['final_score']?.toDouble() ?? 0.0;

    // Debug print for calculated scores
    print('Calculated scores:');
    print('Development: $developmentScore');
    print('Vocabulary: $vocabularyScore');
    print('Effectiveness: $effectivenessScore');
    print('Modulation: $modulationScore');
    print('Proficiency: $proficiencyScore');

    final analysisMetrics = [
      _buildMetricCard(
        'Speech Development',
        developmentScore,
        Icons.trending_up,
        AppColors.primaryBlue,
      ),
      _buildMetricCard(
        'Vocabulary Evaluation',
        vocabularyScore,
        Icons.menu_book,
        AppColors.accent,
      ),
      _buildMetricCard(
        'Speech Effectiveness',
        effectivenessScore,
        Icons.psychology_alt,
        AppColors.success,
      ),
      _buildMetricCard(
        'Voice Analysis',
        modulationScore,
        Icons.mic,
        AppColors.warning,
      ),
      _buildMetricCard(
        'Proficiency',
        proficiencyScore,
        Icons.verified,
        AppColors.error,
      ),
    ];

    return analysisMetrics;
  }

  Widget _buildMetricCard(String title, double score, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CardLayout(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTextStyles.body1),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: score / 20,
                      backgroundColor: AppColors.lightBlue,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 5,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
