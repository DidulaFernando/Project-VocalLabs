import re
import nltk
from nltk.tokenize import word_tokenize
from collections import Counter
import numpy as np
import statistics

# Download necessary NLTK data
def download_nltk_data():
    try:
        nltk.data.find('tokenizers/punkt')
    except LookupError:
        nltk.download('punkt')
    
    try:
        nltk.data.find('taggers/averaged_perceptron_tagger')
    except LookupError:
        nltk.download('averaged_perceptron_tagger')

# Vocabulary complexity levels with some common words in each category
BASIC_WORDS = {
    'good', 'bad', 'big', 'small', 'happy', 'sad', 'go', 'come', 'make', 'take', 'see', 
    'look', 'find', 'get', 'give', 'think', 'say', 'tell', 'work', 'call', 'try', 'ask', 
    'need', 'feel', 'leave', 'put', 'like', 'time', 'know', 'people', 'year', 'way', 'day',
    'man', 'thing', 'woman', 'life', 'child', 'world', 'school', 'state', 'family', 'student',
    'group', 'country', 'problem', 'hand', 'part', 'place', 'case', 'week', 'company', 'system',
    'program', 'question', 'work', 'government', 'number', 'night', 'point', 'home', 'water',
    'room', 'mother', 'area', 'money', 'story', 'fact', 'month', 'lot', 'right', 'study'
}

INTERMEDIATE_WORDS = {
    'accomplish', 'adequate', 'analyze', 'approach', 'appropriate', 'assemble', 'capable',
    'comprehensive', 'concentrate', 'concern', 'considerable', 'convey', 'demonstrate',
    'determine', 'develop', 'disclose', 'efficient', 'emphasize', 'enhance', 'establish',
    'evaluate', 'facilitate', 'fundamental', 'generate', 'implement', 'indicate', 'individual',
    'interpret', 'maintain', 'modify', 'monitor', 'objective', 'obtain', 'participate',
    'perceive', 'positive', 'potential', 'previous', 'primary', 'principle', 'procedure',
    'process', 'require', 'research', 'resolve', 'resources', 'respond', 'significant',
    'similar', 'specific', 'strategy', 'structure', 'sufficient', 'summarize', 'technique'
}

ADVANCED_WORDS = {
    'acquiesce', 'ambiguous', 'anomaly', 'anticipate', 'assiduous', 'astute', 'attenuate',
    'audacious', 'austere', 'autonomous', 'avarice', 'capricious', 'cogent', 'cognizant',
    'commensurate', 'comprehensive', 'conundrum', 'corroborate', 'credulous', 'deleterious',
    'denigrate', 'derivative', 'desiccate', 'didactic', 'dilatory', 'discursive', 'dissident',
    'dogmatic', 'ebullient', 'efficacious', 'egregious', 'elicit', 'empirical', 'endemic',
    'enervate', 'ephemeral', 'equivocal', 'esoteric', 'exacerbate', 'expedient', 'extraneous',
    'fallacious', 'fastidious', 'furtive', 'gratuitous', 'heterogeneous', 'homogeneous',
    'hypothesis', 'impetuous', 'implicit', 'impute', 'inane', 'incisive', 'indigenous'
}

def analyze_word_complexity(word):
    """Determine the complexity level of a given word."""
    word = word.lower()
    
    if word in ADVANCED_WORDS:
        return 3  # Advanced
    elif word in INTERMEDIATE_WORDS:
        return 2  # Intermediate
    elif word in BASIC_WORDS or len(word) <= 4:
        return 1  # Basic
    else:
        # Simple heuristic: longer words tend to be more complex
        if len(word) >= 8:
            return 2.5  # Likely intermediate to advanced
        elif len(word) >= 6:
            return 1.5  # Likely basic to intermediate
        else:
            return 1  # Basic
            
def analyze_grammar_and_word_selection(transcription):
    """
    Analyze the grammar and word selection in the transcription.
    
    Parameters:
    transcription (str): The transcribed speech text
    
    Returns:
    dict: Analysis of grammar and word selection
    """
    # Ensure NLTK data is downloaded
    download_nltk_data()
    
    # Clean text and tokenize
    cleaned_text = re.sub(r'\[[\d.]+ second pause\]', '', transcription)  # Remove pause markers
    cleaned_text = re.sub(r'[^\w\s.,!?]', '', cleaned_text)  # Remove special characters
    
    words = word_tokenize(cleaned_text)
    words = [word for word in words if word.isalpha()]  # Keep only alphabetic words
    
    if not words:
        return {
            "word_count": 0,
            "unique_word_count": 0,
            "avg_word_length": 0,
            "word_complexity_score": 0,
            "sentence_complexity": 0,
            "grammar_score": 70.0
        }
    
    # Basic text statistics
    word_count = len(words)
    unique_words = len(set(words))
    avg_word_length = sum(len(word) for word in words) / word_count
    
    # Word complexity analysis
    complexity_scores = [analyze_word_complexity(word) for word in words]
    avg_complexity = sum(complexity_scores) / len(complexity_scores)
    
    # Count advanced words
    advanced_word_count = sum(1 for score in complexity_scores if score >= 2.5)
    advanced_word_percentage = (advanced_word_count / word_count) * 100
    
    # Sentence structure analysis (using NLTK's part-of-speech tagging)
    try:
        tagged_words = nltk.pos_tag(words)
        pos_counts = Counter(tag for _, tag in tagged_words)
        
        # Calculate distribution of parts of speech
        verb_count = sum(1 for _, tag in tagged_words if tag.startswith('VB'))
        noun_count = sum(1 for _, tag in tagged_words if tag.startswith('NN'))
        adj_count = sum(1 for _, tag in tagged_words if tag.startswith('JJ'))
        adv_count = sum(1 for _, tag in tagged_words if tag.startswith('RB'))
        
        # Grammatical complexity indicators
        verb_variety = verb_count / word_count
        modifier_ratio = (adj_count + adv_count) / word_count
        
        # Sentence complexity score (0-10)
        sentence_complexity = min(10, (verb_variety * 5) + (modifier_ratio * 5))
        
    except Exception as e:
        print(f"Error in POS tagging: {e}")
        sentence_complexity = 5  # Default value
    
    # Calculate Grammar and Word Selection Score (0-100)
    # 40% word complexity, 30% sentence complexity, 30% lexical diversity
    lexical_diversity = unique_words / word_count
    lexical_diversity_score = min(10, lexical_diversity * 20)  # Scale to 0-10
    
    word_complexity_score = min(10, avg_complexity * 3)  # Scale complexity to 0-10
    
    grammar_score = (word_complexity_score * 4) + (sentence_complexity * 3) + (lexical_diversity_score * 3)
    
    # Normalize to 0-100 scale
    grammar_score = max(50, min(95, grammar_score))
    
    # Adjust score based on advanced word percentage
    if advanced_word_percentage > 15:
        grammar_score = min(95, grammar_score + 5)
    elif advanced_word_percentage > 10:
        grammar_score = min(95, grammar_score + 3)
    elif advanced_word_percentage > 5:
        grammar_score = min(95, grammar_score + 1)
    
    return {
        "word_count": word_count,
        "unique_word_count": unique_words,
        "lexical_diversity": round(lexical_diversity, 2),
        "avg_word_length": round(avg_word_length, 1),
        "word_complexity_score": round(word_complexity_score, 1),
        "advanced_word_percentage": round(advanced_word_percentage, 1),
        "sentence_complexity": round(sentence_complexity, 1),
        "grammar_score": round(grammar_score, 1)
    }

def analyze_pronunciation(result):
    """
    Analyze pronunciation quality based on speech recognition results.
    
    Parameters:
    result (dict): Result data from the speech recognition process
    
    Returns:
    dict: Pronunciation analysis results
    """
    # Extract confidence scores if available
    confidence_scores = []
    word_durations = []
    
    if isinstance(result, dict) and 'segments' in result:
        for segment in result['segments']:
            # Extract confidence score
            if 'confidence' in segment:
                confidence_scores.append(segment['confidence'])
            
            # Analyze words in the segment
            for word_info in segment.get('words', []):
                if 'start' in word_info and 'end' in word_info:
                    duration = word_info['end'] - word_info['start']
                    word_durations.append(duration)
    
    # Calculate pronunciation clarity score
    if confidence_scores:
        avg_confidence = statistics.mean(confidence_scores)
        clarity_score = 65 + (avg_confidence * 30)  # Map 0-1 confidence to 65-95 scale
    else:
        # Default if no confidence data available
        clarity_score = 80.0
    
    # Calculate speech rhythm score based on word durations
    if word_durations and len(word_durations) > 1:
        # Calculate coefficient of variation (lower is more consistent)
        mean_duration = statistics.mean(word_durations)
        std_duration = statistics.stdev(word_durations)
        cv = std_duration / mean_duration if mean_duration > 0 else 0
        
        # Convert to a score (lower CV = higher score)
        rhythm_score = 90 - min(cv * 100, 30)
    else:
        # Default if no duration data available
        rhythm_score = 80.0
    
    # Calculate overall pronunciation score
    pronunciation_score = (clarity_score * 0.6) + (rhythm_score * 0.4)
    
    return {
        "clarity_score": round(clarity_score, 1),
        "rhythm_score": round(rhythm_score, 1),
        "pronunciation_score": round(pronunciation_score, 1)
    }

def calculate_vocabulary_evaluation(result, transcription):
    """
    Calculate the vocabulary evaluation scores.
    
    Parameters:
    result (dict): Result data from the speech recognition process
    transcription (str): The transcribed speech text
    
    Returns:
    dict: Complete vocabulary evaluation
    """
    # Grammar and Word Selection Analysis
    grammar_analysis = analyze_grammar_and_word_selection(transcription)
    
    # Pronunciation Analysis
    pronunciation_analysis = analyze_pronunciation(result)
    
    # Calculate overall Vocabulary Evaluation score
    grammar_word_selection_score = grammar_analysis["grammar_score"]
    pronunciation_score = pronunciation_analysis["pronunciation_score"]
    
    # Overall score is an average of the two components
    overall_score = (grammar_word_selection_score + pronunciation_score) / 2
    
    return {
        "vocabulary_score": round(overall_score, 1),
        "grammar_word_selection": {
            "score": grammar_word_selection_score,
            "details": grammar_analysis
        },
        "pronunciation": {
            "score": pronunciation_score,
            "details": pronunciation_analysis
        }
    }