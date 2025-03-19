import numpy as np
import librosa
import re
from sklearn.preprocessing import StandardScaler
import spacy
import torch
from transformers import BertTokenizer, BertModel
import os
import warnings

# Suppress unnecessary warnings
warnings.filterwarnings("ignore", category=UserWarning)

# Load NLP models
nlp = spacy.load("en_core_web_sm")

# Load BERT model for key phrase identification
BERT_MODEL_NAME = "bert-base-uncased"
tokenizer = None
model = None

def load_bert_model():
    """Lazily load BERT model when needed"""
    global tokenizer, model
    if tokenizer is None:
        try:
            tokenizer = BertTokenizer.from_pretrained(BERT_MODEL_NAME)
            model = BertModel.from_pretrained(BERT_MODEL_NAME)
            return True
        except Exception as e:
            print(f"Error loading BERT model: {e}")
            return False
    return True

def detect_emphasized_segments(audio, sample_rate, transcript_with_timestamps=None):
    """
    Detect emphasized segments in audio based on audio features

    Returns: List of time segments with emphasis markers
    """
    # Extract audio features for emphasis detection
    hop_length = 512
    frame_length = 2048

    # 1. Extract volume (energy) - sudden increases often indicate emphasis
    rms = librosa.feature.rms(y=audio, frame_length=frame_length, hop_length=hop_length)[0]
    rms_scaled = StandardScaler().fit_transform(rms.reshape(-1, 1)).flatten()

    # 2. Extract pitch and pitch variations
    pitches, magnitudes = librosa.piptrack(y=audio, sr=sample_rate,
                                           fmin=75, fmax=400,
                                           n_fft=frame_length, hop_length=hop_length)

    pitch_values = []
    for t in range(pitches.shape[1]):
        index = magnitudes[:, t].argmax()
        pitch = pitches[index, t]
        pitch_values.append(pitch if pitch > 0 else 0)

    # Calculate pitch delta (changes in pitch often indicate emphasis)
    pitch_delta = np.abs(np.diff(np.array(pitch_values), prepend=pitch_values[0]))
    pitch_delta_scaled = StandardScaler().fit_transform(pitch_delta.reshape(-1, 1)).flatten()

    # 3. Extract spectral contrast (variations in harmonic structure)
    contrast = librosa.feature.spectral_contrast(y=audio, sr=sample_rate,
                                                 n_fft=frame_length, hop_length=hop_length)
    contrast_mean = np.mean(contrast, axis=0)
    contrast_scaled = StandardScaler().fit_transform(contrast_mean.reshape(-1, 1)).flatten()

    # 4. Detect pauses from transcript if available
    pause_indicators = np.zeros_like(rms)
    if transcript_with_timestamps:
        # Extract pause information from transcript
        pause_pattern = r'\[(\d+\.\d+) second pause\]'
        pause_matches = re.finditer(pause_pattern, transcript_with_timestamps)

        for match in pause_matches:
            pause_duration = float(match.group(1))
            start_idx = transcript_with_timestamps.find(match.group(0))

            # Find nearby frames - simplified approximation
            frame_index = int(start_idx / len(transcript_with_timestamps) * len(pause_indicators))
            if 0 <= frame_index < len(pause_indicators):
                pause_indicators[frame_index] = 1.0

    # Combine features into an emphasis score
    # Weight: 40% volume, 30% pitch change, 20% spectral contrast, 10% pauses
    emphasis_score = (0.4 * rms_scaled +
                      0.3 * pitch_delta_scaled +
                      0.2 * contrast_scaled +
                      0.1 * pause_indicators)

    # Normalize to 0-1 range
    emphasis_score = (emphasis_score - np.min(emphasis_score)) / (np.max(emphasis_score) - np.min(emphasis_score))

    # Identify emphasized segments (where score exceeds threshold)
    emphasis_threshold = 0.7  # Calibrated threshold
    emphasized_frames = np.where(emphasis_score > emphasis_threshold)[0]

    # Convert frames to time segments
    emphasized_segments = []
    if len(emphasized_frames) > 0:
        # Group adjacent frames
        current_segment = [emphasized_frames[0]]

        for i in range(1, len(emphasized_frames)):
            if emphasized_frames[i] - emphasized_frames[i-1] <= 3:  # Within 3 frames
                current_segment.append(emphasized_frames[i])
            else:
                # End current segment and start a new one
                start_time = librosa.frames_to_time(min(current_segment), sr=sample_rate, hop_length=hop_length)
                end_time = librosa.frames_to_time(max(current_segment), sr=sample_rate, hop_length=hop_length)
                emphasized_segments.append((start_time, end_time))
                current_segment = [emphasized_frames[i]]

        # Add final segment
        start_time = librosa.frames_to_time(min(current_segment), sr=sample_rate, hop_length=hop_length)
        end_time = librosa.frames_to_time(max(current_segment), sr=sample_rate, hop_length=hop_length)
        emphasized_segments.append((start_time, end_time))

    return emphasized_segments

def identify_key_phrases(text):
    """
    Identify phrases in text that should be emphasized
    Uses NLP techniques to find important concepts and transition phrases

    Returns: List of phrases that should be emphasized
    """
    if not text:
        return []

    key_phrases = []
    doc = nlp(text)

    # 1. Important nouns and noun phrases
    for chunk in doc.noun_chunks:
        # Only consider substantial noun phrases
        if len(chunk) >= 2 and not all(token.is_stop for token in chunk):
            key_phrases.append(chunk.text)

    # 2. Named entities (people, organizations, etc.)
    for ent in doc.ents:
        key_phrases.append(ent.text)

    # 3. Transition and emphasis phrases
    emphasis_indicators = [
        "important", "critical", "essential", "crucial", "significant",
        "key", "primary", "fundamental", "vital", "central",
        "remember", "note that", "consider", "focus on", "emphasize"
    ]

    for token in doc:
        if token.text.lower() in emphasis_indicators and token.head.text:
            # Get the context around emphasis words
            start = max(0, token.i - 2)
            end = min(len(doc), token.i + 5)
            key_phrases.append(doc[start:end].text)

    # 4. Use BERT for keyword extraction if available
    if load_bert_model():
        try:
            # Process text with BERT
            inputs = tokenizer(text, return_tensors="pt", truncation=True, max_length=512)
            with torch.no_grad():
                outputs = model(**inputs)

            # Extract token embeddings
            token_embeddings = outputs.last_hidden_state

            # Analyze token importance
            sentence_embedding = torch.mean(token_embeddings[0], dim=0)
            token_importance = torch.cosine_similarity(token_embeddings[0], sentence_embedding.unsqueeze(0))

            # Find important tokens and their contexts
            important_token_indices = torch.where(token_importance > 0.85)[0].tolist()
            tokens = tokenizer.convert_ids_to_tokens(inputs.input_ids[0])

            # Extract contexts around important tokens
            for idx in important_token_indices:
                if idx < len(tokens) - 1 and not tokens[idx].startswith('##'):
                    # Get surrounding context
                    start_idx = max(0, idx - 2)
                    end_idx = min(len(tokens), idx + 3)

                    # Reconstruct phrase from tokens
                    phrase = tokenizer.convert_tokens_to_string(tokens[start_idx:end_idx])
                    if len(phrase) > 3 and phrase not in key_phrases:
                        key_phrases.append(phrase)

        except Exception as e:
            print(f"BERT keyword extraction failed: {e}")

    # Remove duplicates and normalize
    key_phrases = list(set(key_phrase.strip().lower() for key_phrase in key_phrases))

    # Filter out very common words and short phrases
    key_phrases = [phrase for phrase in key_phrases if len(phrase) > 2 and phrase not in ["the", "is", "are", "was", "were"]]

    return key_phrases

def map_emphasis_to_transcript(emphasized_segments, result, text):
    """
    Map emphasized audio segments to words in transcript

    Args:
        emphasized_segments: List of time tuples (start, end)
        result: Whisper transcription result with word timestamps
        text: Full transcript text

    Returns: Dictionary mapping emphasized words to their positions
    """
    emphasized_words = []

    try:
        if not emphasized_segments or not result or 'segments' not in result:
            return emphasized_words

        # Extract words with timestamps from Whisper result
        all_words = []
        for segment in result['segments']:
            if 'words' in segment:
                for word_info in segment['words']:
                    all_words.append({
                        'word': word_info['word'],
                        'start': word_info['start'],
                        'end': word_info['end']
                    })

        # Find words that overlap with emphasized segments
        for start_time, end_time in emphasized_segments:
            segment_words = []
            for word_info in all_words:
                word_start = word_info['start']
                word_end = word_info['end']

                # Check for overlap
                if (word_start <= end_time and word_end >= start_time):
                    segment_words.append(word_info['word'])

            if segment_words:
                emphasized_phrase = ' '.join(segment_words).strip()
                if emphasized_phrase and len(emphasized_phrase) > 1:
                    emphasized_words.append(emphasized_phrase)

    except Exception as e:
        print(f"Error mapping emphasis to transcript: {e}")

    return emphasized_words

def analyze_emphasis(audio_path, transcription_result, transcript_text):
    """
    Analyze emphasis quality in speech

    Args:
        audio_path: Path to audio file
        transcription_result: Whisper result with timestamps
        transcript_text: Text transcript with pause markers

    Returns: Dictionary with emphasis analysis results
    """
    try:
        # Load audio
        audio, sample_rate = librosa.load(audio_path, sr=None)

        # Detect emphasized segments in audio
        emphasized_segments = detect_emphasized_segments(audio, sample_rate, transcript_text)

        # Map emphasized segments to words
        emphasized_words = map_emphasis_to_transcript(emphasized_segments, transcription_result, transcript_text)

        # Identify key phrases that should be emphasized
        key_phrases = identify_key_phrases(transcript_text)

        # Calculate how many key phrases were actually emphasized
        emphasized_key_phrases = []
        for key_phrase in key_phrases:
            for emph_word in emphasized_words:
                if key_phrase in emph_word.lower() or emph_word.lower() in key_phrase:
                    emphasized_key_phrases.append(key_phrase)
                    break

        # Calculate emphasis metrics
        total_emphasized_segments = len(emphasized_segments)
        emphasis_density = total_emphasized_segments / (len(audio) / sample_rate / 60) if len(audio) > 0 else 0
        emphasis_coverage = len(emphasized_key_phrases) / len(key_phrases) if len(key_phrases) > 0 else 0

        # Calculate emphasis score
        emphasis_score = min(100, max(0, int(
            40 * min(1.0, emphasis_coverage) +  # 40% for covering key phrases
            30 * min(1.0, emphasis_density / 5) +  # 30% for appropriate emphasis density
            30 * min(1.0, total_emphasized_segments / max(1, len(key_phrases)))  # 30% for number of emphases
        )))

        # Generate feedback based on score
        feedback = []
        if emphasis_score >= 80:
            feedback.append("Excellent use of vocal emphasis to highlight key points.")
        elif emphasis_score >= 60:
            feedback.append("Good emphasis patterns but could be more consistent on key points.")
        elif emphasis_score >= 40:
            feedback.append("Some points emphasized effectively, but important concepts need clearer emphasis.")
        else:
            feedback.append("Limited vocal emphasis detected. Work on highlighting key points through voice modulation.")

        # Add specific feedback
        if emphasis_coverage < 0.3:
            feedback.append("Many important concepts weren't emphasized. Practice identifying and highlighting key points.")

        if emphasis_density < 2:
            feedback.append("Add more emphasis to engage listeners and highlight important information.")
        elif emphasis_density > 10:
            feedback.append("Too many emphasized segments may dilute their impact. Focus on emphasizing only the most important points.")

        # Missed key phrases feedback
        missed_phrases = [phrase for phrase in key_phrases if phrase not in emphasized_key_phrases]
        if missed_phrases and len(missed_phrases) <= 5:
            feedback.append(f"Consider emphasizing these key concepts: {', '.join(missed_phrases[:3])}...")

        # Success feedback
        if emphasized_key_phrases and emphasis_score >= 60:
            feedback.append(f"Effectively emphasized {len(emphasized_key_phrases)} key points in your speech.")

        return {
            'emphasis_score': emphasis_score,
            'total_emphasized_segments': total_emphasized_segments,
            'emphasis_density_per_minute': round(emphasis_density, 2),
            'emphasis_coverage': round(emphasis_coverage * 100),
            'key_phrases': key_phrases,
            'emphasized_words': emphasized_words,
            'feedback': feedback
        }

    except Exception as e:
        print(f"Error in emphasis analysis: {e}")
        import traceback
        traceback.print_exc()
        return {
            'emphasis_score': 50,
            'feedback': ["Unable to fully analyze emphasis. Focus on varying your tone to highlight key points."]
        }