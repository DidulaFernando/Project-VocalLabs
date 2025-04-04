from sentence_transformers import SentenceTransformer
import nltk
from nltk.tokenize import sent_tokenize, word_tokenize
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
from sklearn.feature_extraction.text import TfidfVectorizer
import numpy as np
from typing import List, Dict, Tuple
import spacy
import re

# Initialize models
sbert_model = SentenceTransformer('all-MiniLM-L6-v2')
nlp = spacy.load('en_core_web_sm')

def preprocess_text(text: str) -> str:
    """Clean and preprocess text for analysis."""
    # Tokenize and lemmatize
    lemmatizer = WordNetLemmatizer()
    stop_words = set(stopwords.words('english'))
    
    # Basic cleaning
    text = text.lower()
    
    # Tokenize and lemmatize
    words = word_tokenize(text)
    words = [lemmatizer.lemmatize(word) for word in words 
             if word.isalnum() and word not in stop_words]
    
    return ' '.join(words)

def compute_semantic_similarity(speech_text: str, topic: str) -> float:
    """Compute semantic similarity between speech and topic using SBERT."""
    # Encode texts
    speech_embedding = sbert_model.encode(speech_text)
    topic_embedding = sbert_model.encode(topic)
    
    # Calculate cosine similarity
    similarity = np.dot(speech_embedding, topic_embedding) / \
                (np.linalg.norm(speech_embedding) * np.linalg.norm(topic_embedding))
    
    return float(similarity)

def extract_keywords(text: str, n: int = 10) -> List[str]:
    """Extract top n keywords from text using TF-IDF."""
    vectorizer = TfidfVectorizer(max_features=n)
    tfidf_matrix = vectorizer.fit_transform([text])
    
    # Get feature names and scores
    feature_names = vectorizer.get_feature_names_out()
    scores = tfidf_matrix.toarray()[0]
    
    # Sort keywords by score
    keyword_scores = list(zip(feature_names, scores))
    keyword_scores.sort(key=lambda x: x[1], reverse=True)
    
    return [word for word, _ in keyword_scores[:n]]

def analyze_speech_structure(speech_text: str) -> Dict:
    """Analyze the structure and coherence of the speech."""
    sentences = sent_tokenize(speech_text)
    num_sentences = len(sentences)
    
    # More lenient section detection for shorter speeches
    if num_sentences < 3:
        intro_end = 1
        body_end = max(1, num_sentences - 1)
    else:
        intro_end = max(1, int(num_sentences * 0.2))
        body_end = int(num_sentences * 0.8)
    
    intro = ' '.join(sentences[:intro_end])
    body = ' '.join(sentences[intro_end:body_end])
    conclusion = ' '.join(sentences[body_end:])
    
    # Analyze coherence using spaCy
    doc = nlp(speech_text)
    
    # Calculate topic consistency based on main subjects and verbs
    main_subjects = []
    main_verbs = []
    for token in doc:
        if token.dep_ == 'nsubj':
            main_subjects.append(token.text.lower())
        elif token.pos_ == 'VERB':
            main_verbs.append(token.text.lower())
    
    # Calculate topic consistency
    topic_consistency = 0
    if main_subjects and main_verbs:
        unique_subjects = set(main_subjects)
        unique_verbs = set(main_verbs)
        subject_consistency = len([s for s in main_subjects if s in unique_subjects]) / len(main_subjects)
        verb_variety = len(unique_verbs) / len(main_verbs)
        topic_consistency = (subject_consistency + verb_variety) / 2
    
    return {
        'has_intro': bool(intro and len(intro.split()) >= 3),
        'has_body': bool(body and len(body.split()) >= 5),
        'has_conclusion': bool(conclusion and len(conclusion.split()) >= 3),
        'has_discourse_markers': _check_discourse_markers(speech_text),
        'topic_consistency': topic_consistency,
        'num_sentences': num_sentences,
        'sections': {
            'intro': intro,
            'body': body,
            'conclusion': conclusion
        }
    }

def _check_discourse_markers(text: str) -> float:
    """Check for discourse markers and return a score based on their usage."""
    discourse_markers = {
        'introduction': ['first', 'to begin', 'introduction', 'topic', 'discuss'],
        'transition': ['however', 'moreover', 'furthermore', 'additionally', 'therefore', 'consequently'],
        'conclusion': ['finally', 'in conclusion', 'to summarize', 'thus', 'in summary']
    }
    
    text_lower = text.lower()
    total_markers = 0
    for category, markers in discourse_markers.items():
        for marker in markers:
            if marker in text_lower:
                total_markers += 1
    
    # Return a normalized score (0-1)
    return min(1.0, total_markers / 5)  # Expecting at least 5 markers for full score

def evaluate_speech_effectiveness(speech_text: str, topic: str, expected_duration: str = "5-7 minutes", actual_duration_seconds: int = 0) -> Dict:
    """Main function to evaluate speech effectiveness."""
    # Input validation and logging
    if not speech_text or not topic:
        print("Warning: Empty speech text or topic")
        return {
            "total_score": 0,
            "relevance_score": 0,
            "purpose_score": 0,
            "details": {},
            "feedback": ["Invalid input: Speech or topic is empty"]
        }
    
    print(f"\nAnalyzing speech effectiveness:")
    print(f"Topic: {topic}")
    print(f"Expected Duration: {expected_duration}")
    print(f"Speech length: {len(speech_text)} characters")

    # Preprocess texts
    processed_speech = preprocess_text(speech_text)
    processed_topic = preprocess_text(topic)
    
    # Enhanced topic interpretation for creative speeches
    topic_variations = generate_topic_variations(topic)
    
    # Enhanced analysis components
    structure_analysis = analyze_speech_structure(speech_text)
    narrative_score = analyze_narrative_elements(speech_text)
    creative_elements = analyze_creative_elements(speech_text, topic)
    
    # Calculate enhanced relevance score with creative consideration
    base_relevance = compute_semantic_similarity(speech_text, topic)
    creative_relevance = max(
        compute_semantic_similarity(speech_text, variation)
        for variation in topic_variations
    )
    
    # Use the better of direct or creative relevance
    effective_relevance = max(base_relevance, creative_relevance)
    
    # Calculate purpose achievement
    purpose_data = calculate_purpose_achievement(
        speech_text,
        structure_analysis,
        narrative_score,
        creative_elements
    )
    
    # Scale scores properly (0-10)
    relevance_score = scale_relevance_score(effective_relevance, creative_elements)
    final_purpose_score = scale_purpose_score(purpose_data)
    
    # Calculate total score (0-20)
    total_score = relevance_score + final_purpose_score
    
    # Debug logging
    print(f"\nEffectiveness Scoring Details:")
    print(f"Base Relevance: {base_relevance:.2f}")
    print(f"Creative Relevance: {creative_relevance:.2f}")
    print(f"Final Relevance Score: {relevance_score:.2f}/10")
    print(f"Final Purpose Score: {final_purpose_score:.2f}/10")
    print(f"Total Score: {total_score:.2f}/20")
    
    return {
        'total_score': float(total_score),  # Ensure float type
        'relevance_score': float(relevance_score),  # Ensure float type
        'purpose_score': float(final_purpose_score),  # Ensure float type
        'details': {
            'narrative_elements': narrative_score,
            'creative_elements': creative_elements,
            'structure': structure_analysis
        },
        'feedback': generate_feedback(relevance_score, final_purpose_score, structure_analysis)
    }

def generate_topic_variations(topic: str) -> List[str]:
    """Generate variations of topic interpretation."""
    variations = [topic]
    
    # Add metaphorical interpretation
    variations.append(f"metaphor about {topic}")
    
    # Add story-based interpretation
    variations.append(f"story illustrating {topic}")
    
    # Add lesson-based interpretation
    variations.append(f"lesson about {topic}")
    
    # Add symbolic interpretation
    variations.append(f"symbolism of {topic}")
    
    return variations

def analyze_narrative_elements(speech_text: str) -> Dict:
    """Analyze storytelling and narrative elements."""
    narrative_elements = {
        'has_story': False,
        'has_characters': False,
        'has_metaphor': False,
        'has_lesson': False,
        'emotional_connection': 0.0
    }
    
    # Story detection
    story_markers = ['once', 'when i was', 'there was', 'story']
    narrative_elements['has_story'] = any(marker in speech_text.lower() for marker in story_markers)
    
    # Character detection
    character_patterns = r'\b(he|she|they|their|someone|people|person)\b'
    narrative_elements['has_characters'] = bool(re.findall(character_patterns, speech_text.lower()))
    
    # Metaphor detection
    metaphor_markers = ['like', 'as if', 'symbolizes', 'represents', 'means']
    narrative_elements['has_metaphor'] = any(marker in speech_text.lower() for marker in metaphor_markers)
    
    # Lesson/moral detection
    lesson_markers = ['realize', 'learned', 'understand', 'truth', 'lesson']
    narrative_elements['has_lesson'] = any(marker in speech_text.lower() for marker in lesson_markers)
    
    # Emotional connection scoring
    emotional_words = ['feel', 'felt', 'heart', 'love', 'fear', 'hope', 'dream', 'scared']
    emotional_count = sum(speech_text.lower().count(word) for word in emotional_words)
    narrative_elements['emotional_connection'] = min(1.0, emotional_count / 10)
    
    return narrative_elements

def analyze_creative_elements(speech_text: str, topic: str) -> Dict:
    """Analyze creative and artistic elements."""
    return {
        'metaphor_strength': detect_metaphor_strength(speech_text),
        'artistic_references': detect_artistic_references(speech_text),
        'creative_structure': analyze_creative_structure(speech_text),
        'topic_creativity': measure_topic_creativity(speech_text, topic)
    }

def calculate_purpose_achievement(speech_text: str, structure_analysis: Dict, narrative_score: Dict, creative_elements: Dict) -> Dict:
    """Calculate purpose achievement score based on various analyses."""
    base_score = 0.5 * structure_analysis['topic_consistency'] + 0.3 * narrative_score['emotional_connection'] + 0.2 * creative_elements['creative_structure']
    
    return {
        'base_score': base_score,
        'narrative_quality': narrative_score['emotional_connection'],
        'audience_engagement': structure_analysis['has_discourse_markers'],
        'message_clarity': structure_analysis['has_intro'] and structure_analysis['has_conclusion']
    }

def scale_relevance_score(relevance: float, creative_elements: Dict) -> float:
    """Scale relevance score with creative consideration."""
    # Start with a higher base multiplier
    base_score = relevance * 8  # Changed from 7 to 8
    
    # Calculate creative bonus with adjusted weights
    creative_bonus = sum([
        creative_elements.get('metaphor_strength', 0) * 2.0,  # Increased weight
        creative_elements.get('artistic_references', 0) * 1.5,
        creative_elements.get('creative_structure', 0) * 1.5,
        creative_elements.get('topic_creativity', 0) * 2.0    # Increased weight
    ])
    
    # Ensure minimum score of 4.0 for complete speeches with any relevance
    raw_score = base_score + creative_bonus
    if raw_score > 0:
        final_score = max(6.0, min(10.0, raw_score))  # Increased minimum score
    else:
        final_score = 4.0  # Default minimum score
    
    return final_score

def scale_purpose_score(purpose_data: Dict) -> float:
    """Scale purpose achievement score."""
    # Start with a higher base multiplier
    base_score = purpose_data.get('base_score', 0) * 7  # Changed from 6 to 7
    
    # Calculate achievement bonus with adjusted weights
    achievement_bonus = sum([
        purpose_data.get('narrative_quality', 0) * 2.5,      # Increased weight
        purpose_data.get('audience_engagement', 0) * 2.0,    # Increased weight
        purpose_data.get('message_clarity', 0) * 2.0        # Increased weight
    ])
    
    # Ensure minimum score of 4.0 for complete speeches
    raw_score = base_score + achievement_bonus
    if raw_score > 0:
        final_score = max(6.0, min(10.0, raw_score))  # Increased minimum score
    else:
        final_score = 4.0  # Default minimum score
    
    return final_score

def detect_metaphor_strength(text: str) -> float:
    """Detect and score metaphorical language."""
    metaphor_markers = [
        'like', 'as', 'symbolizes', 'represents', 'means',
        'metaphor', 'comparison', 'similar to', 'just as',
        'reflects', 'mirrors', 'parallels'
    ]
    
    literary_devices = [
        'rose', 'journey', 'path', 'light', 'darkness',
        'heart', 'bridge', 'door', 'window', 'book'
    ]
    
    metaphor_count = sum(text.lower().count(marker) for marker in metaphor_markers)
    literary_count = sum(text.lower().count(device) for device in literary_devices)
    
    # Calculate score (0-1)
    score = min(1.0, (metaphor_count * 0.2) + (literary_count * 0.15))
    return score

def detect_artistic_references(text: str) -> float:
    """Detect and score artistic/literary references."""
    artistic_elements = [
        'book', 'story', 'author', 'art', 'music',
        'poem', 'novel', 'character', 'literature',
        'culture', 'creative', 'artistic'
    ]
    
    reference_count = sum(text.lower().count(element) for element in artistic_elements)
    return min(1.0, reference_count * 0.2)

def analyze_creative_structure(text: str) -> float:
    """Analyze creative speech structure."""
    # Check for storytelling elements
    story_elements = [
        'once', 'when', 'story', 'then', 'finally',
        'first', 'next', 'later', 'eventually',
        'in the end', 'learned', 'realized'
    ]
    
    # Count story elements
    element_count = sum(text.lower().count(element) for element in story_elements)
    
    # Check for narrative flow
    sentences = sent_tokenize(text)
    has_intro = any('introduce' in s.lower() or 'begin' in s.lower() for s in sentences[:2])
    has_conclusion = any('conclusion' in s.lower() or 'finally' in s.lower() for s in sentences[-2:])
    
    # Calculate score (0-1)
    structure_score = min(1.0, (element_count * 0.15) + (has_intro * 0.3) + (has_conclusion * 0.3))
    return structure_score

def measure_topic_creativity(text: str, topic: str) -> float:
    """Measure creative interpretation of topic."""
    # Look for creative elements related to the topic
    topic_words = set(word_tokenize(topic.lower()))
    text_words = set(word_tokenize(text.lower()))
    
    # Direct topic mentions
    direct_mentions = len(topic_words.intersection(text_words))
    
    # Look for creative interpretations
    interpretive_markers = [
        'meaning', 'represents', 'symbolizes', 'teaches',
        'shows', 'illustrates', 'demonstrates', 'reflects'
    ]
    
    creative_count = sum(text.lower().count(marker) for marker in interpretive_markers)
    
    # Calculate score (0-1) - reward both direct and creative usage
    score = min(1.0, (direct_mentions * 0.2) + (creative_count * 0.25))
    return score

def generate_feedback(relevance_score: float, purpose_score: float, structure: Dict) -> List[str]:
    """Generate specific feedback based on the analysis results."""
    feedback = []
    
    # Relevance feedback
    if relevance_score < 5:
        feedback.append("The speech appears to deviate significantly from the main topic. Try to stay more focused on the subject matter.")
    elif relevance_score < 7:
        feedback.append("The speech somewhat relates to the topic but could be more focused. Consider tightening the connection to the main theme.")
    else:
        feedback.append("Good job maintaining relevance to the topic throughout the speech.")
    
    # Structure feedback
    if not structure['has_intro']:
        feedback.append("The speech lacks a clear introduction. Consider adding an opening that sets up your main points.")
    if not structure['has_conclusion']:
        feedback.append("The speech needs a stronger conclusion to reinforce your message.")
    if not structure['has_discourse_markers']:
        feedback.append("Try using transition phrases to improve flow between ideas.")
    
    # Purpose achievement feedback
    if purpose_score < 5:
        feedback.append("The speech structure needs significant improvement. Focus on organizing your thoughts more clearly.")
    elif purpose_score < 7:
        feedback.append("The speech structure is decent but could be more organized. Consider using a clearer beginning-middle-end format.")
    else:
        feedback.append("Well-structured speech with good organization of ideas.")
    
    return feedback
