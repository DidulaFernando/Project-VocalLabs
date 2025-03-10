def evaluate_filler_words(filler_analysis):
    max_score = 10  # Changed from 20 to 10
    score = max_score
    
    # Get filler words per minute from the analysis
    per_minute_data = filler_analysis['Filler Words Per Minute']
    if isinstance(per_minute_data, str):  # "No filler words detected"
        return max_score
        
    for minute, count in per_minute_data.items():
        if 0 <= count <= 2:
            score -= 0.5  # Halved the penalties
        elif 3 <= count <= 5:
            score -= 1
        elif 6 <= count <= 8:
            score -= 2.5
        elif count >= 9:
            score -= 4
    
    return max(0, score)

def evaluate_pauses(pause_analysis):
    max_score = 10  # Changed from 20 to 10
    score = max_score
    
    # Apply penalties based on pause categories
    if pause_analysis['Pauses under 1.5 seconds'] > 5:
        score -= 0.5  # Halved the penalties
        
    if pause_analysis['Pauses between 1.5-3 seconds'] > 3:
        score -= 1
        
    if pause_analysis['Pauses exceeding 3 seconds'] > 2:
        score -= 2.5
        
    if pause_analysis['Pauses exceeding 5 seconds'] > 0:
        score -= 4
    
    return max(0, score)

def calculate_proficiency_score(filler_analysis, pause_analysis):
    filler_score = evaluate_filler_words(filler_analysis)
    pause_score = evaluate_pauses(pause_analysis)
    
    # Final proficiency score (sum of both scores, which are now out of 10 each)
    final_score = filler_score + pause_score
    
    return {
        'final_score': round(final_score, 1),
        'filler_score': round(filler_score, 1),
        'pause_score': round(pause_score, 1),
        'details': {
            'filler_penalty': round(10 - filler_score, 1),
            'pause_penalty': round(10 - pause_score, 1)
        }
    }
