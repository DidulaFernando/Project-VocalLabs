import librosa
import numpy as np
import parselmouth
from parselmouth.praat import call
import statistics

def analyze_voice_modulation(audio_path):
    """Analyze voice modulation parameters from the audio file."""
    try:
        # Load the audio file
        y, sr = librosa.load(audio_path)
        sound = parselmouth.Sound(audio_path)
        
        # Analyze pitch
        pitch = sound.to_pitch()
        pitch_values = pitch.selected_array['frequency']
        pitch_values = pitch_values[pitch_values != 0]
        
        # Calculate pitch statistics
        mean_pitch = np.mean(pitch_values)
        std_pitch = np.std(pitch_values)
        pitch_range = np.max(pitch_values) - np.min(pitch_values)
        
        # Analyze volume/intensity
        intensity = sound.to_intensity()
        intensity_values = intensity.values[0]
        mean_intensity = np.mean(intensity_values)
        intensity_range = np.max(intensity_values) - np.min(intensity_values)
        
        # Calculate emphasis points (significant pitch/intensity variations)
        emphasis_points = detect_emphasis_points(pitch_values, intensity_values)
        
        # Calculate individual scores
        pitch_vol_score = (calculate_pitch_score(mean_pitch, std_pitch, pitch_range) + 
                          calculate_volume_score(intensity_values)) / 2
        emphasis_score = calculate_emphasis_score(emphasis_points, len(y)/sr, 
                                               pitch_values, intensity_values)
        
        total_score = pitch_vol_score + emphasis_score
        
        return {
            'pitch_analysis': {
                'mean_pitch': float(mean_pitch),
                'pitch_range': float(pitch_range),
                'pitch_variation': float(std_pitch)
            },
            'volume_analysis': {
                'mean_intensity': float(mean_intensity),
                'intensity_range': float(intensity_range)
            },
            'emphasis_analysis': {
                'emphasis_points_count': len(emphasis_points),
                'emphasis_distribution': calculate_emphasis_distribution(emphasis_points, len(y)/sr)
            },
            'scores': {
                'pitch_and_volume_score': float(pitch_vol_score),
                'emphasis_score': float(emphasis_score),
                'total_score': float(total_score),
                'detailed_scores': {
                    'pitch_variation_penalty': 10 - float(pitch_vol_score),
                    'emphasis_penalty': 10 - float(emphasis_score)
                }
            }
        }
    except Exception as e:
        return {
            'error': f"Error analyzing voice modulation: {str(e)}"
        }

def detect_emphasis_points(pitch_values, intensity_values):
    """Detect points of emphasis based on pitch and intensity variations."""
    emphasis_points = []
    pitch_threshold = np.std(pitch_values) * 1.5
    intensity_threshold = np.std(intensity_values) * 1.5
    
    for i in range(1, len(pitch_values) - 1):
        if (abs(pitch_values[i] - pitch_values[i-1]) > pitch_threshold or 
            abs(intensity_values[i] - intensity_values[i-1]) > intensity_threshold):
            emphasis_points.append(i)
    
    return emphasis_points

def calculate_pitch_score(mean_pitch, std_pitch, pitch_range):
    """Calculate score for pitch variation and range (0-10)."""
    score = 10.0  # Start with full score
    
    # Evaluate pitch variation (5 points)
    ideal_std_pitch = 30  # Hz
    if std_pitch < 10:  # Too monotone
        score -= 4
    elif std_pitch < 20:  # Slightly monotone
        score -= 2
    elif std_pitch > 50:  # Too erratic
        score -= 3
    
    # Evaluate pitch range (5 points)
    ideal_range = 100  # Hz
    if pitch_range < 50:  # Too flat
        score -= 4
    elif pitch_range > 200:  # Too extreme
        score -= 3
    
    return max(0, min(10, score))

def calculate_volume_score(intensity_values):
    """Calculate score for volume consistency (part of pitch & volume score)."""
    score = 10.0
    
    # Calculate volume consistency
    intensity_std = np.std(intensity_values)
    intensity_range = np.max(intensity_values) - np.min(intensity_values)
    
    # Penalize for inconsistent volume
    if intensity_std > 15:  # High variation
        score -= 3
    if intensity_range > 40:  # Extreme changes
        score -= 3
    
    return max(0, min(10, score))

def calculate_emphasis_score(emphasis_points, duration, pitch_values, intensity_values):
    """Calculate score for emphasis points (0-10)."""
    score = 10.0
    
    # Calculate ideal number of emphasis points (roughly 1 every 3 seconds)
    ideal_emphasis_count = duration / 3
    actual_count = len(emphasis_points)
    
    # Score based on number of emphasis points (4 points)
    if actual_count < ideal_emphasis_count * 0.5:  # Too few emphasis points
        score -= 3
    elif actual_count > ideal_emphasis_count * 2:  # Too many emphasis points
        score -= 2
    
    # Score emphasis distribution (3 points)
    distribution = calculate_emphasis_distribution(emphasis_points, duration)
    if max(distribution) > len(emphasis_points) * 0.5:  # Too clustered
        score -= 2
    
    # Score emphasis intensity (3 points)
    emphasis_intensities = [intensity_values[p] for p in emphasis_points if p < len(intensity_values)]
    if emphasis_intensities:
        avg_emphasis_intensity = np.mean(emphasis_intensities)
        if avg_emphasis_intensity < np.mean(intensity_values) * 1.1:  # Weak emphasis
            score -= 2
        elif avg_emphasis_intensity > np.mean(intensity_values) * 1.5: # Too strong
            score -= 2
    
    return max(0, min(10, score))

def calculate_emphasis_distribution(emphasis_points, duration):
    """Calculate how well-distributed the emphasis points are."""
    if not emphasis_points:
        return 0
    
    segments = 4  # Divide speech into 4 quarters
    segment_duration = duration / segments
    distribution = [0] * segments
    
    for point in emphasis_points:
        segment = int((point / len(emphasis_points)) * segments)
        if segment >= segments:
            segment = segments - 1
        distribution[segment] += 1
    
    return distribution
