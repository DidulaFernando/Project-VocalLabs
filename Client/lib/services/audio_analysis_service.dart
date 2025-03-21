import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AudioAnalysisService {
  static const String baseUrl =
      'http://10.0.2.2:8000'; // Local development server

  /// Uploads audio data and returns the analysis results
  static Future<Map<String, dynamic>> analyzeAudio({
    required Uint8List audioData,
    required String fileName,
    required String topic,
    required String speechType,
    required String expectedDuration,
    required String actualDuration,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/upload/');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);

      // Add audio file
      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        audioData,
        filename: fileName,
        contentType: MediaType('audio', 'mp3'),
      );
      request.files.add(multipartFile);

      // Add form fields
      request.fields['topic'] = topic;
      request.fields['speech_type'] = speechType;
      request.fields['expected_duration'] = expectedDuration;
      request.fields['actual_duration'] = actualDuration;

      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Failed to analyze audio: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error in analyzeAudio: $e');
      throw Exception('Failed to analyze audio: $e');
    }
  }
}
