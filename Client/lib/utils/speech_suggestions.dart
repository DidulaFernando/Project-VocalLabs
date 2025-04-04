class SpeechSuggestion {
  final String category;
  final String suggestion;
  final double score;

  SpeechSuggestion({
    required this.category,
    required this.suggestion,
    required this.score,
  });
}

class SpeechSuggestions {
  static Map<String, String> suggestionMap = {
    'structure': 'Work on organizing your content better. Start with a clear introduction, develop main points sequentially, and end with a strong conclusion.',
    'timeUtilization': 'Practice timing your speech sections better. Allocate appropriate time for introduction, main points, and conclusion.',
    'grammarWordSelection': 'Focus on using more precise vocabulary and correct grammar. Review common grammatical structures and expand your word choice.',
    'pronunciation': 'Practice clear pronunciation of challenging words. Record yourself speaking and focus on improving unclear sounds.',
    'clearPurpose': 'Make your speech objective clearer. State your main message explicitly and ensure all content supports it.',
    'achievement': 'Strengthen how you achieve your speech goals. Include more supporting evidence and examples.',
    'pitchVolume': 'Vary your voice pitch and volume more effectively. Practice using vocal variety to engage your audience.',
    'emphasis': 'Improve how you emphasize key points. Use vocal stress and pacing to highlight important information.',
    'pause': 'Work on strategic pausing. Use deliberate pauses to separate ideas and create impact.',
    'filler': 'Reduce filler words like "um," "uh," and "like." Practice replacing them with purposeful pauses.',
  };
}
