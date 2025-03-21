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

def analyze_topic_relevance(topic, transcription):
    """
    Analyze how well the speech content aligns with the provided topic.
    
    Parameters:
    topic (str): The stated topic of the speech
    transcription (str): The transcribed speech text
    
    Returns:
    dict: Analysis of topic relevance with scores
    """
    try:
        # Make sure NLTK resources are available
        download_nltk_data()
        
        # Return default values for empty inputs
        if not topic or not transcription:
            return {
                "relevance_score": 75.0,
                "keyword_match_score": 0.0,
                "semantic_similarity_score": 0.0,
                "keyword_distribution_score": 0.0,
                "topic_keywords": [],
                "matched_keywords": []
            }
        
        # Clean and preprocess text
        try:
            stop_words = set(stopwords.words('english'))
        except LookupError:
            # If stopwords aren't available, use a simple fallback
            print("Warning: NLTK stopwords not available, using fallback")
            stop_words = {'a', 'an', 'the', 'and', 'or', 'but', 'in', 'on', 'at', 'to', 'for', 'with', 'by'}
        
        try:
            lemmatizer = WordNetLemmatizer()
        except LookupError:
            # If WordNet isn't available, just use identity function
            print("Warning: NLTK WordNet not available, using identity function")
            class IdentityLemmatizer:
                def lemmatize(self, word):
                    return word
            lemmatizer = IdentityLemmatizer()
        
        def clean_text(text):
            try:
                # Remove punctuation and convert to lowercase
                text = text.lower()
                text = re.sub(r'\[\d+\.\d+ second pause\]', '', text)  # Remove pause markers
                text = text.translate(str.maketrans('', '', string.punctuation))
                # Tokenize and remove stopwords
                words = word_tokenize(text)
                words = [word for word in words if word not in stop_words and len(word) > 2]
                # Lemmatize words
                words = [lemmatizer.lemmatize(word) for word in words]
                return words
            except Exception as e:
                print(f"Error in clean_text: {str(e)}")
                # Return simple word split as fallback
                text = text.lower()
                text = re.sub(r'[^\w\s]', '', text)
                return [word for word in text.split() if word not in stop_words and len(word) > 2]
        
        # Extract topic keywords
        topic_words = clean_text(topic)
        
        # Get POS tags to identify key nouns and verbs in topic
        try:
            topic_pos_tags = nltk.pos_tag(topic_words)
            
            # Extract important words from topic (nouns, verbs, adjectives)
            important_tags = {'NN', 'NNS', 'NNP', 'NNPS', 'VB', 'VBD', 'VBG', 'VBN', 'VBP', 'VBZ', 'JJ', 'JJR', 'JJS'}
            key_topic_words = [word for word, tag in topic_pos_tags if tag[:2] in important_tags]
        except Exception as e:
            print(f"Error in POS tagging: {str(e)}")
            # If POS tagging fails, just use all topic words
            key_topic_words = topic_words
        
        # If we couldn't extract any key words, use all topic words
        if not key_topic_words and topic_words:
            key_topic_words = topic_words
        
        # Clean transcription
        transcript_words = clean_text(transcription)
        
        # Calculate keyword match score
        matched_keywords = []
        keyword_match_score = 0.0
        
        if key_topic_words:
            for keyword in key_topic_words:
                if keyword in transcript_words:
                    matched_keywords.append(keyword)
            
            keyword_match_score = (len(matched_keywords) / len(key_topic_words)) * 100 if key_topic_words else 0.0
        
        # Calculate keyword distribution score - this part was missing
        keyword_distribution_score = 0.0
        if matched_keywords:
            try:
                # Split transcript into segments (beginning, middle, end)
                sentences = sent_tokenize(transcription)
                total_sentences = len(sentences)
                
                if total_sentences < 3:
                    keyword_distribution_score = 50.0
                else:
                    beginning = ' '.join(sentences[:total_sentences//3])
                    middle = ' '.join(sentences[total_sentences//3:2*total_sentences//3])
                    end = ' '.join(sentences[2*total_sentences//3:])
                    
                    sections = [beginning, middle, end]
                    section_scores = []
                    
                    for section in sections:
                        section_words = clean_text(section)
                        section_matched = sum(1 for keyword in matched_keywords if keyword in section_words)
                        section_score = section_matched / len(matched_keywords) if matched_keywords else 0
                        section_scores.append(section_score)
                    
                    # If keywords appear in all sections, that's ideal
                    if all(score > 0 for score in section_scores):
                        keyword_distribution_score = 90.0 + 10.0 * min(section_scores) / max(max(section_scores), 0.001)
                    # If keywords appear in 2 of 3 sections, that's good
                    elif sum(score > 0 for score in section_scores) == 2:
                        keyword_distribution_score = 75.0
                    # If keywords only appear in 1 section, that's not ideal but okay
                    else:
                        keyword_distribution_score = 60.0
            except Exception as e:
                print(f"Error in keyword distribution analysis: {str(e)}")
                keyword_distribution_score = 50.0
        else:
            keyword_distribution_score = 50.0
        
        # TF-IDF implementation with proper error handling
        semantic_similarity_score = 0.0
        try:
            if topic and transcription and len(topic.split()) > 0 and len(transcription.split()) > 0:
                # Use TF-IDF vectorizer
                vectorizer = TfidfVectorizer(min_df=1, max_features=1000)
                
                # Handle very short inputs by adding placeholder content
                # This prevents TfidfVectorizer from failing on very short inputs
                safe_topic = topic
                safe_transcript = transcription
                
                # Make sure inputs are long enough for TF-IDF
                if len(topic.split()) < 3:
                    safe_topic = topic + " topic placeholder text for analysis"
                if len(transcription.split()) < 3:
                    safe_transcript = transcription + " transcript placeholder text for analysis"
                
                # Handle empty vocabulary error
                try:
                    tfidf_matrix = vectorizer.fit_transform([safe_topic, safe_transcript])
                    
                    # Calculate cosine similarity (will be between 0 and 1)
                    similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
                    
                    # Convert to a score out of 100
                    semantic_similarity_score = similarity * 100
                except ValueError as ve:
                    print(f"TF-IDF vectorization error: {ve}")
                    # Fallback to simple word overlap ratio if vectorization fails
                    topic_set = set(safe_topic.lower().split())
                    transcript_set = set(safe_transcript.lower().split())
                    
                    if topic_set and transcript_set:
                        overlap = len(topic_set.intersection(transcript_set))
                        semantic_similarity_score = (overlap / len(topic_set)) * 100
                    else:
                        semantic_similarity_score = 60.0  # Default when no meaningful comparison is possible
            else:
                print("Topic or transcription too short for TF-IDF analysis")
                semantic_similarity_score = 60.0
        except Exception as e:
            print(f"Error calculating semantic similarity: {e}")
            semantic_similarity_score = 60.0
        
        # The rest of the function remains the same
        # ...existing code...
        
        # Calculate overall relevance score with weighted components
        # 40% keyword match, 30% semantic similarity, 30% keyword distribution
        relevance_score = (
            keyword_match_score * 0.4 +
            semantic_similarity_score * 0.3 +
            keyword_distribution_score * 0.3
        )
        
        # Ensure score is within 0-100 range and provide a floor of 50 if any text is present
        relevance_score = max(50 if topic and transcription else 0, min(100, relevance_score))
        
        return {
            "relevance_score": round(relevance_score, 1),
            "keyword_match_score": round(keyword_match_score, 1),
            "semantic_similarity_score": round(semantic_similarity_score, 1),
            "keyword_distribution_score": round(keyword_distribution_score, 1),
            "topic_keywords": key_topic_words,
            "matched_keywords": matched_keywords
        }
    except Exception as e:
        print(f"Error in topic relevance analysis: {str(e)}")
        return {
            "relevance_score": 75.0,
            "keyword_match_score": 0.0,
            "semantic_similarity_score": 0.0,
            "keyword_distribution_score": 0.0,
            "topic_keywords": [],
            "matched_keywords": []
        }

def evaluate_speech_development(transcription, topic, actual_duration, expected_duration):
    """
    Evaluate the development of a speech based on structure, time utilization, and topic relevance.
    
    Parameters:
    transcription (str): The transcribed speech text
    topic (str): The topic of the speech
    actual_duration (int): Actual duration in seconds
    expected_duration (str): Expected duration string (e.g., "5–7 minutes")
    
    Returns:
    dict: Complete speech development evaluation
    """
    # Analyze structure
    structure_analysis = analyze_speech_structure(transcription)
    
    # Evaluate time utilization with structure information
    time_analysis = evaluate_time_utilization(actual_duration, expected_duration, structure_analysis)
    
    # Analyze topic relevance
    topic_analysis = analyze_topic_relevance(topic, transcription)
    topic_relevance = topic_analysis["relevance_score"]
    
    # Calculate overall development score with weights
    structure_weight = 0.5
    time_weight = 0.3
    relevance_weight = 0.2
    
    overall_score = (
        structure_analysis["structure_score"] * structure_weight +
        time_analysis["time_utilization_score"] * time_weight +
        topic_relevance * relevance_weight
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
        # Get the section with the most problematic proportion
        intro_percent = time_analysis["time_distribution"]["breakdown"]["introduction_percentage"]
        body_percent = time_analysis["time_distribution"]["breakdown"]["body_percentage"]
        conclusion_percent = time_analysis["time_distribution"]["breakdown"]["conclusion_percentage"]
        
        # Identify the most significant time distribution issue
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
        
        # If no significant issues and distribution quality is good or better, provide positive feedback
        if not time_feedback[1:] and time_analysis["time_distribution"]["quality"] in ["good", "very_good", "excellent"]:
            time_feedback.append("You allocated your time effectively between introduction, body, and conclusion.")
    
    # Generate topic relevance feedback
    topic_feedback = []
    
    if topic_analysis["keyword_match_score"] < 60:
        if topic_analysis["topic_keywords"]:
            topic_feedback.append(f"Your speech didn't include many keywords related to '{topic}'. Try to incorporate terms like: {', '.join(topic_analysis['topic_keywords'][:3])}.")
        else:
            topic_feedback.append(f"Your speech seemed to stray from the topic '{topic}'. Try to keep your content more focused on the main subject.")
    
    if topic_analysis["keyword_distribution_score"] < 70:
        topic_feedback.append("Reference your topic throughout the speech, not just in one section.")
    
    if topic_analysis["relevance_score"] >= 85:
        topic_feedback.append(f"Excellent job staying on topic. Your speech clearly addressed '{topic}'.")
    elif topic_analysis["relevance_score"] >= 70:
        topic_feedback.append(f"Your speech generally stayed on topic. Consider making '{topic}' more central to your message.")
    
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
        },
        "topic_relevance": {
            "score": round(topic_relevance, 1),
            "details": topic_analysis,
            "feedback": topic_feedback,
            "topic": topic
        }
    }
