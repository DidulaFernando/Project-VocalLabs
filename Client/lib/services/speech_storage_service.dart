import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/speech_model.dart';

class SpeechStorageService {
  static const String _storageKey = 'speech_history';
  
  // Save a speech to history
  static Future<bool> saveSpeech(SpeechModel speech) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Retrieve existing speeches
      final List<SpeechModel> speeches = await getSpeeches();
      
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
  
  // Get all saved speeches
  static Future<List<SpeechModel>> getSpeeches() async {
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
}
