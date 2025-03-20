import nltk
import spacy
from nltk.tokenize import word_tokenize

# Load language model
nlp = spacy.load('en_core_web_sm')

def analyze_speech_effectiveness(text):
    if isinstance(text, dict):
        text = text.get('text', '')
    try:
        purpose_indicators = [
            "purpose", "goal", "aim", "objective", "today", "discuss",
            "explain", "demonstrate", "show", "present", "introduce"
        ]

        conclusion_indicators = [
            "conclusion", "finally", "in summary", "to sum up", "therefore",
            "thus", "consequently", "in closing", "lastly"
        ]

        words = word_tokenize(text.lower())
        first_50_words = ' '.join(words[:50])

        has_clear_purpose = any(indicator in first_50_words for indicator in purpose_indicators)

        last_50_words = ' '.join(words[-50:])
        has_conclusion = any(indicator in last_50_words for indicator in conclusion_indicators)

        sentences = nltk.sent_tokenize(text)
        if sentences:
            avg_sentence_length = sum(len(word_tokenize(sentence)) for sentence in sentences) / len(sentences)
        else:
            avg_sentence_length = 0

        effectiveness_score = 0
        feedback = []

        if has_clear_purpose:
            effectiveness_score += 30
            feedback.append("Clear purpose statement identified in the introduction.")
        else:
            feedback.append("Consider adding a clear purpose statement at the beginning.")

        if 10 <= avg_sentence_length <= 20:
            effectiveness_score += 20
            feedback.append("Good sentence length variation for clarity.")
        else:
            feedback.append("Consider varying sentence lengths for better flow.")

        if has_conclusion:
            effectiveness_score += 20
            feedback.append("Clear conclusion identified.")
        else:
            feedback.append("Consider adding a strong concluding statement.")

        transition_words = ["however", "moreover", "furthermore", "additionally", "therefore"]
        transition_count = sum(1 for word in words if word.lower() in transition_words)

        if transition_count >= 3:
            effectiveness_score += 30
            feedback.append("Good use of transition words for coherence.")
        else:
            feedback.append("Consider using more transition words to improve flow.")

        return {
            'effectiveness_score': effectiveness_score,
            'purpose_clarity': has_clear_purpose,
            'has_conclusion': has_conclusion,
            'avg_sentence_length': round(avg_sentence_length, 2),
            'feedback': feedback
        }

    except Exception as e:
        print(f"Error in speech effectiveness analysis: {e}")
        return None

def analyze_speech_structure(text):
    if isinstance(text, dict):
        text = text.get('text', '')
    try:
        doc = nlp(text)
        sentences = list(doc.sents)
        num_sentences = len(sentences)
        if num_sentences > 0:
            sentence_lengths = [len(sentence) for sentence in sentences]
            avg_sentence_length = sum(sentence_lengths) / num_sentences
        else:
            avg_sentence_length = 0

        paragraphs = [sent.text for sent in doc.sents if sent.text.strip()]

        transitions = ["however", "moreover", "thus", "therefore", "in addition"]
        transition_count = sum(1 for token in doc if token.text.lower() in transitions)

        introduction_keywords = ["introduction", "begin", "start"]
        conclusion_keywords = ["conclusion", "end", "summary"]
        introduction_present = any(keyword in text.lower() for keyword in introduction_keywords)
        conclusion_present = any(keyword in text.lower() for keyword in conclusion_keywords)

        structure_score = 0
        structure_feedback = []

        if introduction_present:
            structure_score += 30
            structure_feedback.append("Clear introduction detected.")
        else:
            structure_feedback.append("Consider adding a clear introduction.")

        if conclusion_present:
            structure_score += 30
            structure_feedback.append("Clear conclusion detected.")
        else:
            structure_feedback.append("Consider adding a clear conclusion.")

        if transition_count >= 3:
            structure_score += 20
            structure_feedback.append("Effective use of transitions detected.")
        else:
            structure_feedback.append("Consider adding more transitions for coherence.")

        return {
            'structure_score': structure_score,
            'avg_sentence_length': round(avg_sentence_length, 2),
            'num_paragraphs': len(paragraphs),
            'feedback': structure_feedback
        }

    except Exception as e:
        print(f"Error in speech structure analysis: {e}")
        return None