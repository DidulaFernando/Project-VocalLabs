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

def evaluate_timing(actual_duration, expected_duration):
    """
    Evaluate how well the speech timing matches the expected duration.
    
    Args:
        actual_duration: Actual duration in seconds
        expected_duration: Expected duration string (e.g., "5–7 minutes")
        
    Returns:
        Score out of 10
    """
    max_score = 10
    score = max_score
    
    # Parse expected duration
    try:
        # Handle different formats like "5-7 minutes", "5–7 minutes", "5 minutes"
        expected_duration = expected_duration.lower().replace('–', '-')
        if '-' in expected_duration:
            # Range format like "5-7 minutes"
            parts = expected_duration.split('-')
            min_minutes = float(parts[0].strip())
            max_minutes_part = parts[1].strip()
            max_minutes = float(max_minutes_part.split(' ')[0])
        else:
            # Single value like "5 minutes"
            min_minutes = max_minutes = float(expected_duration.split(' ')[0])
            
        # Convert to seconds
        min_seconds = min_minutes * 60
        max_seconds = max_minutes * 60
        
        # Allow a 10% buffer on either side
        min_seconds_buffer = min_seconds * 0.9
        max_seconds_buffer = max_seconds * 1.1
        
        # Evaluate based on actual duration
        if actual_duration < min_seconds_buffer:
            # Too short
            percentage_short = (min_seconds_buffer - actual_duration) / min_seconds_buffer
            penalty = percentage_short * 10
            score -= min(8, penalty)  # Cap the penalty at 8 points
        elif actual_duration > max_seconds_buffer:
            # Too long
            percentage_long = (actual_duration - max_seconds_buffer) / max_seconds_buffer
            penalty = percentage_long * 10
            score -= min(8, penalty)  # Cap the penalty at 8 points
    except (ValueError, TypeError, AttributeError) as e:
        # If there's an error parsing the expected duration, give a neutral score
        logging.warning(f"Error evaluating timing: {e}")
        score = 7  # Default to a neutral score if we can't evaluate
    
    return max(0, score)

def calculate_proficiency_score(filler_analysis, pause_analysis, actual_duration_str=None, expected_duration=None):
    filler_score = evaluate_filler_words(filler_analysis)
    pause_score = evaluate_pauses(pause_analysis)
    timing_score = 7  # Default timing score
    
    # Evaluate timing if both durations are provided
    if actual_duration_str and expected_duration:
        try:
            # Convert actual duration string (MM:SS) to seconds
            parts = actual_duration_str.split(':')
            actual_duration = int(parts[0]) * 60 + int(parts[1])
            timing_score = evaluate_timing(actual_duration, expected_duration)
        except (ValueError, IndexError, AttributeError):
            # Use default if parsing fails
            pass
    
    # Calculate final score (now includes timing)
    # Adjust weights: filler (40%), pauses (40%), timing (20%)
    final_score = (filler_score * 0.4) + (pause_score * 0.4) + (timing_score * 0.2)
    
    return {
        'final_score': round(final_score * 2, 1),  # Scale to /20
        'filler_score': round(filler_score, 1),
        'pause_score': round(pause_score, 1),
        'timing_score': round(timing_score, 1),
        'details': {
            'filler_penalty': round(10 - filler_score, 1),
            'pause_penalty': round(10 - pause_score, 1),
            'timing_penalty': round(10 - timing_score, 1)
        }
    }
