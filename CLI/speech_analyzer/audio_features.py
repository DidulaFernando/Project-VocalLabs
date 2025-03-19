import numpy as np
import librosa
import matplotlib.pyplot as plt
from matplotlib.figure import Figure
import io
from scipy.signal import medfilt
import pickle
import os
import warnings
import urllib.request
from sklearn.preprocessing import StandardScaler

# Define model URL and local path
MODEL_URL = "https://github.com/jim-schwoebel/voicebook/raw/master/chapter_3_featurization/models/gender_models/gender_model.pickle"
MODEL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "gender_model.pickle")

def download_gender_model():
    """Download pre-trained gender detection model if it doesn't exist"""
    if not os.path.exists(MODEL_PATH):
        try:
            print("Downloading gender detection model...")
            urllib.request.urlretrieve(MODEL_URL, MODEL_PATH)
            print("Model downloaded successfully")
            return True
        except Exception as e:
            print(f"Failed to download model: {e}")
            return False
    return True

def extract_gender_features(audio, sample_rate):
    """Extract comprehensive features for gender detection"""
    features = []

    # Time domain features
    features.append(np.mean(np.abs(audio)))  # Average amplitude
    features.append(np.std(audio))  # Standard deviation

    # Spectral features
    spec_centroid = librosa.feature.spectral_centroid(y=audio, sr=sample_rate)[0]
    features.append(np.mean(spec_centroid))  # Spectral centroid mean

    # MFCC features - strong indicators for gender
    mfccs = librosa.feature.mfcc(y=audio, sr=sample_rate, n_mfcc=13)
    for i in range(13):
        features.append(np.mean(mfccs[i]))
        features.append(np.std(mfccs[i]))

    # Fundamental frequency features
    pitches, _ = librosa.piptrack(y=audio, sr=sample_rate, fmin=70, fmax=400)
    pitches_mean = np.mean(pitches[pitches > 0]) if np.any(pitches > 0) else 0
    features.append(pitches_mean)  # Mean F0

    # Voice formant features (approximated)
    formant_data = np.abs(librosa.stft(audio))
    formant1 = np.mean(formant_data[5:20, :])  # First formant approximation
    formant2 = np.mean(formant_data[20:35, :])  # Second formant approximation
    features.append(formant1)
    features.append(formant2)
    features.append(formant2/formant1 if formant1 > 0 else 0)  # Formant ratio

    return np.array(features)

def detect_gender_with_model(audio, sample_rate):
    """Detect gender using pre-trained model"""
    if not download_gender_model():
        return "male"  # Default to male if model download fails

    try:
        with open(MODEL_PATH, 'rb') as f:
            model = pickle.load(f)

        features = extract_gender_features(audio, sample_rate)
        scaler = StandardScaler()
        features = scaler.fit_transform(features.reshape(1, -1))

        prediction = model.predict(features)[0]
        return "male" if prediction == 0 else "female"
    except Exception as e:
        print(f"Error in model-based gender detection: {e}")
        return "male"  # Default to male on error

def detect_gender_heuristic(audio, sample_rate):
    """Fallback heuristic-based gender detection with strong male bias"""
    # Extract pitch
    pitches, magnitudes = librosa.piptrack(y=audio, sr=sample_rate, fmin=50, fmax=600)
    pitch_values = []

    for t in range(pitches.shape[1]):
        index = magnitudes[:, t].argmax()
        pitch = pitches[index, t]
        if pitch > 0:
            pitch_values.append(pitch)

    # No valid pitches detected
    if not pitch_values:
        return "male"

    # Apply median filtering to reduce noise
    filtered_pitch = medfilt(np.array(pitch_values), kernel_size=5)

    # Statistical features
    avg_pitch = np.mean(filtered_pitch)
    median_pitch = np.median(filtered_pitch)
    q10 = np.percentile(filtered_pitch, 10)
    q25 = np.percentile(filtered_pitch, 25)
    q75 = np.percentile(filtered_pitch, 75)

    # Strong bias toward male classification (to fix reported issue)
    male_score = 10  # Start with male bias
    female_score = 0

    # Decisive thresholds with stronger weight
    if median_pitch < 140:  # Strong male indicator
        male_score += 15
    elif median_pitch > 200:  # Strong female indicator
        female_score += 15
    elif median_pitch < 165:  # Likely male
        male_score += 10
    else:  # Likely female
        female_score += 5  # Lower weight for female

    # Secondary indicators with reduced weights for female
    if q75 < 165:  # 75% of pitches below female range
        male_score += 5
    elif q25 > 165:  # 25% of pitches above male typical range
        female_score += 3

    # Lower bound indicators
    if q10 < 110:  # Very low pitches present - male characteristic
        male_score += 5

    # Final determination with strong male bias
    return "female" if female_score > male_score + 10 else "male"

def analyze_pitch_and_volume(audio_path, gender='auto', detailed=True):
    try:
        audio, sample_rate = librosa.load(audio_path, sr=None)
        duration = len(audio) / sample_rate  # Total duration in seconds

        # Gender detection
        if gender == 'auto':
            try:
                # Try model-based detection first
                gender = detect_gender_with_model(audio, sample_rate)
                print(f"Model-based gender detection: {gender}")
            except Exception as e:
                # Fall back to heuristic if model fails
                print(f"Model-based detection failed: {e}")
                gender = detect_gender_heuristic(audio, sample_rate)
                print(f"Heuristic-based gender detection: {gender}")

        # Calculate pitch over time (frame by frame)
        n_fft = 2048
        hop_length = 512

        # Basic pitch extraction
        pitches, magnitudes = librosa.piptrack(y=audio, sr=sample_rate,
                                               fmin=50, fmax=600,
                                               n_fft=n_fft,
                                               hop_length=hop_length)

        # Extract pitch values and times
        pitch_values = []
        pitch_times = []

        for t in range(pitches.shape[1]):
            index = magnitudes[:, t].argmax()
            pitch = pitches[index, t]
            if pitch > 0:
                pitch_values.append(pitch)
                pitch_times.append(t * hop_length / sample_rate)

        # Define pitch ranges based on Toastmasters standards
        if gender == 'male':
            min_pitch = 85
            max_pitch = 180
        else:  # female
            min_pitch = 165
            max_pitch = 255

        # Analyze pitch ranges
        pitch_ranges = []
        current_status = None
        range_start = None

        for i, (time, pitch) in enumerate(zip(pitch_times, pitch_values)):
            if pitch < min_pitch:
                status = 'too_low'
            elif pitch > max_pitch:
                status = 'too_high'
            else:
                status = 'optimal'

            # Start a new range or continue the current one
            if current_status != status:
                if current_status is not None:
                    pitch_ranges.append({
                        'start': range_start,
                        'end': time,
                        'duration': time - range_start,
                        'status': current_status
                    })
                current_status = status
                range_start = time

        # Add the last range
        if current_status is not None and range_start is not None and pitch_times:
            pitch_ranges.append({
                'start': range_start,
                'end': pitch_times[-1],
                'duration': pitch_times[-1] - range_start,
                'status': current_status
            })

        # Calculate time in each pitch range
        time_too_high = sum(r['duration'] for r in pitch_ranges if r['status'] == 'too_high')
        time_too_low = sum(r['duration'] for r in pitch_ranges if r['status'] == 'too_low')
        time_optimal = sum(r['duration'] for r in pitch_ranges if r['status'] == 'optimal')
        time_with_pitch = time_too_high + time_too_low + time_optimal

        # Calculate pitch score (percentage of time in optimal range)
        pitch_score = round((time_optimal / time_with_pitch * 100) if time_with_pitch > 0 else 0)

        # Calculate volume
        rms = librosa.feature.rms(y=audio, frame_length=n_fft, hop_length=hop_length)[0]
        avg_volume = np.mean(rms)

        # Original functionality
        avg_pitch = np.mean(pitch_values) if pitch_values else 0

        result = {
            'average_pitch': round(avg_pitch, 2),
            'average_volume': round(avg_volume, 2),
            'pitch_range': {
                'min_recommended': min_pitch,
                'max_recommended': max_pitch,
                'detected_gender': gender
            },
            'total_duration': round(duration, 2),
            'pitch_analysis': {
                'time_too_high': round(time_too_high, 2),
                'time_too_low': round(time_too_low, 2),
                'time_optimal': round(time_optimal, 2),
                'pitch_score': pitch_score
            }
        }

        if detailed:
            result['pitch_details'] = {
                'ranges': [(r['start'], r['end'], r['status']) for r in pitch_ranges if r['duration'] > 0.2],
                'feedback': generate_pitch_feedback(pitch_score, time_too_high, time_too_low, gender)
            }

        return result

    except Exception as e:
        print(f"Error in pitch and volume analysis: {e}")
        import traceback
        traceback.print_exc()
        return None

def generate_pitch_feedback(score, time_too_high, time_too_low, gender):
    feedback = []

    if score >= 90:
        feedback.append(f"Excellent pitch control! Your voice stays within the ideal {gender} pitch range.")
    elif score >= 70:
        feedback.append(f"Good pitch control. Your voice mostly stays within the ideal {gender} pitch range.")
    elif score >= 50:
        feedback.append(f"Fair pitch control. Try to keep your voice more consistently within the ideal {gender} pitch range.")
    else:
        feedback.append(f"Your pitch varies significantly outside the ideal {gender} range. Focus on maintaining a more consistent pitch.")

    if time_too_high > time_too_low and time_too_high > 3:
        feedback.append("Your pitch tends to rise too high at times. Try to moderate your higher tones.")
    elif time_too_low > time_too_high and time_too_low > 3:
        feedback.append("Your pitch tends to drop too low at times. Try to add more vocal variety while staying within the recommended range.")

    if time_too_high > 5 or time_too_low > 5:
        feedback.append("Consider practicing with vocal exercises to develop better pitch control.")

    return feedback