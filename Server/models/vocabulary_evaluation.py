import re
import nltk
from nltk.tokenize import word_tokenize
from nltk.corpus import wordnet, brown, webtext, gutenberg, cmudict
from collections import Counter, defaultdict
import numpy as np
import statistics
import os
import pickle
import json
from datetime import datetime
import librosa
import soundfile as sf
from scipy.spatial.distance import cosine, euclidean
from scipy import stats
import pandas as pd

# Download necessary NLTK data
def download_nltk_data():
    required_data = [
        ('tokenizers/punkt', 'punkt'),
        ('taggers/averaged_perceptron_tagger', 'averaged_perceptron_tagger'),
        ('corpora/wordnet', 'wordnet'),
        ('corpora/brown', 'brown'),
        ('corpora/webtext', 'webtext'),
        ('corpora/gutenberg', 'gutenberg'),
        ('corpora/cmudict', 'cmudict')
    ]
    
    for path, package in required_data:
        try:
            nltk.data.find(path)
        except LookupError:
            print(f"Downloading {package}...")
            nltk.download(package)

# ---------- Word Frequency Analysis ----------

def get_word_frequency_data(force_rebuild=False):
    """
    Creates or loads word frequency data from multiple corpora.
    
    Args:
        force_rebuild (bool): Whether to force rebuilding the frequency data
        
    Returns:
        Dict: Word frequency percentiles and related data
    """
    cache_path = 'word_frequency_cache_v2.pkl'
    
    # Check if the cached data exists and is not being forced to rebuild
    if os.path.exists(cache_path) and not force_rebuild:
        with open(cache_path, 'rb') as f:
            data = pickle.load(f)
            # Check if the cached data has the correct structure
            if isinstance(data, dict) and 'metadata' in data and 'word_percentiles' in data:
                print(f"Using cached word frequency data (created: {data['metadata']['created']})")
                return data['word_percentiles']
    
    # Otherwise, build the frequency data from multiple corpora
    print("Building comprehensive word frequency data from multiple corpora... (this may take a moment)")
    download_nltk_data()
    
    # Collection of words from various corpora
    corpus_collections = {
        'brown': [word.lower() for word in brown.words()],
        'webtext': [word.lower() for word in webtext.words()],
        'gutenberg': [word.lower() for word in gutenberg.words()]
    }
    
    # Create a combined frequency dictionary with source tracking
    combined_freq = defaultdict(lambda: {'count': 0, 'sources': {}})
    
    # Process each corpus
    for corpus_name, words in corpus_collections.items():
        corpus_freq = Counter(words)
        corpus_total = sum(corpus_freq.values())
        
        for word, count in corpus_freq.items():
            # Skip non-alphabetic words and very short words (likely not real words)
            if not word.isalpha() or len(word) < 2:
                continue
                
            combined_freq[word]['count'] += count
            combined_freq[word]['sources'][corpus_name] = count / corpus_total
    
    # Calculate overall frequency percentiles
    total_words = sum(item['count'] for item in combined_freq.values())
    word_items = [(word, data['count']) for word, data in combined_freq.items()]
    sorted_words = sorted(word_items, key=lambda x: x[1], reverse=True)
    
    word_percentiles = {}
    corpus_coverage = {corpus: set() for corpus in corpus_collections.keys()}
    
    for rank, (word, _) in enumerate(sorted_words, 1):
        # Calculate percentile (higher percentile = more common)
        percentile = 100 - (rank / len(sorted_words) * 100)
        word_percentiles[word] = {
            'percentile': percentile,
            'sources': combined_freq[word]['sources'],
            'count': combined_freq[word]['count']
        }
        
        # Track which corpora contain this word
        for corpus in combined_freq[word]['sources']:
            corpus_coverage[corpus].add(word)
    
    # Calculate corpus diversity statistics
    corpus_stats = {
        corpus: {
            'unique_words': len(words),
            'words_in_percentiles': {
                'common (75-100)': len([w for w in word_percentiles if w in corpus_coverage[corpus] and word_percentiles[w]['percentile'] >= 75]),
                'moderate (25-75)': len([w for w in word_percentiles if w in corpus_coverage[corpus] and 25 <= word_percentiles[w]['percentile'] < 75]),
                'rare (0-25)': len([w for w in word_percentiles if w in corpus_coverage[corpus] and word_percentiles[w]['percentile'] < 25])
            }
        }
        for corpus, words in corpus_coverage.items()
    }
    
    # Create metadata for the cache
    metadata = {
        'created': datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        'corpora_used': list(corpus_collections.keys()),
        'total_unique_words': len(word_percentiles),
        'corpus_stats': corpus_stats
    }
    
    # Save data with cache version and metadata
    cache_data = {
        'metadata': metadata,
        'word_percentiles': word_percentiles
    }
    
    with open(cache_path, 'wb') as f:
        pickle.dump(cache_data, f)
    
    # Also save a human-readable summary
    with open('word_frequency_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=2)
        
    print(f"Built frequency data with {len(word_percentiles)} unique words across {len(corpus_collections)} corpora")
    
    return word_percentiles

def analyze_word_complexity(word, word_percentiles, config=None):
    """
    Determine the complexity level of a given word using corpus data.
    Returns a score from 1 (basic) to 3 (advanced).
    
    Args:
        word: The word to analyze
        word_percentiles: Dictionary of word frequency data
        config: Optional configuration parameters to adjust scoring
    """
    # Default configuration
    if config is None:
        config = {
            'frequency_weight': 0.5,
            'length_weight': 0.2,
            'semantic_weight': 0.3,
            'domain_adjustment': None
        }
    
    word = word.lower()
    
    # Skip non-alphabetic words
    if not word.isalpha():
        return 1.5  # Default middle score for non-alphabetic items
    
    # Get word frequency data (if available)
    word_data = word_percentiles.get(word, None)
    
    # Calculate frequency score
    if word_data is None:
        # Word not found in any corpus - could be very rare, specialized, or a mistake
        frequency_score = 3  # Initially assume it's advanced (rare)
    else:
        percentile = word_data['percentile']
        
        # Score based on percentile
        if percentile >= 75:
            frequency_score = 1  # Common (basic)
        elif percentile >= 50:
            frequency_score = 1.5  # Moderately common
        elif percentile >= 25:
            frequency_score = 2  # Moderately rare
        else:
            frequency_score = 3  # Rare (advanced)
            
        # Adjust score based on corpus diversity
        # If a word appears in multiple corpora, it's more likely to be general vocabulary
        source_count = len(word_data['sources'])
        if source_count > 2:
            frequency_score = max(1, frequency_score - 0.5)
    
    # Length factor - longer words tend to be more complex
    length_score = min(3, max(1, len(word) / 3.5))
    
    # Semantic complexity using WordNet
    semantic_score = 1.5  # Default middle score
    
    synsets = wordnet.synsets(word)
    if synsets:
        # Analyze:
        # 1. Number of meanings (more meanings = more complex)
        # 2. Definition complexity
        # 3. Hierarchical depth in WordNet (deeper = more specialized)
        
        meanings_count = len(synsets)
        
        # Average definition length
        definitions = [s.definition() for s in synsets]
        avg_def_length = sum(len(d.split()) for d in definitions) / len(definitions)
        
        # Get hypernym path lengths (measure of specificity)
        hypernym_paths = [len(ss.hypernym_paths()) for ss in synsets if ss.hypernym_paths()]
        avg_hypernym_length = sum(hypernym_paths) / len(hypernym_paths) if hypernym_paths else 1
        
        # Calculate semantic score components
        meaning_factor = min(3, meanings_count / 2)  # Words with many meanings are often foundational
        definition_factor = min(3, avg_def_length / 8)  # Complex definitions suggest complex concepts
        specificity_factor = min(3, avg_hypernym_length / 4)  # Deep in hierarchy = specific/technical
        
        # Balance these factors - words with MANY meanings are often simpler foundational words
        if meanings_count > 10:
            semantic_score = (specificity_factor * 0.7) + (definition_factor * 0.3)
        else:
            semantic_score = (meaning_factor * 0.3) + (definition_factor * 0.4) + (specificity_factor * 0.3)
    
    # Domain-specific adjustment (if configured)
    domain_adjustment = 0
    if config['domain_adjustment'] and word in config['domain_adjustment']:
        domain_adjustment = config['domain_adjustment'][word]
    
    # Combine all factors with their weights
    final_score = (
        (frequency_score * config['frequency_weight']) + 
        (length_score * config['length_weight']) + 
        (semantic_score * config['semantic_weight']) + 
        domain_adjustment
    )
    
    # Ensure the score stays within bounds
    return min(3, max(1, final_score))

def analyze_grammar_and_word_selection(transcription, word_percentiles, domain_config=None):
    """
    Analyze the grammar and word selection in the transcription with fairness considerations.
    
    Parameters:
    transcription (str): The transcribed speech text
    word_percentiles (dict): Dictionary of word frequency percentiles
    domain_config (dict): Optional configuration for domain-specific scoring
    
    Returns:
    dict: Analysis of grammar and word selection
    """
    # Set default domain configuration if none provided
    if domain_config is None:
        domain_config = {
            'domain_name': 'general',
            'complexity_weights': {
                'frequency_weight': 0.5,
                'length_weight': 0.2,
                'semantic_weight': 0.3
            },
            'domain_terms': {}  # No domain-specific terms adjustment
        }
    
    # Clean text and tokenize
    cleaned_text = re.sub(r'\[[\d.]+ second pause\]', '', transcription)  # Remove pause markers
    cleaned_text = re.sub(r'[^\w\s.,!?]', '', cleaned_text)  # Remove special characters
    
    # Split into sentences for better analysis
    sentences = re.split(r'[.!?]+', cleaned_text)
    sentences = [s.strip() for s in sentences if s.strip()]
    
    words = word_tokenize(cleaned_text)
    words = [word for word in words if word.isalpha()]  # Keep only alphabetic words
    
    if not words:
        return {
            "word_count": 0,
            "unique_word_count": 0,
            "avg_word_length": 0,
            "word_complexity_score": 0,
            "sentence_complexity": 0,
            "grammar_score": 70.0,
            "domain_appropriateness": 0
        }
    
    # Basic text statistics
    word_count = len(words)
    unique_words = len(set(words))
    avg_word_length = sum(len(word) for word in words) / word_count
    
    # Configure word complexity analysis
    complexity_config = {
        'frequency_weight': domain_config['complexity_weights']['frequency_weight'],
        'length_weight': domain_config['complexity_weights']['length_weight'],
        'semantic_weight': domain_config['complexity_weights']['semantic_weight'],
        'domain_adjustment': domain_config['domain_terms'] if 'domain_terms' in domain_config else None
    }
    
    # Word complexity analysis
    complexity_scores = [
        analyze_word_complexity(word, word_percentiles, complexity_config) 
        for word in words
    ]
    avg_complexity = sum(complexity_scores) / len(complexity_scores)
    
    # Count advanced words (score >= 2.5)
    advanced_word_count = sum(1 for score in complexity_scores if score >= 2.5)
    advanced_word_percentage = (advanced_word_count / word_count) * 100
    
    # Domain-specific vocabulary analysis
    if 'domain_terms' in domain_config and domain_config['domain_terms']:
        domain_terms = set(term.lower() for term in domain_config['domain_terms'].keys())
        domain_terms_used = sum(1 for word in words if word.lower() in domain_terms)
        domain_terms_percentage = (domain_terms_used / word_count) * 100
    else:
        domain_terms_percentage = 0
    
    # Sentence structure analysis
    try:
        tagged_words = nltk.pos_tag(words)
        
        # Analyze overall part-of-speech distribution
        pos_counts = Counter(tag for _, tag in tagged_words)
        
        # Calculate distribution of parts of speech
        verb_count = sum(1 for _, tag in tagged_words if tag.startswith('VB'))
        noun_count = sum(1 for _, tag in tagged_words if tag.startswith('NN'))
        adj_count = sum(1 for _, tag in tagged_words if tag.startswith('JJ'))
        adv_count = sum(1 for _, tag in tagged_words if tag.startswith('RB'))
        
        # Grammatical complexity indicators
        verb_variety = verb_count / word_count
        modifier_ratio = (adj_count + adv_count) / word_count
        
        # Analyze sentence structure complexity
        avg_sentence_length = word_count / len(sentences) if sentences else 0
        
        # Detect complex syntactic structures (e.g., subordinate clauses)
        complex_structures_count = 0
        for sentence in sentences:
            sentence_words = word_tokenize(sentence)
            # Simple heuristic: check for subordinating conjunctions or relative pronouns
            # This is a simplified approach - a full parser would be more accurate
            if any(word.lower() in {'because', 'although', 'since', 'while', 'whereas', 'if', 'unless', 'until', 'when', 'where', 'who', 'which', 'that'} for word in sentence_words):
                complex_structures_count += 1
        
        complex_sentence_ratio = complex_structures_count / len(sentences) if sentences else 0
        
        # Sentence complexity score (0-10)
        sentence_complexity = min(10, (verb_variety * 3) + (modifier_ratio * 3) + (min(1, avg_sentence_length/20) * 2) + (complex_sentence_ratio * 2))
        
    except Exception as e:
        print(f"Error in linguistic analysis: {e}")
        sentence_complexity = 5  # Default value
    
    # Calculate Grammar and Word Selection Score (0-100)
    # 40% word complexity, 30% sentence complexity, 30% lexical diversity
    lexical_diversity = unique_words / word_count
    lexical_diversity_score = min(10, lexical_diversity * 20)  # Scale to 0-10
    
    word_complexity_score = min(10, avg_complexity * 3)  # Scale complexity to 0-10
    
    # Base grammar score calculation
    grammar_score = (word_complexity_score * 4) + (sentence_complexity * 3) + (lexical_diversity_score * 3)
    
    # Adjust for domain appropriateness if applicable
    domain_appropriateness = 0
    if domain_terms_percentage > 0:
        domain_appropriateness = min(10, domain_terms_percentage / 2)
        grammar_score = (grammar_score * 0.9) + (domain_appropriateness * 1)
    
    # Normalize to 0-100 scale
    grammar_score = max(50, min(95, grammar_score))
    
    # Detailed word complexity breakdown
    complexity_distribution = {
        'basic': sum(1 for score in complexity_scores if score < 1.5) / word_count,
        'intermediate': sum(1 for score in complexity_scores if 1.5 <= score < 2.5) / word_count,
        'advanced': sum(1 for score in complexity_scores if score >= 2.5) / word_count
    }
    
    return {
        "word_count": word_count,
        "unique_word_count": unique_words,
        "lexical_diversity": round(lexical_diversity, 2),
        "avg_word_length": round(avg_word_length, 1),
        "word_complexity_score": round(word_complexity_score, 1),
        "word_complexity_distribution": {k: round(v*100, 1) for k, v in complexity_distribution.items()},
        "advanced_word_percentage": round(advanced_word_percentage, 1),
        "sentence_complexity": round(sentence_complexity, 1),
        "domain_appropriateness": round(domain_appropriateness, 1) if domain_appropriateness > 0 else None,
        "domain_terms_percentage": round(domain_terms_percentage, 1) if domain_terms_percentage > 0 else None,
        "grammar_score": round(grammar_score, 1)
    }

# ---------- ADVANCED PRONUNCIATION ANALYSIS ENGINE ----------

class PronunciationAnalyzer:
    """Enhanced pronunciation analysis engine for competition-grade evaluation."""
    
    def __init__(self, reference_model_path=None, config=None):
        """
        Initialize the pronunciation analyzer.
        
        Args:
            reference_model_path: Path to reference pronunciation models (optional)
            config: Configuration dictionary for analysis parameters
        """
        # Ensure NLTK data is downloaded
        download_nltk_data()
        
        # Default configuration
        self.config = {
            'scoring_weights': {
                'phoneme_accuracy': 0.35,
                'prosody': 0.25,
                'fluency': 0.2,
                'articulation': 0.2
            },
            'accent_adjustment': True,
            'scoring_scale': (50, 95),  # Min and max scores
            'difficulty_adjustment': True
        }
        
        # Update with user config if provided
        if config:
            self.config.update(config)
        
        # Load CMU pronunciation dictionary
        self.pronunciation_dict = cmudict.dict() if hasattr(cmudict, 'dict') else {}
        
        # Define phonetic categories for analysis
        self.phoneme_categories = {
            'vowels': ['AA', 'AE', 'AH', 'AO', 'AW', 'AY', 'EH', 'ER', 'EY', 'IH', 'IY', 'OW', 'OY', 'UH', 'UW'],
            'stops': ['B', 'D', 'G', 'K', 'P', 'T'],
            'fricatives': ['DH', 'F', 'S', 'SH', 'TH', 'V', 'Z', 'ZH'],
            'affricates': ['CH', 'JH'],
            'nasals': ['M', 'N', 'NG'],
            'liquids': ['L', 'R'],
            'glides': ['W', 'Y', 'HH']
        }
        
        # Audio processing parameters
        self.audio_params = {
            'sample_rate': 16000,
            'n_mfcc': 13,
            'n_fft': 512,
            'hop_length': 160  # 10ms at 16kHz
        }
        
        # Load reference models if available
        self.reference_models = {}
        if reference_model_path and os.path.exists(reference_model_path):
            try:
                with open(reference_model_path, 'rb') as f:
                    self.reference_models = pickle.load(f)
                print(f"Loaded reference pronunciation models from {reference_model_path}")
            except Exception as e:
                print(f"Error loading reference models: {e}")
    
    def extract_audio_features(self, audio_file):
        """
        Extract audio features from speech file for pronunciation analysis.
        
        Args:
            audio_file: Path to audio file
            
        Returns:
            Dict: Audio features including mfccs, pitch, energy, etc.
        """
        try:
            # Load audio file
            y, sr = librosa.load(audio_file, sr=self.audio_params['sample_rate'])
            
            # Normalize audio
            y = librosa.util.normalize(y)
            
            # Extract MFCCs (Mel Frequency Cepstral Coefficients)
            mfccs = librosa.feature.mfcc(
                y=y, 
                sr=sr, 
                n_mfcc=self.audio_params['n_mfcc'],
                n_fft=self.audio_params['n_fft'],
                hop_length=self.audio_params['hop_length']
            )
            
            # Extract pitch (F0) contour
            pitch, voiced_flag, voiced_probs = librosa.pyin(
                y,
                fmin=librosa.note_to_hz('C2'),
                fmax=librosa.note_to_hz('C7'),
                sr=sr
            )
            
            # Replace NaN values in pitch
            pitch = np.nan_to_num(pitch)
            
            # Calculate energy contour
            energy = np.array([
                sum(abs(y[i:i+self.audio_params['hop_length']])) 
                for i in range(0, len(y), self.audio_params['hop_length'])
            ])
            
            # Trim to same length as other features
            energy = energy[:len(pitch)]
            
            # Extract spectral contrast
            contrast = librosa.feature.spectral_contrast(
                y=y, 
                sr=sr,
                n_fft=self.audio_params['n_fft'],
                hop_length=self.audio_params['hop_length']
            )
            
            # Extract spectral centroid (brightness)
            centroid = librosa.feature.spectral_centroid(
                y=y, 
                sr=sr,
                n_fft=self.audio_params['n_fft'],
                hop_length=self.audio_params['hop_length']
            )
            
            # Extract spectral bandwidth (spread)
            bandwidth = librosa.feature.spectral_bandwidth(
                y=y, 
                sr=sr,
                n_fft=self.audio_params['n_fft'],
                hop_length=self.audio_params['hop_length']
            )
            
            # Extract zero crossing rate (noisiness/consonant info)
            zcr = librosa.feature.zero_crossing_rate(
                y, 
                frame_length=self.audio_params['n_fft'],
                hop_length=self.audio_params['hop_length']
            )
            
            # Detect onsets for speech rate and rhythm analysis
            onset_env = librosa.onset.onset_strength(
                y=y, 
                sr=sr,
                hop_length=self.audio_params['hop_length']
            )
            onsets = librosa.onset.onset_detect(
                onset_envelope=onset_env, 
                sr=sr,
                hop_length=self.audio_params['hop_length']
            )
            
            # Return all features
            return {
                'mfccs': mfccs,
                'pitch': pitch,
                'voiced_flag': voiced_flag,
                'energy': energy,
                'contrast': contrast,
                'centroid': centroid,
                'bandwidth': bandwidth,
                'zcr': zcr,
                'onset_env': onset_env,
                'onsets': onsets
            }
        
        except Exception as e:
            print(f"Error extracting audio features: {e}")
            return None
    
    def analyze_phoneme_accuracy(self, audio_features, transcript, word_alignments):
        """
        Analyze phoneme-level pronunciation accuracy.
        
        Args:
            audio_features: Extracted audio features
            transcript: Text transcription of speech
            word_alignments: Word timing information from recognition
            
        Returns:
            Dict: Phoneme accuracy metrics
        """
        # Convert transcript to expected phoneme sequence using CMU dict
        expected_phonemes = []
        phoneme_categories_found = defaultdict(int)
        total_phonemes = 0
        
        # Get transcript words
        words = [w.lower() for w in word_tokenize(transcript) if w.isalpha()]
        
        # Look up expected pronunciation for each word
        for word in words:
            if word in self.pronunciation_dict:
                # Get the first (most common) pronunciation
                phonemes = self.pronunciation_dict[word][0]
                expected_phonemes.append(phonemes)
                
                # Count phoneme categories
                for phoneme in phonemes:
                    # Strip stress markers (numbers) from phoneme
                    base_phoneme = ''.join([c for c in phoneme if not c.isdigit()])
                    total_phonemes += 1
                    
                    # Track which category this phoneme belongs to
                    for category, phoneme_list in self.phoneme_categories.items():
                        if base_phoneme in phoneme_list:
                            phoneme_categories_found[category] += 1
                            break
        
        # If we don't have word alignments or audio features, use a statistical approach
        # based on typical error patterns
        
        # Analyze MFCC patterns for phoneme categories
        if audio_features and 'mfccs' in audio_features:
            mfccs = audio_features['mfccs']
            
            # Calculate statistical measures for different phoneme categories
            vowel_frames = []
            consonant_frames = []
            
            # Use word alignments to estimate which frames correspond to which phonemes
            # (This is a simplified approach; a full ASR system would provide phoneme alignments)
            
            # For each expected phoneme category, analyze corresponding acoustic features
            category_scores = {}
            
            for category, count in phoneme_categories_found.items():
                if category == 'vowels':
                    # Vowels typically have higher energy, lower ZCR
                    if 'energy' in audio_features and 'zcr' in audio_features:
                        energy = np.mean(audio_features['energy'])
                        zcr = np.mean(audio_features['zcr'])
                        
                        # High energy and low ZCR indicate clearer vowel pronunciation
                        vowel_clarity = min(1.0, (energy * 2) / (zcr + 0.001))
                        category_scores['vowels'] = vowel_clarity * 100
                
                elif category in ['fricatives', 'affricates']:
                    # Fricatives have high ZCR and specific spectral properties
                    if 'zcr' in audio_features and 'contrast' in audio_features:
                        zcr = np.mean(audio_features['zcr'])
                        contrast = np.mean(audio_features['contrast'][3])  # Higher band contrast
                        
                        # High ZCR and contrast indicate clear fricative articulation
                        fricative_clarity = min(1.0, (zcr * 0.7 + contrast * 0.3))
                        category_scores[category] = fricative_clarity * 100
                
                elif category in ['stops']:
                    # Stops have characteristic transients
                    if 'onset_env' in audio_features:
                        onset_strength = np.std(audio_features['onset_env'])
                        category_scores[category] = min(100, onset_strength * 200)
                
                else:
                    # Default scoring for other categories
                    category_scores[category] = 80.0  # Baseline score
        
        else:
            # Fallback if we don't have audio features
            category_scores = {category: 80.0 for category in phoneme_categories_found.keys()}
        
        # Calculate overall phoneme accuracy score
        if category_scores:
            weighted_score = sum(
                score * (phoneme_categories_found[cat] / total_phonemes)
                for cat, score in category_scores.items()
            )
        else:
            weighted_score = 80.0  # Default fallback
            
        # Normalize to standard range
        phoneme_accuracy = max(60, min(95, weighted_score))
        
        # Per-category breakdown
        category_breakdown = {
            category: {
                'count': phoneme_categories_found[category],
                'score': round(score, 1)
            }
            for category, score in category_scores.items() 
            if phoneme_categories_found[category] > 0
        }
        
        return {
            'overall_score': round(phoneme_accuracy, 1),
            'categories': category_breakdown,
            'difficult_phonemes': self._identify_difficult_phonemes(category_scores)
        }
    
    def _identify_difficult_phonemes(self, category_scores):
        """Identify phoneme categories that might be challenging for the speaker."""
        difficult_categories = []
        
        for category, score in category_scores.items():
            if score < 75:
                difficult_categories.append(category)
        
        return difficult_categories
    
    def analyze_prosody(self, audio_features, transcript, word_alignments):
        """
        Analyze speech prosody (intonation, stress, rhythm).
        
        Args:
            audio_features: Extracted audio features
            transcript: Text transcription
            word_alignments: Word timing information
            
        Returns:
            Dict: Prosody metrics
        """
        # Initialize scores
        intonation_score = 80.0
        rhythm_score = 80.0
        stress_score = 80.0
        
        if not audio_features:
            return {
                'overall_score': round((intonation_score + rhythm_score + stress_score) / 3, 1),
                'intonation_score': round(intonation_score, 1),
                'rhythm_score': round(rhythm_score, 1),
                'stress_score': round(stress_score, 1),
                'speech_rate': None
            }
        
        # Analyze pitch variation for intonation
        if 'pitch' in audio_features and len(audio_features['pitch']) > 0:
            # Filter out unvoiced frames
            voiced_pitch = audio_features['pitch'][~np.isnan(audio_features['pitch'])]
            
            if len(voiced_pitch) > 0:
                # Calculate pitch statistics
                pitch_mean = np.mean(voiced_pitch)
                pitch_std = np.std(voiced_pitch)
                pitch_range = np.max(voiced_pitch) - np.min(voiced_pitch)
                
                # Normalized pitch variation (coefficient of variation)
                pitch_variation = pitch_std / pitch_mean if pitch_mean > 0 else 0
                
                # Evaluate intonation expressiveness
                # Higher variation generally indicates more expressive intonation
                # But extremely high variation might indicate erratic pitch control
                if 0.05 <= pitch_variation <= 0.25:
                    # Ideal range of variation
                    intonation_score = 85 + (pitch_variation * 40)
                elif pitch_variation < 0.05:
                    # Too monotonous
                    intonation_score = 60 + (pitch_variation * 500)
                else:
                    # Too variable
                    intonation_score = 95 - ((pitch_variation - 0.25) * 100)
                
                # Ensure score is in valid range
                intonation_score = max(60, min(95, intonation_score))
        
        # Analyze rhythm using onset patterns and word durations
        if 'onsets' in audio_features and len(audio_features['onsets']) > 1:
            # Calculate inter-onset intervals
            onset_times = librosa.frames_to_time(
                audio_features['onsets'], 
                sr=self.audio_params['sample_rate'],
                hop_length=self.audio_params['hop_length']
            )
            
            if len(onset_times) > 1:
                # Calculate intervals between onsets
                intervals = np.diff(onset_times)
                
                # Calculate rhythm metrics
                mean_interval = np.mean(intervals)
                interval_std = np.std(intervals)
                
                # Normalized rhythm variability (coefficient of variation)
                rhythm_variability = interval_std / mean_interval if mean_interval > 0 else 0
                
                # Evaluate rhythm consistency
                # Some variability is natural, but too much is less fluent
                if rhythm_variability < 0.6:
                    # Good rhythm control
                    rhythm_score = 85 - (rhythm_variability * 25)
                else:
                    # Too irregular
                    rhythm_score = 70 - ((rhythm_variability - 0.6) * 30)
                
                # Ensure score is in valid range
                rhythm_score = max(60, min(95, rhythm_score))
        
        # Analyze stress patterns using energy contour
        if 'energy' in audio_features and len(audio_features['energy']) > 0:
            # Calculate energy statistics
            energy_mean = np.mean(audio_features['energy'])
            energy_std = np.std(audio_features['energy'])
            
            # Normalized energy variation (coefficient of variation)
            energy_variation = energy_std / energy_mean if energy_mean > 0 else 0
            
            # Evaluate stress patterns
            # A good variation in energy indicates proper stress placement
            if 0.4 <= energy_variation <= 0.8:
                # Ideal range of variation for clear stress patterns
                stress_score = 80 + (energy_variation * 20)
            elif energy_variation < 0.4:
                # Too flat, not enough stress variation
                stress_score = 60 + (energy_variation * 50)
            else:
                # Too much variation, potentially erratic stress
                stress_score = 96 - ((energy_variation - 0.8) * 40)
            
            # Ensure score is in valid range
            stress_score = max(60, min(95, stress_score))
        
        # Calculate speech rate if we have word alignments
        speech_rate = None
        if word_alignments and len(word_alignments) > 1:
            # Extract word durations
            word_durations = []
            for i in range(len(word_alignments) - 1):
                if 'start' in word_alignments[i] and 'end' in word_alignments[i]:
                    duration = word_alignments[i]['end'] - word_alignments[i]['start']
                    word_durations.append(duration)
            
            if word_durations:
                # Calculate words per minute
                total_duration = sum(word_durations)
                if total_duration > 0:
                    word_count = len(word_durations)
                    speech_rate = (word_count / total_duration) * 60
        
        # Overall prosody score (weighted average of components)
        prosody_score = (intonation_score * 0.4) + (rhythm_score * 0.3) + (stress_score * 0.3)
        
        return {
            'overall_score': round(prosody_score, 1),
            'intonation_score': round(intonation_score, 1),
            'rhythm_score': round(rhythm_score, 1),
            'stress_score': round(stress_score, 1),
            'speech_rate': round(speech_rate, 1) if speech_rate else None
        }
        
    def analyze_fluency(self, audio_features, transcript, word_alignments):
        """
        Analyze speech fluency (pauses, hesitations, speech rate consistency).
        
        Args:
            audio_features: Extracted audio features
            transcript: Text transcription
            word_alignments: Word timing information
            
        Returns:
            Dict: Fluency metrics
        """
        # Default fluency scores
        pause_quality_score = 80.0
        hesitation_score = 80.0
        flow_score = 80.0
        
        if not audio_features or not word_alignments:
            return {
                'overall_score': round((pause_quality_score + hesitation_score + flow_score) / 3, 1),
                'pause_quality_score': round(pause_quality_score, 1),
                'hesitation_score': round(hesitation_score, 1),
                'flow_score': round(flow_score, 1),
                'pause_count': None,
                'avg_pause_duration': None
            }
        
        # Detect pauses from word alignments
        pauses = []
        hesitations = []
        
        if len(word_alignments) > 1:
            for i in range(len(word_alignments) - 1):
                if 'end' in word_alignments[i] and 'start' in word_alignments[i+1]:
                    gap = word_alignments[i+1]['start'] - word_alignments[i]['end']
                    
                    # Consider gaps > 0.25s as pauses
                    if gap > 0.25:
                        pauses.append(gap)
                        
                        # Classify long pauses as potential hesitations
                        if gap > 0.75:
                            hesitations.append(gap)
        
        # Analyze pause patterns
        pause_count = len(pauses)
        avg_pause_duration = np.mean(pauses) if pauses else 0
        
        # Analyze pause quality
        if pauses:
            # Calculate normalized pause metrics
            total_speech_length = word_alignments[-1]['end'] - word_alignments[0]['start'] if len(word_alignments) > 0 else 0
            pause_ratio = sum(pauses) / total_speech_length if total_speech_length > 0 else 0
            
            # Evaluate pause quality - good speakers use appropriate pauses
            # Too many or too few pauses can affect comprehension
            if 0.1 <= pause_ratio <= 0.25:
                # Optimal pause ratio
                pause_quality_score = 90 - ((pause_ratio - 0.15) * 100)
            elif pause_ratio < 0.1:
                # Too few pauses
                pause_quality_score = 70 + (pause_ratio * 200)
            else:
                # Too many pauses
                pause_quality_score = 90 - ((pause_ratio - 0.25) * 120)
                
            # Adjust based on pause consistency
            if len(pauses) > 2:
                pause_std = np.std(pauses)
                pause_cv = pause_std / avg_pause_duration if avg_pause_duration > 0 else 0
                
                # Consistent pauses are better
                if pause_cv < 0.5:
                    pause_quality_score += 5
                elif pause_cv > 1.0:
                    pause_quality_score -= 5
        
        # Analyze hesitations
        if total_speech_length > 0:
            hesitation_ratio = len(hesitations) / (len(word_alignments) / 10) if len(word_alignments) > 0 else 0
            
            # Evaluate hesitation quality - fewer hesitations are better
            if hesitation_ratio <= 0.1:
                # Very few hesitations
                hesitation_score = 90
            elif hesitation_ratio <= 0.3:
                # Some hesitations
                hesitation_score = 80 - ((hesitation_ratio - 0.1) * 50)
            else:
                # Many hesitations
                hesitation_score = 70 - ((hesitation_ratio - 0.3) * 30)
        
        # Analyze speech flow using word durations
        if len(word_alignments) > 3:
            word_durations = []
            for word in word_alignments:
                if 'start' in word and 'end' in word:
                    duration = word['end'] - word['start']
                    word_durations.append(duration)
            
            if word_durations:
                # Calculate speech rate consistency
                mean_duration = np.mean(word_durations)
                std_duration = np.std(word_durations)
                duration_cv = std_duration / mean_duration if mean_duration > 0 else 0
                
                # Evaluate speech flow
                # Some variation is natural, but too much indicates choppy speech
                if duration_cv < 0.5:
                    # Consistent flow
                    flow_score = 90 - (duration_cv * 20)
                elif duration_cv < 0.8:
                    # Moderate variation
                    flow_score = 80 - ((duration_cv - 0.5) * 30)
                else:
                    # Highly variable durations
                    flow_score = 70 - ((duration_cv - 0.8) * 25)
        
        # Ensure scores are in valid range
        pause_quality_score = max(60, min(95, pause_quality_score))
        hesitation_score = max(60, min(95, hesitation_score))
        flow_score = max(60, min(95, flow_score))
        
        # Overall fluency score
        fluency_score = (pause_quality_score * 0.3) + (hesitation_score * 0.4) + (flow_score * 0.3)
        
        return {
            'overall_score': round(fluency_score, 1),
            'pause_quality_score': round(pause_quality_score, 1),
            'hesitation_score': round(hesitation_score, 1),
            'flow_score': round(flow_score, 1),
            'pause_count': pause_count,
            'avg_pause_duration': round(avg_pause_duration, 2) if pauses else None
        }
        
    def analyze_articulation(self, audio_features, transcript, word_alignments):
        """
        Analyze speech articulation quality (clarity, precision of consonants and vowels).
        
        Args:
            audio_features: Extracted audio features
            transcript: Text transcription
            word_alignments: Word timing information
            
        Returns:
            Dict: Articulation metrics
        """
        # Default articulation scores
        clarity_score = 80.0
        precision_score = 80.0
        
        if not audio_features:
            return {
                'overall_score': round((clarity_score + precision_score) / 2, 1),
                'clarity_score': round(clarity_score, 1),
                'precision_score': round(precision_score, 1)
            }
        
        # Analyze spectral clarity using spectral statistics
        if 'centroid' in audio_features and 'bandwidth' in audio_features:
            # Calculate mean spectral centroid (relates to brightness/clarity)
            centroid_mean = np.mean(audio_features['centroid'])
            
            # Calculate spectral bandwidth (spread around centroid)
            bandwidth_mean = np.mean(audio_features['bandwidth'])
            
            # Spectral contrast (difference between peaks and valleys)
            contrast_mean = np.mean(np.mean(audio_features['contrast'], axis=1)) if 'contrast' in audio_features else 0
            
            # Evaluate clarity
            # Clear speech typically has appropriate spectral balance
            # Neither too muffled (low centroid) nor too harsh (high centroid)
            clarity_factor = centroid_mean / 2000  # Normalize to typical speech centroid range
            
            if 0.8 <= clarity_factor <= 1.2:
                # Good spectral balance
                clarity_score = 85 + (contrast_mean * 10)
            elif clarity_factor < 0.8:
                # Too muffled
                clarity_score = 75 + (clarity_factor * 10) + (contrast_mean * 5)
            else:
                # Too harsh/bright
                clarity_score = 85 - ((clarity_factor - 1.2) * 25) + (contrast_mean * 5)
        
        # Analyze precision using zero-crossing rate and energy patterns
        if 'zcr' in audio_features and 'energy' in audio_features:
            # ZCR indicates consonant precision (especially fricatives)
            zcr_mean = np.mean(audio_features['zcr'])
            zcr_std = np.std(audio_features['zcr'])
            
            # Energy dynamics indicate articulatory precision
            energy_dynamics = np.diff(audio_features['energy'])
            energy_transitions = np.mean(np.abs(energy_dynamics))
            
            # Evaluate precision
            # ZCR should be variable for good articulation (indicates clear consonants)
            zcr_variation = zcr_std / zcr_mean if zcr_mean > 0 else 0
            
            if zcr_variation > 0.5 and energy_transitions > 0.01:
                # Good dynamic articulation
                precision_score = 85 + (zcr_variation * 10) + (energy_transitions * 100)
            else:
                # Less distinct articulation
                precision_score = 75 + (zcr_variation * 10) + (energy_transitions * 100)
        
        # Ensure scores are in valid range
        clarity_score = max(60, min(95, clarity_score))
        precision_score = max(60, min(95, precision_score))
        
        # Overall articulation score
        articulation_score = (clarity_score * 0.5) + (precision_score * 0.5)
        
        return {
            'overall_score': round(articulation_score, 1),
            'clarity_score': round(clarity_score, 1),
            'precision_score': round(precision_score, 1)
        }
        
    def analyze_pronunciation(self, audio_file, transcript, word_alignments=None):
        """
        Perform complete pronunciation analysis on speech audio.
        
        Args:
            audio_file: Path to audio file
            transcript: Text transcription of speech
            word_alignments: Optional word timing information
            
        Returns:
            Dict: Complete pronunciation analysis results
        """
        # Extract audio features
        audio_features = self.extract_audio_features(audio_file)
        
        # If no audio features could be extracted, use confidence scores if available
        if not audio_features and isinstance(word_alignments, dict) and 'segments' in word_alignments:
            return self._analyze_from_confidence_scores(word_alignments, transcript)
        
        # Analyze phoneme accuracy
        phoneme_accuracy = self.analyze_phoneme_accuracy(audio_features, transcript, word_alignments)
        
        # Analyze prosody
        prosody = self.analyze_prosody(audio_features, transcript, word_alignments)
        
        # Analyze fluency
        fluency = self.analyze_fluency(audio_features, transcript, word_alignments)
        
        # Analyze articulation
        articulation = self.analyze_articulation(audio_features, transcript, word_alignments)
        
        # Calculate overall pronunciation score
        weights = self.config['scoring_weights']
        overall_score = (
            (phoneme_accuracy['overall_score'] * weights['phoneme_accuracy']) +
            (prosody['overall_score'] * weights['prosody']) +
            (fluency['overall_score'] * weights['fluency']) +
            (articulation['overall_score'] * weights['articulation'])
        )
        
        # Apply difficulty adjustment if configured
        if self.config['difficulty_adjustment']:
            # Adjust based on transcript complexity
            words = word_tokenize(transcript)
            advanced_word_count = sum(1 for word in words if len(word) > 8)  # Simple heuristic
            complexity_factor = min(1.1, max(0.9, 1 + (advanced_word_count / len(words) * 0.2)))
            overall_score *= complexity_factor
        
        # Apply accent adjustment if configured
        # This prevents penalizing non-native accents too harshly
        if self.config['accent_adjustment'] and phoneme_accuracy['overall_score'] < 75:
            # Boost phoneme accuracy score but keep other scores
            phoneme_boost = min(15, max(0, 75 - phoneme_accuracy['overall_score'])) * 0.5
            overall_score += (phoneme_boost * weights['phoneme_accuracy'])
        
        # Ensure score is within configured scale
        min_score, max_score = self.config['scoring_scale']
        overall_score = max(min_score, min(max_score, overall_score))
        
        return {
            'pronunciation_score': round(overall_score, 1),
            'phoneme_accuracy': phoneme_accuracy,
            'prosody': prosody,
            'fluency': fluency,
            'articulation': articulation
        }
    
    def _analyze_from_confidence_scores(self, word_alignments, transcript):
        """
        Fallback analysis method when audio features cannot be extracted.
        Uses confidence scores from ASR system if available.
        
        Args:
            word_alignments: Word alignment data with confidence scores
            transcript: Text transcription
            
        Returns:
            Dict: Basic pronunciation analysis results
        """
        # Extract confidence scores if available
        confidence_scores = []
        word_durations = []
        
        if 'segments' in word_alignments:
            for segment in word_alignments['segments']:
                # Extract confidence score
                if 'confidence' in segment:
                    confidence_scores.append(segment['confidence'])
                
                # Analyze words in the segment
                for word_info in segment.get('words', []):
                    if 'start' in word_info and 'end' in word_info:
                        duration = word_info['end'] - word_info['start']
                        word_durations.append(duration)
        
        # Calculate phoneme accuracy from confidence scores
        phoneme_accuracy = {}
        if confidence_scores:
            avg_confidence = np.mean(confidence_scores)
            std_confidence = np.std(confidence_scores)
            
            # Map confidence to phoneme accuracy score
            accuracy_score = 65 + (avg_confidence * 30)
            accuracy_score = max(60, min(95, accuracy_score))
            
            phoneme_accuracy = {
                'overall_score': round(accuracy_score, 1),
                'categories': {
                    'general': {
                        'count': len(confidence_scores),
                        'score': round(accuracy_score, 1)
                    }
                },
                'difficult_phonemes': []
            }
        else:
            # Default phoneme accuracy
            phoneme_accuracy = {
                'overall_score': 75.0,
                'categories': {},
                'difficult_phonemes': []
            }
        
        # Calculate speech rhythm score based on word durations
        prosody = {}
        if word_durations and len(word_durations) > 1:
            # Calculate coefficient of variation (lower is more consistent)
            mean_duration = np.mean(word_durations)
            std_duration = np.std(word_durations)
            cv = std_duration / mean_duration if mean_duration > 0 else 0
            
            # Calculate speech rate
            total_duration = sum(word_durations)
            word_count = len(word_durations)
            speech_rate = (word_count / total_duration) * 60 if total_duration > 0 else None
            
            # Convert to rhythm score (lower CV = higher score)
            rhythm_score = 90 - min(cv * 100, 30)
            rhythm_score = max(60, min(95, rhythm_score))
            
            # Default prosody scores with rhythm from durations
            prosody = {
                'overall_score': round((rhythm_score + 80 + 80) / 3, 1),  # Avg with default scores
                'intonation_score': 80.0,  # Default
                'rhythm_score': round(rhythm_score, 1),
                'stress_score': 80.0,  # Default
                'speech_rate': round(speech_rate, 1) if speech_rate else None
            }
        else:
            # Default prosody scores
            prosody = {
                'overall_score': 80.0,
                'intonation_score': 80.0,
                'rhythm_score': 80.0,
                'stress_score': 80.0,
                'speech_rate': None
            }
        
        # Default fluency and articulation scores
        fluency = {
            'overall_score': 80.0,
            'pause_quality_score': 80.0,
            'hesitation_score': 80.0,
            'flow_score': 80.0,
            'pause_count': None,
            'avg_pause_duration': None
        }
        
        articulation = {
            'overall_score': 80.0,
            'clarity_score': 80.0,
            'precision_score': 80.0
        }
        
        # Calculate overall pronunciation score
        weights = self.config['scoring_weights']
        overall_score = (
            (phoneme_accuracy['overall_score'] * weights['phoneme_accuracy']) +
            (prosody['overall_score'] * weights['prosody']) +
            (fluency['overall_score'] * weights['fluency']) +
            (articulation['overall_score'] * weights['articulation'])
        )
        
        # Ensure score is within configured scale
        min_score, max_score = self.config['scoring_scale']
        overall_score = max(min_score, min(max_score, overall_score))
        
        return {
            'pronunciation_score': round(overall_score, 1),
            'phoneme_accuracy': phoneme_accuracy,
            'prosody': prosody,
            'fluency': fluency,
            'articulation': articulation,
            'note': "Limited analysis based on confidence scores only. For more detailed analysis, provide audio file."
        }


def analyze_pronunciation(result, transcription, audio_file=None, domain_config=None):
    """
    Enhanced pronunciation analysis function that integrates with the vocabulary evaluation.
    
    Parameters:
    result (dict): Result data from the speech recognition process
    transcription (str): The transcribed speech text
    audio_file (str): Optional path to the audio file for detailed analysis
    domain_config (dict): Optional configuration for domain-specific scoring
    
    Returns:
    dict: Pronunciation analysis results
    """
    # Create pronunciation analyzer with default configuration
    analyzer_config = {
        'scoring_weights': {
            'phoneme_accuracy': 0.35,
            'prosody': 0.25,
            'fluency': 0.2,
            'articulation': 0.2
        },
        'accent_adjustment': True,
        'scoring_scale': (50, 95),
        'difficulty_adjustment': True
    }
    
    # Update with domain-specific settings if provided
    if domain_config and 'pronunciation_config' in domain_config:
        analyzer_config.update(domain_config['pronunciation_config'])
    
    # Initialize the analyzer
    analyzer = PronunciationAnalyzer(config=analyzer_config)
    
    # If audio file is provided, perform detailed analysis
    if audio_file and os.path.exists(audio_file):
        word_alignments = result.get('segments', []) if isinstance(result, dict) else []
        return analyzer.analyze_pronunciation(audio_file, transcription, word_alignments)
    
    # Otherwise, use the confidence scores from result
    return analyzer._analyze_from_confidence_scores(result, transcription)


def calculate_vocabulary_evaluation(result, transcription, audio_file=None, domain_config=None):
    """
    Calculate the vocabulary evaluation scores with enhanced pronunciation analysis.
    
    Parameters:
    result (dict): Result data from the speech recognition process
    transcription (str): The transcribed speech text
    audio_file (str): Optional path to the audio file for detailed pronunciation analysis
    domain_config (dict): Optional configuration for domain-specific scoring
    
    Returns:
    dict: Complete vocabulary evaluation
    """
    # Ensure NLTK data is downloaded
    download_nltk_data()
    
    # Get word frequency data
    word_percentiles = get_word_frequency_data()
    
    # Grammar and Word Selection Analysis
    grammar_analysis = analyze_grammar_and_word_selection(
        transcription, 
        word_percentiles,
        domain_config
    )
    
    # Enhanced Pronunciation Analysis
    pronunciation_analysis = analyze_pronunciation(
        result, 
        transcription,
        audio_file,
        domain_config
    )
    
    # Calculate overall Vocabulary Evaluation score
    grammar_word_selection_score = grammar_analysis["grammar_score"]
    pronunciation_score = pronunciation_analysis["pronunciation_score"]
    
    # Overall score is an average of the two components
    overall_score = (grammar_word_selection_score + pronunciation_score) / 2
    
    # Add evaluation metadata for transparency
    evaluation_metadata = {
        "evaluation_version": "3.0",
        "corpora_used": ["brown", "webtext", "gutenberg"],
        "domain_specific": domain_config["domain_name"] if domain_config else "general",
        "detailed_pronunciation": audio_file is not None
    }
    
    return {
        "vocabulary_score": round(overall_score, 1),
        "grammar_word_selection": {
            "score": grammar_word_selection_score,
            "details": grammar_analysis
        },
        "pronunciation": {
            "score": pronunciation_score,
            "details": pronunciation_analysis
        },
        "metadata": evaluation_metadata
    }

# Example of domain-specific configuration for different competitions
DOMAIN_CONFIGS = {
    "general": {
        "domain_name": "general",
        "complexity_weights": {
            "frequency_weight": 0.5,
            "length_weight": 0.2,
            "semantic_weight": 0.3
        },
        "pronunciation_config": {
            "accent_adjustment": True,
            "difficulty_adjustment": True
        }
    },
    "academic": {
        "domain_name": "academic",
        "complexity_weights": {
            "frequency_weight": 0.4,
            "length_weight": 0.2,
            "semantic_weight": 0.4
        },
        "domain_terms": {
            "hypothesis": 0.2,
            "methodology": 0.2,
            "analysis": 0.2,
            "theoretical": 0.2,
            # Add academic terms with their adjustment values
        },
        "pronunciation_config": {
            "scoring_weights": {
                "phoneme_accuracy": 0.3,
                "prosody": 0.3,
                "fluency": 0.2,
                "articulation": 0.2
            }
        }
    },
    "business": {
        "domain_name": "business",
        "complexity_weights": {
            "frequency_weight": 0.5,
            "length_weight": 0.1,
            "semantic_weight": 0.4
        },
        "domain_terms": {
            "strategy": 0.2,
            "implementation": 0.2,
            "stakeholder": 0.2,
            # Add business terms with their adjustment values
        },
        "pronunciation_config": {
            "scoring_weights": {
                "phoneme_accuracy": 0.25,
                "prosody": 0.3,
                "fluency": 0.25,
                "articulation": 0.2
            }
        }
    },
    "technical": {
        "domain_name": "technical",
        "complexity_weights": {
            "frequency_weight": 0.3,
            "length_weight": 0.3,
            "semantic_weight": 0.4
        },
        "domain_terms": {
            "algorithm": 0.3,
            "implementation": 0.2,
            "interface": 0.2,
            # Add technical terms with their adjustment values
        },
        "pronunciation_config": {
            "scoring_weights": {
                "phoneme_accuracy": 0.4,
                "prosody": 0.2,
                "fluency": 0.2,
                "articulation": 0.2
            }
        }
    },
    "presentation": {
        "domain_name": "presentation",
        "complexity_weights": {
            "frequency_weight": 0.4,
            "length_weight": 0.2,
            "semantic_weight": 0.4
        },
        "pronunciation_config": {
            "scoring_weights": {
                "phoneme_accuracy": 0.2,
                "prosody": 0.4,  # Emphasize prosody for presentations
                "fluency": 0.25,
                "articulation": 0.15
            }
        }
    }
}

# Function to run evaluation with full parameters for easier usage
def evaluate_speech(result, transcription, audio_file=None, domain_type="general"):
    """
    Run a complete evaluation with simplified parameters.
    
    Parameters:
    result (dict): Result data from the speech recognition process
    transcription (str): The transcribed speech text
    audio_file (str): Optional path to the audio file for detailed pronunciation analysis
    domain_type (str): The domain type for the evaluation (general, academic, business, technical, presentation)
    
    Returns:
    dict: Complete evaluation results
    """
    domain_config = DOMAIN_CONFIGS.get(domain_type, DOMAIN_CONFIGS["general"])
    return calculate_vocabulary_evaluation(result, transcription, audio_file, domain_config)