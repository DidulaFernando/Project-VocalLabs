import re

FILLER_WORDS = {
    'um', 'uh', 'ah', 'er', 'like', 'you know', 'sort of', 'kind of', 'basically',
    'literally', 'actually', 'hmm', 'huh', 'yeah', 'right', 'okay', 'well'
}

def clean_word(word):
    # Remove punctuation and extra spaces
    cleaned = re.sub(r'[.,!?"]', '', word.lower()).strip()
    return cleaned

def analyze_filler_words(result):
    total_filler_words = 0
    filler_words_per_minute = {}
    
    # Process each word with its timestamp
    for segment in result['segments']:
        for word_info in segment.get('words', []):
            word = clean_word(word_info['word'])
            
            if word in FILLER_WORDS:
                timestamp = word_info['start']
                minute = int(timestamp // 60)
                total_filler_words += 1
                
                # Update filler words count for this minute
                if minute not in filler_words_per_minute:
                    filler_words_per_minute[minute] = 0
                filler_words_per_minute[minute] += 1
    
    # Format the per-minute breakdown as a simple string
    minute_breakdown = {}
    for minute, count in sorted(filler_words_per_minute.items()):
        minute_breakdown[f"Minute {minute + 1}"] = count
    
    return {
        'Total Filler Words': total_filler_words,
        'Filler Words Per Minute': minute_breakdown if minute_breakdown else "No filler words detected"
    }

def analyze_mid_sentence_pauses(transcription):
    # Define pause categories
    pause_categories = {
        'under_1.5': 0,
        'between_1.5_3': 0,
        'exceeding_3': 0,
        'exceeding_5': 0
    }
    
    # Find all pause markers in the text
    pause_pattern = r'\[([\d.]+) second pause\]'
    segments = transcription.split('[')
    
    for i, segment in enumerate(segments[1:], 1):  # Skip first segment as it's before first pause
        pause_match = re.match(pause_pattern, '[' + segment)
        if pause_match:
            pause_duration = float(pause_match.group(1))
            # Check if previous text ends with a period
            previous_text = segments[i-1].strip()
            if not previous_text.endswith('.'):
                # Categorize the pause
                if pause_duration < 1.5:
                    pause_categories['under_1.5'] += 1
                elif 1.5 <= pause_duration <= 3:
                    pause_categories['between_1.5_3'] += 1
                elif 3 < pause_duration <= 5:
                    pause_categories['exceeding_3'] += 1
                else:
                    pause_categories['exceeding_5'] += 1

    return {
        'Pauses under 1.5 seconds': pause_categories['under_1.5'],
        'Pauses between 1.5-3 seconds': pause_categories['between_1.5_3'],
        'Pauses exceeding 3 seconds': pause_categories['exceeding_3'],
        'Pauses exceeding 5 seconds': pause_categories['exceeding_5']
    }
