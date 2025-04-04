import re

FILLER_WORDS = {
    'um', 'uh', 'ah', 'er', 'like', 'you know', 'sort of', 'kind of', 'basically',
    'literally', 'actually', 'hmm', 'huh', 'yeah', 'right', 'okay', 'well',
    'kinda', 'gonna', 'wanna', 'i guess', 'so yeah'
}

def clean_word(word):
    # Remove punctuation and extra spaces
    cleaned = re.sub(r'[.,!?"]', '', word.lower()).strip()
    return cleaned

def analyze_filler_words(result):
    """Analyze filler words with much stricter penalties."""
    total_filler_words = 0
    filler_words_per_minute = {}
    total_words = 0
    
    # Process each word with its timestamp
    for segment in result['segments']:
        for word_info in segment.get('words', []):
            total_words += 1
            word = clean_word(word_info['word'])
            
            if word in FILLER_WORDS:
                timestamp = word_info['start']
                minute = int(timestamp // 60)
                total_filler_words += 1
                
                # Update filler words count for this minute
                if minute not in filler_words_per_minute:
                    filler_words_per_minute[minute] = 0
                filler_words_per_minute[minute] += 1

    # Calculate filler word density (percentage of filler words)
    filler_density = total_filler_words / total_words if total_words > 0 else 0
    
    # Format the per-minute breakdown
    minute_breakdown = {}
    for minute, count in sorted(filler_words_per_minute.items()):
        minute_breakdown[f"Minute {minute + 1}"] = count

    # Much stricter scoring system
    score = 10.0  # Start with maximum score
    
    # Density-based penalties (much harsher)
    if filler_density >= 0.15:  # More than 15% fillers
        score = 0.0  # Automatic zero
    elif filler_density >= 0.10:  # 10-15% fillers
        score = 2.0
    elif filler_density >= 0.05:  # 5-10% fillers
        score = 4.0
    else:
        # For lower densities, apply graduated penalties
        score = max(0, 10 - (filler_density * 100))
    
    # Additional per-minute penalties
    for count in filler_words_per_minute.values():
        if count > 6:  # More than 6 fillers in any minute
            score = max(0, score - 4)  # Harsh penalty
        elif count > 4:  # 4-6 fillers in a minute
            score = max(0, score - 3)
        elif count > 2:  # 2-4 fillers in a minute
            score = max(0, score - 2)

    return {
        'Total Filler Words': total_filler_words,
        'Filler Words Per Minute': minute_breakdown,
        'Filler Density': filler_density,
        'Score': round(score, 1)
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
