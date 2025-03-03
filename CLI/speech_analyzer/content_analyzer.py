import re
import spacy
from collections import Counter
from nltk.tokenize import word_tokenize

# Load language model
nlp = spacy.load('en_core_web_sm')

def filler_word_detection(transcription):
    if isinstance(transcription, dict):
        transcription = transcription.get('text', '')
    filler_count = 0
    filler_words = ["um", "uh", "ah", "ugh", "er", "hmm", "like", "you know", "so", "actually", "basically"]
    for word in filler_words:
        filler_count += len(re.findall(r'\b' + re.escape(word) + r'\b', transcription.lower()))
    return filler_count

def analyze_grammar_and_word_selection(text):
    if isinstance(text, dict):
        text = text.get('text', '')

    try:
        clean_text = re.sub(r'\[\d+\.\d+ second pause\]', '', text)

        doc = nlp(clean_text)

        grammar_issues = 0
        subject_verb_issues = 0
        preposition_issues = 0

        sentences = list(doc.sents)
        total_sentences = len(sentences)

        for sent in sentences:
            subjects = [token for token in sent if "subj" in token.dep_]
            verbs = [token for token in sent if token.pos_ == "VERB"]

            if subjects and verbs:
                for subj in subjects:
                    for verb in verbs:
                        if subj.is_ancestor(verb) and abs(subj.i - verb.i) > 5:
                            subject_verb_issues += 1

            for token in sent:
                if token.dep_ == "prep" and token.head.pos_ in ["VERB", "NOUN"]:
                    if len([child for child in token.children]) == 0:
                        preposition_issues += 1

        grammar_issues = subject_verb_issues + preposition_issues

        words = [token.text.lower() for token in doc if token.is_alpha and not token.is_stop]
        total_words = len(words)

        if total_words > 0:
            unique_words = len(set(words))
            lexical_diversity = unique_words / total_words
        else:
            lexical_diversity = 0

        word_counter = Counter(words)
        repeated_words = [word for word, count in word_counter.items() if count > 3]

        advanced_vocab_count = 0
        basic_words = set(["good", "bad", "nice", "thing", "stuff", "big", "small", "very", "really",
                           "like", "said", "went", "got", "put", "took", "made", "did", "get", "know"])

        for word in set(words):
            if len(word) > 7 and word not in basic_words:
                advanced_vocab_count += 1

        grammar_score = 0
        word_selection_score = 0

        if total_sentences > 0:
            grammar_issue_ratio = grammar_issues / total_sentences
            if grammar_issue_ratio < 0.1:
                grammar_score = 50
            elif grammar_issue_ratio < 0.2:
                grammar_score = 40
            elif grammar_issue_ratio < 0.3:
                grammar_score = 30
            elif grammar_issue_ratio < 0.5:
                grammar_score = 20
            else:
                grammar_score = 10

        if lexical_diversity > 0.7:
            word_selection_score += 20
        elif lexical_diversity > 0.5:
            word_selection_score += 15
        elif lexical_diversity > 0.3:
            word_selection_score += 10
        else:
            word_selection_score += 5

        if total_words > 0:
            advanced_ratio = advanced_vocab_count / total_words
            if advanced_ratio > 0.2:
                word_selection_score += 20
            elif advanced_ratio > 0.1:
                word_selection_score += 15
            elif advanced_ratio > 0.05:
                word_selection_score += 10
            else:
                word_selection_score += 5

        if len(repeated_words) > 5:
            word_selection_score = max(0, word_selection_score - 10)
        elif len(repeated_words) > 3:
            word_selection_score = max(0, word_selection_score - 5)

        feedback = []

        if grammar_score >= 40:
            feedback.append("Grammar is generally correct and well structured.")
        elif grammar_score >= 20:
            feedback.append("Some grammatical issues detected. Pay attention to subject-verb agreement and preposition usage.")
        else:
            feedback.append("Several grammatical errors detected. Consider reviewing basic grammar rules.")

        if lexical_diversity > 0.5:
            feedback.append("Good vocabulary diversity and word choice.")
        else:
            feedback.append("Consider using a wider range of vocabulary to enhance your speech.")

        if len(repeated_words) > 3:
            feedback.append(f"Repetitive use of words detected: {', '.join(repeated_words[:3])}...")

        if advanced_vocab_count > 10:
            feedback.append("Excellent use of advanced vocabulary.")
        elif advanced_vocab_count > 5:
            feedback.append("Good use of complex words. Consider incorporating more advanced vocabulary.")
        else:
            feedback.append("Consider using more sophisticated vocabulary where appropriate.")

        combined_score = grammar_score + word_selection_score

        return {
            'grammar_score': grammar_score,
            'word_selection_score': word_selection_score,
            'combined_score': combined_score,
            'lexical_diversity': round(lexical_diversity, 2),
            'unique_words': len(set(words)) if words else 0,
            'repeated_words': repeated_words[:5],
            'advanced_vocab_count': advanced_vocab_count,
            'grammar_issues': grammar_issues,
            'feedback': feedback
        }

    except Exception as e:
        print(f"Error in grammar and word selection analysis: {e}")
        return None