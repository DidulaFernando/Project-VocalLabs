import numpy as np
import spacy
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import re
from nltk.corpus import stopwords
from collections import Counter
import nltk
from nltk.tokenize import word_tokenize
import traceback

# Try to load sentence-transformers for better semantic similarity
# Falls back to simpler methods if not available
try:
    from sentence_transformers import SentenceTransformer, util
    model = SentenceTransformer('all-MiniLM-L6-v2')
    TRANSFORMER_AVAILABLE = True
except ImportError:
    TRANSFORMER_AVAILABLE = False
    print("sentence-transformers not available, using fallback similarity methods")

# Load spaCy model
try:
    nlp = spacy.load('en_core_web_sm')
except:
    # If model isn't available, try downloading it
    import subprocess
    subprocess.run(["python", "-m", "spacy", "download", "en_core_web_sm"])
    nlp = spacy.load('en_core_web_sm')

# Download NLTK resources if needed
try:
    nltk.data.find('tokenizers/punkt')
    nltk.data.find('corpora/stopwords')
except LookupError:
    nltk.download('punkt')
    nltk.download('stopwords')

def preprocess_text(text):
    """Clean and preprocess text for analysis"""
    if isinstance(text, dict):
        text = text.get('text', '')

    # Remove pause markers
    text = re.sub(r'\[\d+\.\d+ second pause\]', '', text)

    # Remove filler words
    text = re.sub(r'\b(um|uh|ah|er|hmm)\b', '', text.lower())

    # Remove extra whitespace
    text = re.sub(r'\s+', ' ', text).strip()

    return text

def extract_key_topics(text, n=10):
    """Extract key topics/terms from the speech"""
    doc = nlp(text)

    # Get important noun phrases and named entities
    key_phrases = []

    # Add noun chunks (noun phrases)
    for chunk in doc.noun_chunks:
        if not all(token.is_stop for token in chunk):
            key_phrases.append(chunk.text.lower())

    # Add named entities
    for ent in doc.ents:
        key_phrases.append(ent.text)

    # Get most common content words if we don't have enough phrases
    if len(key_phrases) < n:
        stop_words = set(stopwords.words('english'))
        words = [token.text.lower() for token in doc
                 if token.is_alpha and token.text.lower() not in stop_words
                 and len(token.text) > 2]

        word_freq = Counter(words)
        common_words = [word for word, _ in word_freq.most_common(n)]
        key_phrases.extend(common_words)

    # Return unique topics
    return list(set(key_phrases))[:n]

def calculate_similarity_transformer(text1, text2):
    """Calculate semantic similarity using sentence transformers"""
    if not TRANSFORMER_AVAILABLE:
        return None

    try:
        # Generate embeddings
        embedding1 = model.encode(text1, convert_to_tensor=True)
        embedding2 = model.encode(text2, convert_to_tensor=True)

        # Calculate cosine similarity
        similarity = util.pytorch_cos_sim(embedding1, embedding2).item()
        return similarity
    except Exception as e:
        print(f"Error in transformer similarity calculation: {e}")
        return None

def calculate_similarity_tfidf(text1, text2):
    """Calculate similarity using TF-IDF vectors"""
    try:
        vectorizer = TfidfVectorizer()
        tfidf_matrix = vectorizer.fit_transform([text1, text2])
        similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])[0][0]
        return similarity
    except Exception as e:
        print(f"Error in TF-IDF similarity calculation: {e}")
        return 0.5  # Default to neutral similarity

def generate_topic_feedback(score, key_speech_topics, topic):
    """Generate feedback based on relevance score and topics"""
    feedback = []

    if score >= 0.9:
        feedback.append(f"Excellent topic relevance! Your speech is strongly focused on '{topic}'.")
    elif score >= 0.75:
        feedback.append(f"Good topic relevance. Your speech stays on topic with '{topic}'.")
    elif score >= 0.6:
        feedback.append(f"Moderate topic relevance. Your speech somewhat relates to '{topic}' but could be more focused.")
    elif score >= 0.4:
        feedback.append(f"Limited topic relevance. Your speech touches on '{topic}' but frequently deviates from it.")
    else:
        feedback.append(f"Poor topic relevance. Your speech doesn't adequately address '{topic}'.")

    # Add recommendations based on score
    if score < 0.7:
        feedback.append("Try to make stronger connections to the main topic throughout your speech.")

    # Add topic-specific feedback
    if key_speech_topics and len(key_speech_topics) > 0:
        if score < 0.5:
            feedback.append(f"Your speech focused more on {', '.join(key_speech_topics[:3])} than the assigned topic.")
        elif score >= 0.7:
            feedback.append(f"You effectively covered key aspects: {', '.join(key_speech_topics[:3])}.")

    return feedback

def analyze_topic_relevance(transcription_text, topic):
    """Analyze how relevant the speech is to a given topic"""
    try:
        # Preprocessing
        speech_text = preprocess_text(transcription_text)
        topic_text = preprocess_text(topic)

        if not speech_text or not topic_text:
            return {
                'topic_relevance_score': 50,
                'similarity': 0.5,
                'key_speech_topics': [],
                'feedback': ["Unable to analyze topic relevance due to empty text."]
            }

        # Extract key topics from speech
        key_speech_topics = extract_key_topics(speech_text)

        # Calculate semantic similarity between speech and topic
        transformer_similarity = calculate_similarity_transformer(speech_text, topic_text)

        if transformer_similarity is not None:
            similarity = transformer_similarity
        else:
            similarity = calculate_similarity_tfidf(speech_text, topic_text)

        # Ensure similarity is between 0 and 1
        similarity = max(0, min(1, similarity))

        # Convert to a 0-100 score
        relevance_score = int(similarity * 100)

        # Generate feedback
        feedback = generate_topic_feedback(similarity, key_speech_topics, topic)

        return {
            'topic_relevance_score': relevance_score,
            'similarity': round(similarity, 2),
            'key_speech_topics': key_speech_topics,
            'feedback': feedback
        }

    except Exception as e:
        print(f"Error analyzing topic relevance: {e}")
        traceback.print_exc()
        return {
            'topic_relevance_score': 50,
            'similarity': 0.5,
            'key_speech_topics': [],
            'feedback': ["Unable to fully analyze topic relevance. Please ensure both speech and topic are clearly articulated."]
        }