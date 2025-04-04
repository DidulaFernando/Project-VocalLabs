import re
import nltk
from nltk.tokenize import sent_tokenize, word_tokenize
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
from collections import Counter
import math
import string
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import numpy as np

# Ensure NLTK data is downloaded
def download_nltk_data():
    try:
        nltk.data.find('tokenizers/punkt')
    except LookupError:
        nltk.download('punkt')
    
    try:
        nltk.data.find('corpora/stopwords')
    except LookupError:
        nltk.download('stopwords')
    
    try:
        nltk.data.find('corpora/wordnet')
    except LookupError:
        nltk.download('wordnet')
    
    try:
        nltk.data.find('taggers/averaged_perceptron_tagger')
    except LookupError:
        nltk.download('averaged_perceptron_tagger')

# Keywords indicating introduction
INTRO_KEYWORDS = [
    'introduction', 'introduce', 'begin', 'today', 'topic', 'discuss',
    'talk about', 'welcome', 'good morning', 'good afternoon', 'hello',
    'thank you for', 'I am here to', 'I will be', 'starting with',
    'first of all', 'to start with', 'I would like to'
]

# Keywords indicating conclusion
CONCLUSION_KEYWORDS = [
    'conclusion', 'conclude', 'summarize', 'summary', 'in closing',
    'to sum up', 'finally', 'lastly', 'in summary', 'to conclude',
    'wrapping up', 'in the end', 'as we have seen', 'in conclusion',
    'to summarize', 'overall', 'therefore', 'thus', 'in short'
]

# Keywords indicating transitions between main points
TRANSITION_KEYWORDS = [
    'first', 'second', 'third', 'next', 'then', 'furthermore',
    'additionally', 'moreover', 'another', 'following this',
    'subsequently', 'in addition', 'besides', 'also', 'finally',
    'now', 'turning to', 'moving on', 'shifting focus',
    'on one hand', 'on the other hand', 'however', 'nevertheless'
]

# Added: Beginning of body section transitions
BODY_START_KEYWORDS = [
    'first', 'firstly', 'to begin with', 'to start with', 'first of all',
    'my first point', 'the first aspect', 'to start', 'starting with',
    'let me start', 'beginning with', 'let us examine', "let's look at"
]


# Added: Section-to-section transition phrases
SECTION_TRANSITIONS = [
    'moving on to', 'now let\'s discuss', 'turning our attention to',
    'next I\'d like to address', 'having discussed', 'after examining',
    'with that in mind', 'considering this', 'given these points',
    'now that we understand', 'building on this idea', 'this leads us to'
]

def analyze_speech_structure(transcription):
    """
    Analyze the structure of a speech based on its transcription.
    
    Parameters:
    transcription (str): The transcribed speech text
    
    Returns:
    dict: Analysis of the speech structure with scores
    """
    download_nltk_data()
    
    # Clean text from pause markers
    cleaned_text = re.sub(r'\[\d+\.\d+ second pause\]', '', transcription)
    
    # Break into sentences
    sentences = sent_tokenize(cleaned_text)
    
    if not sentences:
        return {
            "structure_score": 70.0,
            "has_introduction": False,
            "has_conclusion": False,
            "body_structure": "unclear",
            "transition_count": 0,
            "section_proportions": {
                "introduction": 0,
                "body": 0,
                "conclusion": 0
            },
            "coherence_score": 0,
            "section_completeness": "incomplete"
        }
    
    total_sentences = len(sentences)
    
    # Improved section detection algorithm
    # First, scan for clear indicators of introduction and conclusion
    intro_markers = []
    conclusion_markers = []
    
    # Detect introduction and conclusion markers with their positions
    for i, sentence in enumerate(sentences):
        sentence_lower = sentence.lower()
        for keyword in INTRO_KEYWORDS:
            if keyword in sentence_lower:
                intro_markers.append((i, keyword))
                break
                
        for keyword in CONCLUSION_KEYWORDS:
            if keyword in sentence_lower:
                conclusion_markers.append((i, keyword))
                break
    
    # Determine introduction and conclusion boundaries
    intro_end = int(total_sentences * 0.2)  # Default: first 20%
    conclusion_start = int(total_sentences * 0.8)  # Default: last 20%
    
    # If we found introduction markers, use the last one to mark introduction end
    if intro_markers:
        intro_positions = [pos for pos, _ in intro_markers]
        last_intro_pos = max(intro_positions)
        intro_end = min(last_intro_pos + 3, int(total_sentences * 0.3))  # Add a few sentences, cap at 30%
    
    # If we found conclusion markers, use the first one to mark conclusion start
    if conclusion_markers:
        conclusion_positions = [pos for pos, _ in conclusion_markers]
        first_conclusion_pos = min(conclusion_positions)
        conclusion_start = max(first_conclusion_pos - 1, int(total_sentences * 0.7))  # Back up a sentence, floor at 70%
    
    # Ensure body section exists
    if intro_end >= conclusion_start:
        # If boundaries overlap, use defaults
        intro_end = int(total_sentences * 0.2)
        conclusion_start = int(total_sentences * 0.8)
    
    # Extract sections
    intro_section = sentences[:intro_end]
    body_section = sentences[intro_end:conclusion_start]
    conclusion_section = sentences[conclusion_start:]
    
    # Calculate section proportions
    intro_proportion = len(intro_section) / total_sentences
    body_proportion = len(body_section) / total_sentences
    conclusion_proportion = len(conclusion_section) / total_sentences
    
    # Score section proportions (ideal: intro 10-20%, body 60-80%, conclusion 10-20%)
    proportion_score = 100
    
    if intro_proportion < 0.05 or intro_proportion > 0.25:
        proportion_score -= 20  # Penalize if introduction is too short or too long
    
    if body_proportion < 0.5 or body_proportion > 0.85:
        proportion_score -= 20  # Penalize if body is too short or too long
    
    if conclusion_proportion < 0.05 or conclusion_proportion > 0.25:
        proportion_score -= 20  # Penalize if conclusion is too short or too long
    
    # Analyze section completeness
    has_introduction = bool(intro_markers) or intro_proportion >= 0.05
    has_conclusion = bool(conclusion_markers) or conclusion_proportion >= 0.05
    has_body = body_proportion >= 0.5
    
    if has_introduction and has_body and has_conclusion:
        section_completeness = "complete"
    elif has_introduction and has_body:
        section_completeness = "missing_conclusion"
    elif has_body and has_conclusion:
        section_completeness = "missing_introduction"
    elif has_body:
        section_completeness = "body_only"
    else:
        section_completeness = "incomplete"
    
    # Convert sections to text for analysis
    intro_text = ' '.join(intro_section).lower()
    body_text = ' '.join(body_section).lower()
    conclusion_text = ' '.join(conclusion_section).lower()
    
    # Count transitions in the body
    body_words = word_tokenize(body_text)
    body_transition_count = sum(1 for word in body_words if word in TRANSITION_KEYWORDS)
    
    # Enhanced: Check for section-to-section transitions
    section_transition_count = 0
    for phrase in SECTION_TRANSITIONS:
        if phrase in body_text:
            section_transition_count += 1
    
    # Enhanced: Detect body organization
    body_organization = "unclear"
    if any(keyword in body_text for keyword in BODY_START_KEYWORDS):
        # Check for sequential ordering words
        if all(keyword in body_text for keyword in ['first', 'second']):
            body_organization = "sequential"
        elif all(keyword in body_text for keyword in ['one', 'another']):
            body_organization = "sequential"
        elif all(keyword in body_text for keyword in ['first', 'next']):
            body_organization = "sequential"
        # Check for comparative structure
        elif all(keyword in body_text for keyword in ['however', 'despite']):
            body_organization = "comparative"
        elif all(keyword in body_text for keyword in ['advantage', 'disadvantage']):
            body_organization = "comparative"
        elif all(keyword in body_text for keyword in ['pros', 'cons']):
            body_organization = "comparative"
        # Check for causal structure
        elif all(keyword in body_text for keyword in ['because', 'therefore']):
            body_organization = "causal"
        elif all(keyword in body_text for keyword in ['cause', 'effect']):
            body_organization = "causal"
        elif all(keyword in body_text for keyword in ['leads to', 'results in']):
            body_organization = "causal"
        else:
            body_organization = "topical"  # Default if we found start but no clear pattern
    
    # Calculate coherence score based on transitions between sections
    coherence_score = 70  # Base score
    
    # Bonus for section transitions
    coherence_score += min(15, section_transition_count * 5)
    
    # Bonus for body organization
    if body_organization == "sequential":
        coherence_score += 15
    elif body_organization in ["comparative", "causal"]:
        coherence_score += 10
    elif body_organization == "topical":
        coherence_score += 5
    
    # Cap coherence score
    coherence_score = min(100, coherence_score)
    
    # Determine body structure quality based on transitions and organization
    body_structure = "excellent" if (body_transition_count >= 5 and body_organization != "unclear") else \
                    "good" if (body_transition_count >= 3 or body_organization != "unclear") else \
                    "adequate" if body_transition_count >= 1 else "unclear"
    
    # Calculate complete structure score
    # Base score: 70
    # Section completeness: +0 to +20
    # Section proportions: +0 to +10
    # Coherence: +0 to +20
    
    base_score = 70
    
    # Add points for section completeness
    if section_completeness == "complete":
        base_score += 20
    elif section_completeness in ["missing_conclusion", "missing_introduction"]:
        base_score += 10
    elif section_completeness == "body_only":
        base_score += 5
    
    # Add points for good proportions
    proportion_bonus = min(10, proportion_score / 10)
    base_score += proportion_bonus
    
    # Add points for coherence
    coherence_bonus = min(20, (coherence_score - 70) / 1.5)
    base_score += coherence_bonus
    
    # Cap at 100
    structure_score = min(100, base_score)
    
    return {
        "structure_score": structure_score,
        "has_introduction": has_introduction,
        "has_conclusion": has_conclusion,
        "body_structure": body_structure,
        "body_organization": body_organization,
        "transition_count": body_transition_count + section_transition_count,
        "section_proportions": {
            "introduction": round(intro_proportion * 100, 1),
            "body": round(body_proportion * 100, 1),
            "conclusion": round(conclusion_proportion * 100, 1)
        },
        "coherence_score": coherence_score,
        "section_completeness": section_completeness,
        "section_transition_count": section_transition_count
    }

def evaluate_time_utilization(actual_duration, expected_duration):
    """
    Evaluate speech timing based on simplified scoring system.
    
    Parameters:
    actual_duration (int): Actual duration in seconds
    expected_duration (str): Expected duration string (e.g., "5–7 minutes")
    
    Returns:
    dict: Time utilization analysis with simplified scoring
    """
    try:
        # Define standard durations
        SPEECH_DURATIONS = {
            "Ice Breaker Speech": (4, 6),    # 4-6 minutes
            "Prepared Speeches": (5, 7),      # 5-7 minutes
            "Evaluation Speech": (2, 3),      # 2-3 minutes
            "Table Topics": (1, 2)            # 1-2 minutes
        }
        
        # Parse expected duration
        expected_duration = expected_duration.replace('–', '-')  # Standardize hyphen
        if '-' in expected_duration:
            parts = expected_duration.split('-')
            min_minutes = float(parts[0].strip())
            max_minutes = float(parts[1].split()[0].strip())  # Remove 'minutes'
        else:
            # Default to Prepared Speech if format is incorrect
            min_minutes, max_minutes = 5, 7
        
        # Convert to seconds
        min_seconds = min_minutes * 60
        max_seconds = max_minutes * 60
        actual_minutes = actual_duration / 60
        
        # Calculate deviation from acceptable range
        if actual_duration < min_seconds:
            deviation = min_seconds - actual_duration
        elif actual_duration > max_seconds:
            deviation = actual_duration - max_seconds
        else:
            deviation = 0
        
        # Apply scoring rules - Scale scores from 0-10 to 0-100 for consistency
        if deviation == 0 or deviation <= 10:  # Within range or ±10 seconds
            score = 100.0
            message = "Excellent timing! Speech duration was perfect."
        elif deviation <= 15:  # ±10-15 seconds
            score = 75.0
            message = "Good timing, but slightly outside the ideal range."
        elif deviation <= 25:  # ±15-25 seconds
            score = 50.0
            message = "Speech duration needs moderate adjustment."
        elif deviation <= 30:  # ±25-30 seconds
            score = 30.0
            message = "Speech duration needs significant adjustment."
        else:  # More than 30 seconds off
            score = 0.0
            message = "Speech duration was substantially outside the expected range."
        
        return {
            "score": score,  # Score out of 100
            "time_utilization_score": score,  # Add this for compatibility
            "actual_duration_minutes": round(actual_minutes, 1),
            "expected_range": {
                "min_minutes": min_minutes,
                "max_minutes": max_minutes
            },
            "deviation_seconds": round(deviation, 1),
            "message": message,
            "status": "within_range" if score >= 75 else "needs_adjustment"
        }
        
    except Exception as e:
        print(f"Error in time utilization evaluation: {e}")
        return {
            "score": 70.0,
            "time_utilization_score": 70.0,  # Add this for compatibility
            "actual_duration_minutes": 0,
            "expected_range": {"min_minutes": 0, "max_minutes": 0},
            "deviation_seconds": 0,
            "message": "Error evaluating time utilization",
            "status": "error"
        }

def get_rating_description(score):
    """Get a qualitative rating based on a 0-100 score."""
    if score >= 90:
        return "Outstanding"
    elif score >= 80:
        return "Excellent"
    elif score >= 70:
        return "Very Good"
    elif score >= 60:
        return "Good"
    elif score >= 50:
        return "Satisfactory"
    else:
        return "Needs Improvement"

def evaluate_speech_development(transcription: str, actual_duration: int, expected_duration: str) -> dict:
    """
    Evaluate the development of a speech based on structure and time utilization.
    
    Parameters:
    transcription (str): The transcribed speech text
    actual_duration (int): Actual duration in seconds
    expected_duration (str): Expected duration string (e.g., "5–7 minutes")
    
    Returns:
    dict: Complete speech development evaluation with structure and time utilization analysis
    """
    # Analyze structure
    structure_analysis = analyze_speech_structure(transcription)
    
    # Evaluate time utilization with structure information
    time_analysis = evaluate_time_utilization(actual_duration, expected_duration)
    
    # Calculate overall development score with weights
    structure_weight = 0.6  # Increased from 0.5
    time_weight = 0.4      # Increased from 0.3
    
    # Scale structure score from 0-100 to 0-10
    structure_score = structure_analysis["structure_score"] / 10
    
    # Use either score or time_utilization_score key from time_analysis
    # Scale time score from 0-100 to 0-10
    time_score = time_analysis.get("time_utilization_score", time_analysis.get("score", 70.0)) / 10
    
    # Calculate overall score (will be out of 10 since both components are out of 10)
    overall_score = (structure_score * structure_weight) + (time_score * time_weight)
    
    # Generate structure-specific feedback
    structure_feedback = []
    
    if not structure_analysis["has_introduction"]:
        structure_feedback.append("Add a clear introduction to establish your topic and purpose.")
    elif structure_analysis["section_proportions"]["introduction"] < 10:
        structure_feedback.append("Consider expanding your introduction to better prepare your audience.")
    
    if not structure_analysis["has_conclusion"]:
        structure_feedback.append("Add a conclusion to summarize key points and provide closure.")
    elif structure_analysis["section_proportions"]["conclusion"] < 10:
        structure_feedback.append("Expand your conclusion to reinforce your message and leave a lasting impression.")
    
    if structure_analysis["body_structure"] == "unclear":
        structure_feedback.append("Organize your main points more clearly with transition phrases.")
    elif structure_analysis["transition_count"] < 3:
        structure_feedback.append("Use more transition words to help your audience follow your speech.")
    
    # If no specific issues, provide positive feedback
    if not structure_feedback:
        if structure_analysis["structure_score"] >= 90:
            structure_feedback.append("Excellent speech structure with well-balanced sections and smooth transitions.")
        else:
            structure_feedback.append("Good overall structure. Continue practicing to perfect your speech organization.")
    
    # Generate time utilization feedback
    time_feedback = []
    
    # Add feedback about compliance with expected duration
    if time_analysis["status"] == "too_short":
        time_feedback.append(f"Your speech was shorter than the minimum required time. Aim for at least {time_analysis['min_expected_minutes']} minutes.")
    elif time_analysis["status"] == "too_long":
        time_feedback.append(f"Your speech exceeded the maximum time. Try to keep it under {time_analysis['max_expected_minutes']} minutes.")
    else:
        time_feedback.append("Great job keeping your speech within the expected time range.")
    
    # Add feedback about time distribution if available
    if "time_distribution" in time_analysis and time_analysis["time_distribution"]["breakdown"]:
        intro_percent = time_analysis["time_distribution"]["breakdown"]["introduction_percentage"]
        body_percent = time_analysis["time_distribution"]["breakdown"]["body_percentage"]
        conclusion_percent = time_analysis["time_distribution"]["breakdown"]["conclusion_percentage"]
        
        if intro_percent < 5:
            time_feedback.append("Your introduction was too brief. Aim for 10-15% of your total speech time.")
        elif intro_percent > 25:
            time_feedback.append("Your introduction was too long. Try to keep it to 10-15% of your total speech time.")
        
        if body_percent < 60:
            time_feedback.append("You didn't spend enough time on the main body of your speech. This should be 60-80% of your total time.")
        elif body_percent > 85:
            time_feedback.append("Almost all your time was spent on the body of your speech. Allocate more time to your introduction and conclusion.")
        
        if conclusion_percent < 5:
            time_feedback.append("Your conclusion was too brief. Aim for 10-15% of your total speech time.")
        elif conclusion_percent > 25:
            time_feedback.append("Your conclusion was too long. Try to keep it to 10-15% of your total speech time.")
        
        if not time_feedback[1:] and time_analysis["time_distribution"]["quality"] in ["good", "very_good", "excellent"]:
            time_feedback.append("You allocated your time effectively between introduction, body, and conclusion.")
    
    # Round to 1 decimal place
    overall_score = round(overall_score, 1)
    
    # Get qualitative rating
    rating = get_rating_description(overall_score)
    
    return {
        "development_score": overall_score,  # Already out of 10
        "rating": rating,
        "structure": {
            "score": round(structure_score, 1),  # Now out of 10
            "details": structure_analysis,
            "feedback": structure_feedback
        },
        "time_utilization": {
            "score": round(time_score, 1),  # Now out of 10
            "details": time_analysis,
            "feedback": time_feedback
        }
    }
