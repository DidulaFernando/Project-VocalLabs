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

def evaluate_time_utilization(actual_duration, expected_duration, structure_analysis=None):
    """
    Evaluate how well the speech timing matches the expected duration and
    how effectively the time is distributed across speech sections.
    
    Parameters:
    actual_duration (int): Actual duration in seconds
    expected_duration (str): Expected duration string (e.g., "5–7 minutes")
    structure_analysis (dict, optional): Results from analyze_speech_structure
    
    Returns:
    dict: Time utilization analysis
    """
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
            target_minutes = (min_minutes + max_minutes) / 2  # Middle of the range is ideal
        else:
            # Single value like "5 minutes"
            min_minutes = max_minutes = target_minutes = float(expected_duration.split(' ')[0])
        
        # Convert to seconds
        min_seconds = min_minutes * 60
        max_seconds = max_minutes * 60
        target_seconds = target_minutes * 60
        
        # Calculate deviation from target
        deviation = abs(actual_duration - target_seconds) / target_seconds
        
        # Determine compliance status
        if actual_duration < min_seconds:
            status = "too_short"
            message = f"Speech was shorter than the minimum required time of {min_minutes} minutes."
            deviation_from_range = (min_seconds - actual_duration) / min_seconds
        elif actual_duration > max_seconds:
            status = "too_long"
            message = f"Speech exceeded the maximum time of {max_minutes} minutes."
            deviation_from_range = (actual_duration - max_seconds) / max_seconds
        else:
            status = "within_range"
            message = f"Speech duration was within the expected range of {expected_duration}."
            deviation_from_range = 0
        
        # Calculate basic time utilization score (0-100) based on timing compliance
        if status == "within_range":
            # Within range gets 80-100 points depending on how close to target
            compliance_score = 90 - (deviation * 50)
            compliance_score = max(80, min(100, compliance_score))
        else:
            # Outside range gets 50-80 points depending on deviation
            base_score = 80 - (deviation_from_range * 100)
            compliance_score = max(50, min(80, base_score))

        # Enhanced: Analyze time distribution across sections if structure analysis is available
        time_distribution_score = 70  # Default distribution score
        time_distribution_feedback = "No information available on time distribution."
        time_breakdown = {}
        distribution_quality = "unknown"
        
        if structure_analysis:
            # Get section proportions from structure analysis
            section_proportions = structure_analysis.get("section_proportions", {})
            intro_proportion = section_proportions.get("introduction", 0) / 100
            body_proportion = section_proportions.get("body", 0) / 100
            conclusion_proportion = section_proportions.get("conclusion", 0) / 100
            
            # Use these proportions to estimate time spent on each section
            intro_time = actual_duration * intro_proportion
            body_time = actual_duration * body_proportion
            conclusion_time = actual_duration * conclusion_proportion
            
            time_breakdown = {
                "introduction_seconds": round(intro_time, 1),
                "introduction_percentage": round(intro_proportion * 100, 1),
                "body_seconds": round(body_time, 1),
                "body_percentage": round(body_proportion * 100, 1),
                "conclusion_seconds": round(conclusion_time, 1),
                "conclusion_percentage": round(conclusion_proportion * 100, 1)
            }
            
            # Evaluate if time distribution is ideal
            # Ideal: intro 10-20%, body 60-80%, conclusion 10-20%
            distribution_score = 70  # Base score
            issues = []
            
            # Check introduction proportion
            if intro_proportion < 0.05:
                distribution_score -= 15
                issues.append("Introduction is too brief (under 5% of total time)")
            elif intro_proportion < 0.1:
                distribution_score -= 5
                issues.append("Introduction could be slightly longer (under 10% of total time)")
            elif intro_proportion > 0.25:
                distribution_score -= 15
                issues.append("Introduction is too long (over 25% of total time)")
            elif intro_proportion > 0.2:
                distribution_score -= 5
                issues.append("Introduction could be slightly shorter (over 20% of total time)")
                
            # Check body proportion
            if body_proportion < 0.5:
                distribution_score -= 20
                issues.append("Body of speech is too short (under 50% of total time)")
            elif body_proportion < 0.6:
                distribution_score -= 10
                issues.append("Body of speech could be expanded (under 60% of total time)")
            elif body_proportion > 0.85:
                distribution_score -= 15
                issues.append("Body is too dominant (over 85% of total time)")
                
            # Check conclusion proportion
            if conclusion_proportion < 0.05:
                distribution_score -= 15
                issues.append("Conclusion is too brief (under 5% of total time)")
            elif conclusion_proportion < 0.1:
                distribution_score -= 5
                issues.append("Conclusion could be slightly longer (under 10% of total time)")
            elif conclusion_proportion > 0.25:
                distribution_score -= 15
                issues.append("Conclusion is too long (over 25% of total time)")
            elif conclusion_proportion > 0.2:
                distribution_score -= 5
                issues.append("Conclusion could be slightly shorter (over 20% of total time)")
            
            # Bonus for near-ideal distribution
            if (0.1 <= intro_proportion <= 0.2 and 
                0.6 <= body_proportion <= 0.8 and 
                0.1 <= conclusion_proportion <= 0.2):
                distribution_score += 20
                issues.append("Excellent balance between introduction, body, and conclusion")
            
            # Cap the score
            distribution_score = max(40, min(100, distribution_score))
            
            # Set time distribution score and feedback
            time_distribution_score = distribution_score
            
            if issues:
                time_distribution_feedback = " ".join(issues)
            else:
                time_distribution_feedback = "Good distribution of time across speech sections."
            
            # Determine overall quality of time distribution
            if distribution_score >= 90:
                distribution_quality = "excellent"
            elif distribution_score >= 80:
                distribution_quality = "very_good"
            elif distribution_score >= 70:
                distribution_quality = "good"
            elif distribution_score >= 50:
                distribution_quality = "adequate"
            else:
                distribution_quality = "poor"
        
        # Calculate final time utilization score (weighted average)
        # 60% compliance with expected duration, 40% effective distribution
        if structure_analysis:
            time_utilization_score = (compliance_score * 0.6) + (time_distribution_score * 0.4)
        else:
            time_utilization_score = compliance_score
        
        return {
            "time_utilization_score": time_utilization_score,
            "compliance_score": compliance_score,
            "status": status,
            "message": message,
            "actual_duration_minutes": actual_duration / 60,
            "min_expected_minutes": min_minutes,
            "max_expected_minutes": max_minutes,
            "deviation": deviation * 100,  # Convert to percentage
            "time_distribution": {
                "score": time_distribution_score,
                "quality": distribution_quality,
                "feedback": time_distribution_feedback,
                "breakdown": time_breakdown
            }
        }
    except (ValueError, TypeError, AttributeError) as e:
        # If there's an error parsing the expected duration, give a neutral score
        return {
            "time_utilization_score": 70.0,
            "compliance_score": 70.0,
            "status": "error",
            "message": f"Unable to analyze time utilization: {str(e)}",
            "actual_duration_minutes": actual_duration / 60,
            "min_expected_minutes": 0,
            "max_expected_minutes": 0,
            "deviation": 0,
            "time_distribution": {
                "score": 70.0,
                "quality": "unknown",
                "feedback": "Unable to analyze time distribution due to an error.",
                "breakdown": {}
            }
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
    time_analysis = evaluate_time_utilization(actual_duration, expected_duration, structure_analysis)
    
    # Calculate overall development score with weights
    structure_weight = 0.6  # Increased from 0.5
    time_weight = 0.4      # Increased from 0.3
    
    overall_score = (
        structure_analysis["structure_score"] * structure_weight +
        time_analysis["time_utilization_score"] * time_weight
    )
    
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
        "development_score": overall_score,
        "rating": rating,
        "structure": {
            "score": round(structure_analysis["structure_score"], 1),
            "details": structure_analysis,
            "feedback": structure_feedback
        },
        "time_utilization": {
            "score": round(time_analysis["time_utilization_score"], 1),
            "details": time_analysis,
            "feedback": time_feedback
        }
    }
