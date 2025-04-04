import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vocallabs_flutter_app/models/speech_model.dart';

class SpeechStorageService {
  static const String _storageKey = 'speech_history';
  
  // Save a speech to history
  static Future<bool> saveSpeech(SpeechModel speech) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Retrieve existing speeches
      final List<SpeechModel> speeches = await getSpeechesFromLocalStorage();
      
      // Add new speech
      speeches.add(speech);
      
      // Convert to JSON string and store
      final speechesJson = speeches.map((s) => s.toMap()).toList();
      await prefs.setString(_storageKey, jsonEncode(speechesJson));
      
      return true;
    } catch (e) {
      print('Error saving speech: $e');
      return false;
    }
  }
  
  // Get all saved speeches from local storage
  static Future<List<SpeechModel>> getSpeechesFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final speechesString = prefs.getString(_storageKey);
      
      if (speechesString == null) {
        return [];
      }
      
      final speechesJson = jsonDecode(speechesString) as List;
      return speechesJson.map((json) => 
        SpeechModel.fromMap(json as Map<String, dynamic>)
      ).toList();
    } catch (e) {
      print('Error retrieving speeches: $e');
      return [];
    }
  }

  static double _parseDurationString(String? durationStr) {
    if (durationStr == null) return 0.0;
    try {
      final parts = durationStr.split(':');
      if (parts.length == 2) {
        final minutes = int.parse(parts[0]);
        final seconds = int.parse(parts[1]);
        return (minutes * 60 + seconds).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error parsing duration: $e');
      return 0.0;
    }
  }

  // Get all saved speeches from Firestore
  static Future<List<SpeechModel>> getSpeeches() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('No user logged in');
        return [];
      }

      print('Fetching speeches for user: ${user.uid}');
      
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      
      final speechesCollection = userDoc.collection('speeches');
      print('Accessing speeches collection path: ${speechesCollection.path}');

      final QuerySnapshot speechDocs = await speechesCollection
          .orderBy('recorded_at', descending: true)
          .get();

      print('Found ${speechDocs.docs.length} speech documents');
      
      if (speechDocs.docs.isEmpty) {
        print('No speech documents found in Firestore');
        return [];
      }

      return Future.value(speechDocs.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        print('Processing speech document ID: ${doc.id}');
        print('Speech data: $data');
        
        try {
          final durationInSeconds = _parseDurationString(data['actual_duration'] as String?);
          
          // Add audio URL from Firestore
          final audioUrl = data['audio_url'] as String?;
          print('Audio URL found: $audioUrl');
          
          final speech = SpeechModel(
            topic: data['topic'] ?? 'Untitled Speech',
            transcription: data['transcription'],
            duration: durationInSeconds,
            recordedAt: (data['recorded_at'] as Timestamp).toDate(),
            score: data['overall_score']?.round() ?? 0,
            speechType: data['speech_type'] ?? 'Prepared Speech',
            expectedDuration: data['expected_duration'] ?? '5-7 minutes',
            audioData: null,
            audioUrl: audioUrl, // Add this field
            analysis: {
              'speech_development': {
                'structure': {'score': data['speech_development_score'] ?? 0},
                'time_utilization': {'score': data['time_utilization_score'] ?? 0},
              },
              'vocabulary_evaluation': {
                'vocabulary_score': data['vocabulary_evaluation_score'] ?? 0,
              },
              'speech_effectiveness': {
                'total_score': data['effectiveness_score'] ?? 0,
              },
              'modulation_analysis': {
                'scores': {'total_score': data['voice_analysis_score'] ?? 0},
              },
              'proficiency_scores': {
                'final_score': data['proficiency_score'] ?? 0},
            },
          );
          print('Successfully created SpeechModel for: ${speech.topic}');
          return speech;
        } catch (e) {
          print('Error creating SpeechModel from document ${doc.id}: $e');
          throw e;
        }
      }).toList());

    } catch (e) {
      print('Error in getSpeeches: $e');
      print('Error stack trace: ${StackTrace.current}');
      return [];
    }
  }
}
