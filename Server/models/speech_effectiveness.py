from sentence_transformers import SentenceTransformer
import nltk
from nltk.tokenize import sent_tokenize, word_tokenize
from nltk.corpus import stopwords
from nltk.stem import WordNetLemmatizer
from sklearn.feature_extraction.text import TfidfVectorizer
import numpy as np
from typing import List, Dict, Tuple
import spacy

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

def evaluate_speech_effectiveness(speech_text: str, topic: str) -> Dict:
    """
    Main function to evaluate speech effectiveness based on topic relevance
    and achievement of purpose.
    """
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
    print(f"Speech length: {len(speech_text)} characters")

    # Preprocess texts
    processed_speech = preprocess_text(speech_text)
    processed_topic = preprocess_text(topic)
    
    # 1. Clear Purpose & Relevance (10 points)
    semantic_similarity = compute_semantic_similarity(processed_speech, processed_topic)
    print(f"Semantic similarity score: {semantic_similarity}")
    
    speech_keywords = set(extract_keywords(processed_speech))
    topic_keywords = set(extract_keywords(processed_topic))
    keyword_overlap = len(speech_keywords.intersection(topic_keywords)) / max(len(topic_keywords), 1)
    print(f"Keyword overlap score: {keyword_overlap}")
    
    # Calculate relevance score with adjusted weights
    relevance_score = (semantic_similarity * 6) + (keyword_overlap * 4)
    relevance_score = max(0, min(10, relevance_score * 10))  # Scale to 0-10
    
    # 2. Achievement of Purpose (10 points)
    structure_analysis = analyze_speech_structure(speech_text)
    
    # Calculate purpose score based on structure and topic relevance
    purpose_components = {
        'structure': 0,
        'coherence': 0,
        'topic_alignment': 0
    }
    
    # Structure score (4 points)
    if structure_analysis['has_intro']:
        purpose_components['structure'] += 1
    if structure_analysis['has_body']:
        purpose_components['structure'] += 2
    if structure_analysis['has_conclusion']:
        purpose_components['structure'] += 1
    
    # Coherence score (3 points)
    discourse_marker_score = _check_discourse_markers(speech_text)
    purpose_components['coherence'] = discourse_marker_score * 3
    
    # Topic alignment score (3 points)
    # This ensures achievement of purpose is tied to topic relevance
    topic_alignment = (semantic_similarity * 0.7 + keyword_overlap * 0.3) * 3
    purpose_components['topic_alignment'] = topic_alignment
    
    # Calculate final purpose score
    purpose_score = sum(purpose_components.values())
    purpose_score = max(0, min(10, purpose_score))  # Ensure it's between 0-10
    
    print(f"\nPurpose Score Components:")
    for component, score in purpose_components.items():
        print(f"{component}: {score:.2f}")
    
    print(f"\nFinal scores:")
    print(f"Relevance score: {relevance_score}/10")
    print(f"Purpose score: {purpose_score}/10")
    
    return {
        'total_score': round(relevance_score + purpose_score, 2),
        'relevance_score': round(relevance_score, 2),
        'purpose_score': round(purpose_score, 2),
        'details': {
            'semantic_similarity': round(semantic_similarity, 3),
            'keyword_overlap': round(keyword_overlap, 3),
            'speech_keywords': list(speech_keywords),
            'topic_keywords': list(topic_keywords),
            'structure_analysis': structure_analysis,
            'purpose_components': {k: round(v, 2) for k, v in purpose_components.items()}
        },
        'feedback': generate_feedback(relevance_score, purpose_score, structure_analysis)
    }

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
