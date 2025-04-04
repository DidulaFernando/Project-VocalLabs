def get_duration_adjusted_thresholds(expected_duration):
    """Calculate thresholds based on expected speech duration"""
    try:
        # Parse expected duration (e.g., "5-7 minutes" or "1-2 minutes")
        expected_duration = expected_duration.lower().replace('–', '-')
        if '-' in expected_duration:
            max_minutes = float(expected_duration.split('-')[1].split()[0])
        else:
            max_minutes = float(expected_duration.split()[0])
        
        # Calculate scaling factor (1.0 for 7 minutes, proportionally less for shorter durations)
        scaling_factor = min(max_minutes / 7.0, 1.0)
        
        return {
            'filler_thresholds': {
                'minimal': round(2 * scaling_factor),  # 0-2 for 7 min speech
                'low': round(5 * scaling_factor),      # 3-5 for 7 min speech
                'moderate': round(8 * scaling_factor), # 6-8 for 7 min speech
            },
            'pause_thresholds': {
                'short': round(5 * scaling_factor),    # up to 5 for 7 min speech
                'medium': round(3 * scaling_factor),   # up to 3 for 7 min speech
                'long': round(2 * scaling_factor),     # up to 2 for 7 min speech
                'very_long': 0                         # always 0
            }
        }
    except (ValueError, AttributeError):
        # Return default thresholds if parsing fails
        return {
            'filler_thresholds': {'minimal': 2, 'low': 5, 'moderate': 8},
            'pause_thresholds': {'short': 5, 'medium': 3, 'long': 2, 'very_long': 0}
        }

def evaluate_filler_words(filler_analysis, expected_duration):
    """Evaluate filler word usage with stricter penalties"""
    max_score = 10
    score = max_score
    
    # Count total filler words
    total_fillers = filler_analysis.get('Total Filler Words', 0)
    
    # Get per-minute breakdown
    per_minute_data = filler_analysis['Filler Words Per Minute']
    
    # Calculate filler word density
    filler_density = filler_analysis.get('Filler Density', 0)
    
    # Harsh penalties for high filler word density
    if filler_density > 0.15:  # More than 15% filler words
        return 0  # Automatic zero for excessive fillers
    elif filler_density > 0.10:  # 10-15% filler words
        score = 2
    elif filler_density > 0.05:  # 5-10% filler words
        score = 4
    else:
        # Apply per-minute penalties
        if isinstance(per_minute_data, dict):
            for minute, count in per_minute_data.items():
                if count > 8:  # More than 8 fillers in any minute
                    score -= 3
                elif count > 5:  # 5-8 fillers
                    score -= 2
                elif count > 2:  # 2-5 fillers
                    score -= 1
    
    return max(0, min(score, max_score))

def evaluate_pauses(pause_analysis, expected_duration):
    """Evaluate pauses with stricter penalties"""
    max_score = 10
    score = max_score
    
    # Penalize more heavily for mid-sentence pauses
    if pause_analysis['Pauses under 1.5 seconds'] > 3:
        score -= 2  # Increased penalty
    
    if pause_analysis['Pauses between 1.5-3 seconds'] > 2:
        score -= 3  # Increased penalty
    
    if pause_analysis['Pauses exceeding 3 seconds'] > 1:
        score -= 4  # Increased penalty
    
    if pause_analysis['Pauses exceeding 5 seconds'] > 0:
        score = 0  # Automatic zero for very long pauses
    
    # Calculate total pauses
    total_pauses = sum(pause_analysis.values())
    if total_pauses > 8:  # Too many pauses overall
        score = max(0, score - 5)
    
    return max(0, score)

def calculate_proficiency_score(filler_analysis, pause_analysis, actual_duration_str=None, expected_duration=None):
    """Calculate overall proficiency with weighted penalties"""
    if not expected_duration:
        expected_duration = "5-7 minutes"
        
    filler_score = evaluate_filler_words(filler_analysis, expected_duration)
    pause_score = evaluate_pauses(pause_analysis, expected_duration)
    
    # More weight on filler words (60%) vs pauses (40%)
    final_score = ((filler_score * 0.6) + (pause_score * 0.4)) * 2
    
    return {
        'final_score': round(final_score, 1),
        'filler_score': round(filler_score, 1),
        'pause_score': round(pause_score, 1),
        'details': {
            'filler_penalty': round(10 - filler_score, 1),
            'pause_penalty': round(10 - pause_score, 1),
            'filler_density': filler_analysis.get('Filler Density', 0),
            'total_fillers': filler_analysis.get('Total Filler Words', 0)
        }
    }
