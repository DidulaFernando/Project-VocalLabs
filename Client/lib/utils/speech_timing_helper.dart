import 'package:flutter/material.dart';
import 'package:vocallabs_flutter_app/utils/constants.dart';

class SpeechTimingHelper {
  // Method to parse duration range (e.g., "5-7 minutes")
  static Map<String, int> parseDurationRange(String durationText) {
    // Handle formats like "5-7 minutes" or "4–6 minutes"
    final pattern = RegExp(r'(\d+)[\s\-–]+(\d+)');
    final match = pattern.firstMatch(durationText);
    
    int minSeconds = 300; // Default: 5 minutes
    int maxSeconds = 420; // Default: 7 minutes
    
    if (match != null && match.groupCount >= 2) {
      try {
        final minMinutes = int.parse(match.group(1)!);
        final maxMinutes = int.parse(match.group(2)!);
        
        minSeconds = minMinutes * 60;
        maxSeconds = maxMinutes * 60;
      } catch (e) {
        print('Error parsing duration range: $e');
      }
    }
    
    return {
      'minSeconds': minSeconds,
      'maxSeconds': maxSeconds,
    };
  }
  
  // Check if duration is within expected range
  static bool isWithinRange(int seconds, int minSeconds, int maxSeconds) {
    return seconds >= minSeconds && seconds <= maxSeconds;
  }
  
  // Get status color based on duration
  static Color getStatusColor(int seconds, int minSeconds, int maxSeconds) {
    if (seconds < minSeconds) {
      return AppColors.lightText; // Not reached minimum yet
    } else if (seconds <= maxSeconds) {
      return AppColors.success; // Within range
    } else {
      return AppColors.warning; // Exceeded maximum
    }
  }
  
  // Get feedback message based on duration
  static String getFeedbackMessage(int seconds, int minSeconds, int maxSeconds) {
    if (seconds < minSeconds) {
      final remaining = minSeconds - seconds;
      final mins = remaining ~/ 60;
      final secs = remaining % 60;
      return 'Minimum: ${mins}m ${secs}s remaining';
    } else if (seconds <= maxSeconds) {
      return 'Within expected time range';
    } else {
      final exceeded = seconds - maxSeconds;
      final mins = exceeded ~/ 60;
      final secs = exceeded % 60;
      return 'Exceeded by ${mins}m ${secs}s';
    }
  }
  
  // Format seconds to mm:ss format
  static String formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  // Get speech score adjustment based on timing compliance
  static int getTimingScoreAdjustment(int seconds, int minSeconds, int maxSeconds) {
    if (seconds < minSeconds) {
      // Too short - penalty based on how short
      final shortBy = minSeconds - seconds;
      final shortRatio = shortBy / minSeconds;
      // Penalty up to -10 points, scaled by how short
      return -(shortRatio * 10).round();
    } else if (seconds <= maxSeconds) {
      // Perfect timing - bonus points
      return 5;
    } else {
      // Too long - penalty based on how long
      final longBy = seconds - maxSeconds;
      final longRatio = longBy / maxSeconds;
      // Cap the penalty at -15 points
      return -math.min((longRatio * 15).round(), 15);
    }
  }
}
