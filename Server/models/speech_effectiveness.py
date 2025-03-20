import re
import nltk
from nltk.tokenize import sent_tokenize, word_tokenize
from nltk.corpus import stopwords
from collections import Counter
import statistics
import math

# Download necessary NLTK data
def download_nltk_data():
    try:
        nltk.data.find('tokenizers/punkt')
        nltk.data.find('corpora/stopwords')
    except LookupError:
        nltk.download('punkt')
        nltk.download('stopwords')

# Keywords indicating purpose/intent
PURPOSE_KEYWORDS = {
    'informative': ['explain', 'inform', 'describe', 'present', 'show', 'demonstrate', 'illustrate', 'clarify'],
    'persuasive': ['convince', 'persuade', 'argue', 'suggest', 'recommend', 'propose', 'advocate', 'urge'],
    'motivational': ['inspire', 'motivate', 'encourage', 'challenge', 'stimulate', 'energize', 'empower'],
    'instructional': ['teach', 'guide', 'instruct', 'direct', 'train', 'educate', 'coach', 'mentor']
}

# Keywords indicating transitions and structure
TRANSITION_WORDS = [
    'first', 'second', 'third', 'finally', 'lastly', 'next', 'then', 'subsequently',
    'meanwhile', 'previously', 'afterward', 'consequently', 'therefore', 'thus',
    'in conclusion', 'to summarize', 'in summary', 'in short', 'to illustrate',
    'for example', 'for instance', 'specifically', 'in particular', 'namely',
    'in other words', 'that is', 'to put it differently', 'again', 'further',
    'moreover', 'additionally', 'also', 'besides', 'furthermore', 'likewise',
    'similarly', 'in the same way', 'conversely', 'instead', 'in contrast',
    'on the other hand', 'on the contrary', 'however', 'nevertheless', 'still',
    'yet', 'though', 'although', 'even though', 'despite', 'in spite of',
    'because', 'since', 'due to', 'as a result', 'consequently', 'hence'
]

def analyze_purpose_clarity(transcription):
    """
    Analyze how clearly the purpose of the speech is communicated.
    
    Parameters:
    transcription (str): The transcribed speech text
    
    Returns:
    dict: Analysis of purpose clarity
    """
    download_nltk_data()
    
    # Clean text from pause markers
    cleaned_text = re.sub(r'\[\d+\.\d+ second pause\]', '', transcription)
    
    # Tokenize and clean the text
    words = word_tokenize(cleaned_text.lower())
    stop_words = set(stopwords.words('english'))
    filtered_words = [word for word in words if word.isalpha() and word not in stop_words]
    
    # Score based on presence of purpose-indicating words
    purpose_scores = {}
    total_words = len(filtered_words)
    
    if total_words == 0:
        return {
            "purpose_clarity_score": 70.0,
            "primary_purpose": "unknown",
            "purpose_strength": 0.0,
            "purpose_in_introduction": False
        }
    
    for purpose, keywords in PURPOSE_KEYWORDS.items():
        matches = sum(1 for word in filtered_words if word in keywords)
        purpose_scores[purpose] = matches / total_words if total_words > 0 else 0
    
    # Determine the primary purpose
    primary_purpose = max(purpose_scores.items(), key=lambda x: x[1])[0] if purpose_scores else 'unclear'
    purpose_strength = max(purpose_scores.values()) if purpose_scores else 0
    
    # Score the overall purpose clarity (0-1)
    purpose_clarity = min(1.0, purpose_strength * 5)
    
    # Convert to a 0-100 scale for reporting
    purpose_clarity_score = 50 + (purpose_clarity * 40)
    
    # Analyze the introduction (first 20% of the text)
    sentences = sent_tokenize(cleaned_text)
    intro_size = max(1, int(len(sentences) * 0.2))
    intro_text = ' '.join(sentences[:intro_size])
    intro_words = word_tokenize(intro_text.lower())
    intro_filtered = [word for word in intro_words if word.isalpha() and word not in stop_words]
    
    # Check if purpose keywords appear in the introduction
    purpose_in_intro = any(word in intro_filtered for purpose_list in PURPOSE_KEYWORDS.values() for word in purpose_list)
    
    # Boost score if purpose is stated early
    if purpose_in_intro:
        purpose_clarity_score = min(100, purpose_clarity_score + 10)
    
    return {
        "purpose_clarity_score": round(purpose_clarity_score, 1),
        "primary_purpose": primary_purpose,
        "purpose_strength": round(purpose_strength * 100, 1),
        "purpose_in_introduction": purpose_in_intro
    }

def analyze_purpose_achievement(transcription):
    """
    Analyze how well the speech achieves its purpose.
    
    Parameters:
    transcription (str): The transcribed speech text
    
    Returns:
    dict: Analysis of purpose achievement
    """
    download_nltk_data()
    
    # Clean text from pause markers
    cleaned_text = re.sub(r'\[\d+\.\d+ second pause\]', '', transcription)
    
    # Tokenize into sentences
    sentences = sent_tokenize(cleaned_text)
    
    if not sentences:
        return {
            "achievement_score": 70.0,
            "structure_quality": 65.0,
            "content_relevance": 75.0,
            "conclusion_strength": 70.0
        }
    
    # Analyze speech structure
    transition_count = 0
    for sentence in sentences:
        words = word_tokenize(sentence.lower())
        sentence_text = sentence.lower()
        
        # Count individual transition words
        for word in words:
            if word in TRANSITION_WORDS:
                transition_count += 1
        
        # Count phrases (may span multiple tokens)
        for phrase in [tw for tw in TRANSITION_WORDS if ' ' in tw]:
            if phrase in sentence_text:
                transition_count += 1
    
    # Structure quality score based on transitions and sentence count
    transition_density = transition_count / len(sentences)
    structure_quality = 60 + min(30, transition_density * 60)
    
    # Analyze content relevance by looking for key topic consistency
    # Without advanced NLP, we'll use a simple heuristic:
    # 1. Find most frequent content words
    # 2. Check consistency throughout the speech
    words = word_tokenize(cleaned_text.lower())
    stop_words = set(stopwords.words('english'))
    content_words = [word for word in words if word.isalpha() and word not in stop_words and len(word) > 3]
    
    if content_words:
        word_counter = Counter(content_words)
        top_words = [word for word, _ in word_counter.most_common(5)]
        
        # Split speech into beginning, middle, and end
        third_size = max(1, len(sentences) // 3)
        beginning = ' '.join(sentences[:third_size])
        middle = ' '.join(sentences[third_size:2*third_size])
        end = ' '.join(sentences[2*third_size:])
        
        # Check if top words appear in all parts
        sections = [beginning, middle, end]
        topic_consistency = 0
        for word in top_words:
            sections_with_word = sum(1 for section in sections if word in section.lower())
            topic_consistency += sections_with_word / len(sections)
        
        # Average consistency across top words
        avg_consistency = topic_consistency / len(top_words) if top_words else 0
        content_relevance = 60 + min(35, avg_consistency * 40)
    else:
        content_relevance = 70  # Default if no content words found
    
    # Check for conclusion strength
    conclusion_section = ' '.join(sentences[-max(1, int(len(sentences) * 0.2)):])
    conclusion_markers = ['conclude', 'conclusion', 'summary', 'summarize', 'finally', 'lastly', 
                          'in closing', 'to sum up', 'in summary', 'therefore', 'thus', 'overall']
    
    has_conclusion = any(marker in conclusion_section.lower() for marker in conclusion_markers)
    conclusion_strength = 80 if has_conclusion else 60
    
    # Calculate overall achievement score
    achievement_score = (structure_quality * 0.4) + (content_relevance * 0.4) + (conclusion_strength * 0.2)
    
    return {
        "achievement_score": round(achievement_score, 1),
        "structure_quality": round(structure_quality, 1),
        "content_relevance": round(content_relevance, 1),
        "conclusion_strength": round(conclusion_strength, 1)
    }

def evaluate_speech_effectiveness(transcription):
    """
    Evaluate the overall effectiveness of the speech.
    
    Parameters:
    transcription (str): Transcribed text
    
    Returns:
    dict: Complete speech effectiveness evaluation
    """
    # Ensure NLTK data is available
    download_nltk_data()
    
    # Run analyses
    purpose_analysis = analyze_purpose_clarity(transcription)
    achievement_analysis = analyze_purpose_achievement(transcription)
    
    # Calculate category scores
    clear_purpose_score = purpose_analysis["purpose_clarity_score"]
    achievement_score = achievement_analysis["achievement_score"]
    
    # Calculate overall effectiveness score
    effectiveness_score = (clear_purpose_score * 0.5) + (achievement_score * 0.5)
    
    # Determine qualitative rating
    if effectiveness_score >= 85:
        rating = "Excellent"
    elif effectiveness_score >= 75:
        rating = "Very Good"
    elif effectiveness_score >= 65:
        rating = "Good"
    elif effectiveness_score >= 55:
        rating = "Fair"
    else:
        rating = "Needs Improvement"
    
    return {
        "effectiveness_score": round(effectiveness_score, 1),
        "rating": rating,
        "clear_purpose": {
            "score": round(clear_purpose_score, 1),
            "details": purpose_analysis
        },
        "achievement_of_purpose": {
            "score": round(achievement_score, 1),
            "details": achievement_analysis
        }
    }