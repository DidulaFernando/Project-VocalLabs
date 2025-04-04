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
        
        # Add audio quality assessment
        audio_quality = assess_audio_quality(y, sr)
        quality_compensation = calculate_quality_compensation(audio_quality)
        
        # Calculate individual scores with quality compensation
        pitch_vol_score = (
            calculate_pitch_score(mean_pitch, std_pitch, pitch_range) + 
            calculate_volume_score(intensity_values)
        ) / 2
        pitch_vol_score = adjust_score_for_quality(pitch_vol_score, quality_compensation)
        
        emphasis_score = calculate_emphasis_score(emphasis_points, len(y)/sr, 
                                               pitch_values, intensity_values)
        emphasis_score = adjust_score_for_quality(emphasis_score, quality_compensation)
        
        # Calculate total score (scale to 0-20)
        total_score = (pitch_vol_score + emphasis_score)
        
        # Debug logging
        print(f"\nVoice Modulation Analysis:")
        print(f"Audio Quality Factor: {audio_quality:.2f}")
        print(f"Quality Compensation: +{quality_compensation:.2f}")
        print(f"Raw Pitch/Volume Score: {pitch_vol_score:.2f}")
        print(f"Raw Emphasis Score: {emphasis_score:.2f}")
        print(f"Final Total Score: {total_score:.2f}")
        
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
            'audio_quality': {
                'quality_factor': float(audio_quality),
                'compensation_applied': float(quality_compensation)
            },
            'scores': {
                'pitch_and_volume_score': float(pitch_vol_score),
                'emphasis_score': float(emphasis_score),
                'total_score': float(total_score)
            }
        }
        
    except Exception as e:
        print(f"Error in voice modulation analysis: {e}")
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
    
    # More lenient pitch variation evaluation (6 points)
    # Increased thresholds to account for audio quality
    if std_pitch < 8:  # Too monotone
        score -= 5
    elif std_pitch < 15:  # Slightly monotone
        score -= 3
    elif std_pitch > 60:  # Too erratic
        score -= 4
    
    # Evaluate pitch range (4 points) - more forgiving thresholds
    if pitch_range < 40:  # Too flat
        score -= 3
    elif pitch_range > 250:  # Too extreme
        score -= 2
    
    # Audio quality compensation
    # Add bonus points for clear pitch detection
    if 15 <= std_pitch <= 50 and 50 <= pitch_range <= 200:
        score += 1
    
    return max(5, min(10, score))  # Minimum score raised to 5

def calculate_volume_score(intensity_values):
    """Calculate score for volume consistency."""
    score = 10.0
    
    # More lenient volume consistency evaluation
    intensity_std = np.std(intensity_values)
    intensity_range = np.max(intensity_values) - np.min(intensity_values)
    
    # Adjusted thresholds for poorer audio quality
    if intensity_std > 20:  # High variation (was 15)
        score -= 2  # Reduced penalty (was -3)
    if intensity_range > 50:  # Extreme changes (was 40)
        score -= 2  # Reduced penalty (was -3)
    
    # Bonus for good dynamic range despite audio quality
    if 10 <= intensity_std <= 18:
        score += 1
    
    return max(5, min(10, score))  # Minimum score raised to 5

def calculate_emphasis_score(emphasis_points, duration, pitch_values, intensity_values):
    """Calculate score for emphasis points (0-10)."""
    score = 10.0
    
    # More lenient ideal emphasis count (roughly 1 every 4 seconds instead of 3)
    ideal_emphasis_count = duration / 4
    actual_count = len(emphasis_points)
    
    # Score based on number of emphasis points (5 points)
    emphasis_ratio = actual_count / ideal_emphasis_count
    if emphasis_ratio < 0.4:  # Too few emphasis points (was 0.5)
        score -= 3
    elif emphasis_ratio > 2.5:  # Too many emphasis points (was 2.0)
        score -= 2
    
    # Score emphasis distribution (3 points)
    distribution = calculate_emphasis_distribution(emphasis_points, duration)
    if max(distribution) > len(emphasis_points) * 0.6:  # Too clustered (was 0.5)
        score -= 2
    
    # Score emphasis intensity (2 points) - more forgiving thresholds
    emphasis_intensities = [intensity_values[p] for p in emphasis_points if p < len(intensity_values)]
    if emphasis_intensities:
        avg_emphasis_intensity = np.mean(emphasis_intensities)
        base_intensity = np.mean(intensity_values)
        
        # More lenient intensity thresholds
        if avg_emphasis_intensity < base_intensity * 1.05:  # Weak emphasis (was 1.1)
            score -= 1  # Reduced penalty
        elif avg_emphasis_intensity > base_intensity * 1.6:  # Too strong (was 1.5)
            score -= 1  # Reduced penalty
    
    # Audio quality compensation
    if emphasis_ratio >= 0.4 and emphasis_ratio <= 2.5:
        score += 1  # Bonus for reasonable emphasis pattern
    
    return max(5, min(10, score))  # Minimum score raised to 5

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

def assess_audio_quality(y, sr):
    """Assess the quality of the audio recording."""
    # Calculate signal-to-noise ratio
    noise_floor = np.mean(np.abs(y[y < np.mean(y)]))
    signal_power = np.mean(np.abs(y))
    snr = 20 * np.log10(signal_power / (noise_floor + 1e-10))
    
    # Calculate spectral centroid stability
    spec_cent = librosa.feature.spectral_centroid(y=y, sr=sr)[0]
    cent_stability = 1.0 / (np.std(spec_cent) + 1e-10)
    
    # Combine factors into quality score (0-1)
    quality_score = min(1.0, max(0.0, 
        (snr / 60.0) * 0.6 +  # SNR weight
        (cent_stability / 100.0) * 0.4  # Stability weight
    ))
    
    return quality_score

def calculate_quality_compensation(quality_factor):
    """Calculate score compensation based on audio quality."""
    # More compensation for lower quality audio
    if quality_factor < 0.5:
        return 2.0  # Maximum compensation
    elif quality_factor < 0.7:
        return 1.5
    elif quality_factor < 0.9:
        return 1.0
    return 0.0  # No compensation needed for high quality audio

def adjust_score_for_quality(score, compensation):
    """Adjust a score based on audio quality compensation."""
    return min(10.0, score + compensation)
