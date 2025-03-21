import 'dart:typed_data';

class SpeechModel {
  final String topic;
  final DateTime recordedAt;
  String? transcription;
  Map<String, dynamic>? analysis;
  Uint8List? audioData;
  double? duration; // Actual duration in seconds
  int? score;
  String speechType; // Added for speech type (e.g., "Prepared Speech")
  String expectedDuration; // Added for expected duration range (e.g., "5-7 minutes")
  
  SpeechModel({
    required this.topic,
    DateTime? recordedAt,
    this.transcription,
    this.analysis,
    this.audioData,
    this.duration,
    this.score,
    this.speechType = "Prepared Speech", // Default value
    this.expectedDuration = "5–7 minutes", // Default value
  }) : recordedAt = recordedAt ?? DateTime.now();
  
  // Convert to a map for storage
  Map<String, dynamic> toMap() {
    return {
      'topic': topic,
      'recordedAt': recordedAt.toIso8601String(),
      'transcription': transcription,
      'duration': duration,
      'score': score,
      'speechType': speechType,
      'expectedDuration': expectedDuration,
      // Note: audioData and full analysis might be stored separately due to size
    };
  }
  
  // Create from a map (from storage)
  factory SpeechModel.fromMap(Map<String, dynamic> map) {
    return SpeechModel(
      topic: map['topic'] as String,
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      transcription: map['transcription'] as String?,
      duration: map['duration'] as double?,
      score: map['score'] as int?,
      speechType: map['speechType'] as String? ?? "Prepared Speech",
      expectedDuration: map['expectedDuration'] as String? ?? "5–7 minutes",
    );
  }
}
