import whisper
import torch
import spacy
import re

from .transcription import transcribe_audio, process_transcription
from .time_analysis import neutralize_time_durations, get_audio_duration
from .structure_analyzer import analyze_speech_effectiveness, analyze_speech_structure
from .content_analyzer import filler_word_detection, analyze_grammar_and_word_selection
from .pronunciation import analyze_pronunciation_quality
from .audio_features import analyze_pitch_and_volume
from .emphasis_analyzer import analyze_emphasis
from .topic_relevance import analyze_topic_relevance
from .evaluator import SpeechEvaluator

# Load language model
nlp = spacy.load('en_core_web_sm')

class SpeechAnalyzer:

    def __init__(self, model_name="medium", audio_path=r"E:\IIT\Project-VocalLabs\CLI\Technology Tools for Leaders.wav", topic=None):
        self.model = whisper.load_model(model_name)
        self.audio_path = audio_path
        self.topic = topic
        self.transcription_with_pauses = []
        self.number_of_pauses = 0
        self.device = 0 if torch.cuda.is_available() else -1
        self.evaluator = SpeechEvaluator()
        print("SpeechAnalyzer initialized.")

    def transcribe_audio(self):
        return transcribe_audio(self.model, self.audio_path)

    def process_transcription(self, result):
        self.transcription_with_pauses, self.number_of_pauses = process_transcription(result)

    def get_audio_duration(self):
        return get_audio_duration(self.audio_path)

    def neutralize_time_durations(self, transcription_result):
        return neutralize_time_durations(self.audio_path, self.transcription_with_pauses, transcription_result, self.get_audio_duration())

    def filler_word_detection(self, transcription):
        return filler_word_detection(transcription)

    def analyze_speech_effectiveness(self, text):
        return analyze_speech_effectiveness(text)

    def analyze_speech_structure(self, text):
        return analyze_speech_structure(text)

    def analyze_grammar_and_word_selection(self, text):
        return analyze_grammar_and_word_selection(text)

    def analyze_pronunciation_quality(self, audio_data=None, transcription=None):
        audio_path = audio_data if audio_data is not None else self.audio_path
        text = transcription if transcription is not None else self.transcription_with_pauses
        return analyze_pronunciation_quality(audio_path, text, self.model)

    def analyze_pitch_and_volume(self, audio_data=None, gender='auto'):
        audio_path = audio_data if audio_data is not None else self.audio_path
        return analyze_pitch_and_volume(audio_path, gender=gender)

    def analyze_emphasis(self, audio_data=None, transcription_result=None, transcript_text=None):
        """Analyze emphasis in speech"""
        audio_path = audio_data if audio_data is not None else self.audio_path
        result = transcription_result if transcription_result is not None else self.transcribe_audio()
        text = transcript_text if transcript_text is not None else self.transcription_with_pauses
        return analyze_emphasis(audio_path, result, text)

    def analyze_topic_relevance(self, transcription_text=None, topic=None):
        """Analyze how relevant the speech is to a given topic"""
        text = transcription_text if transcription_text is not None else self.transcription_with_pauses
        speech_topic = topic if topic is not None else self.topic

        if not speech_topic:
            return None

        return analyze_topic_relevance(text, speech_topic)

    def print_analysis(self, transcription_result):
        """Perform full analysis and print results"""
        # Print transcription info
        print("\nTranscription with pauses:\n")
        print(self.transcription_with_pauses)
        print("\nNumber of pauses detected:", self.number_of_pauses)
        filler_count = self.filler_word_detection(transcription_result)
        print("\nNumber of filler words detected:", filler_count)

        # Run all analyses
        time_results = self.neutralize_time_durations(transcription_result)
        effectiveness_results = self.analyze_speech_effectiveness(transcription_result)
        structure_results = self.analyze_speech_structure(transcription_result)
        grammar_results = self.analyze_grammar_and_word_selection(transcription_result)
        pronunciation_results = self.analyze_pronunciation_quality(self.audio_path, transcription_result)
        pitch_volume_results = self.analyze_pitch_and_volume(self.audio_path)
        emphasis_results = self.analyze_emphasis(self.audio_path, transcription_result, self.transcription_with_pauses)

        # Run topic relevance analysis if a topic is provided
        topic_relevance_results = None
        if self.topic:
            topic_relevance_results = self.analyze_topic_relevance(transcription_result, self.topic)

        # Print time analysis results
        self._print_time_analysis(time_results)

        # Print effectiveness analysis results
        self._print_effectiveness_analysis(effectiveness_results)

        # Print structure analysis results
        self._print_structure_analysis(structure_results)

        # Print grammar analysis results
        self._print_grammar_analysis(grammar_results)

        # Print pronunciation analysis results
        self._print_pronunciation_analysis(pronunciation_results)

        # Print pitch and volume analysis results
        self._print_pitch_analysis(pitch_volume_results)

        # Print emphasis analysis results
        self._print_emphasis_analysis(emphasis_results)

        # Print topic relevance results if available
        if topic_relevance_results:
            self._print_topic_relevance(topic_relevance_results)

        # Calculate final score and generate improvement suggestions
        final_score_data = self.evaluator.calculate_final_score(
            effectiveness_results, structure_results, grammar_results,
            pronunciation_results, pitch_volume_results, emphasis_results,
            topic_relevance_results
        )

        improvement_suggestions = self.evaluator.generate_improvement_suggestions(
            final_score_data, effectiveness_results, structure_results,
            grammar_results, pronunciation_results, pitch_volume_results,
            time_results, self.number_of_pauses, emphasis_results,
            topic_relevance_results
        )

        # Print final evaluation
        print(self.evaluator.format_evaluation_output(final_score_data))

        # Print improvement suggestions
        print("\nImprovement Suggestions:")
        for suggestion in improvement_suggestions:
            print(f"  - {suggestion}")
        print("="*50)

    def _print_time_analysis(self, time_results):
        """Print time analysis section"""
        if time_results:
            print("\n=== Time Duration Analysis ===")
            print(f"Original audio duration: {time_results['original_duration']:.2f} seconds")
            print(f"Total pause time: {time_results['pause_time']:.2f} seconds")
            print(f"Neutralized speaking time: {time_results['neutralized_duration']:.2f} seconds")
            print(f"Word count: {time_results['word_count']} words")
            print(f"Speaking rate: {time_results['speaking_rate']} words per second")

    def _print_effectiveness_analysis(self, effectiveness_results):
        """Print effectiveness analysis section"""
        if effectiveness_results:
            print("\n=== Speech Effectiveness Analysis ===")
            print(f"Overall effectiveness score: {effectiveness_results['effectiveness_score']}/100")
            print(f"Clear purpose identified: {'Yes' if effectiveness_results['purpose_clarity'] else 'No'}")
            print(f"Conclusion present: {'Yes' if effectiveness_results['has_conclusion'] else 'No'}")
            print(f"Average sentence length: {effectiveness_results['avg_sentence_length']} words")
            print("\nFeedback:")
            for feedback in effectiveness_results['feedback']:
                print(f"- {feedback}")

    def _print_structure_analysis(self, structure_results):
        """Print structure analysis section"""
        if structure_results:
            print("\n=== Speech Structure Analysis ===")
            print(f"Overall structure score: {structure_results['structure_score']}/100")
            print(f"Average sentence length: {structure_results['avg_sentence_length']} words")
            print(f"Number of paragraphs: {structure_results['num_paragraphs']}")
            print("\nFeedback:")
            for feedback in structure_results['feedback']:
                print(f"- {feedback}")

    def _print_grammar_analysis(self, grammar_results):
        """Print grammar and word selection analysis section"""
        if grammar_results:
            print("\n=== Grammar and Word Selection Analysis ===")
            print(f"Grammar score: {grammar_results['grammar_score']}/50")
            print(f"Word selection score: {grammar_results['word_selection_score']}/50")
            print(f"Combined score: {grammar_results['combined_score']}/100")
            print(f"Lexical diversity: {grammar_results['lexical_diversity']}")
            print(f"Unique words used: {grammar_results['unique_words']}")
            print(f"Advanced vocabulary count: {grammar_results['advanced_vocab_count']}")
            if grammar_results['repeated_words']:
                print(f"Frequently repeated words: {', '.join(grammar_results['repeated_words'])}")
            print("\nFeedback:")
            for feedback in grammar_results['feedback']:
                print(f"- {feedback}")

    def _print_pronunciation_analysis(self, pronunciation_results):
        """Print pronunciation analysis section"""
        if pronunciation_results:
            print("\n=== Pronunciation Quality Analysis ===")
            print(f"Pronunciation score: {pronunciation_results['pronunciation_score']}/100")
            print(f"Speech rate: {pronunciation_results['speech_rate']} words per second")
            if pronunciation_results['phoneme_clarity']:
                print("Phoneme clarity scores:")
                for phoneme, score in pronunciation_results['phoneme_clarity'].items():
                    print(f"  - {phoneme}: {score}/100")
            print("\nFeedback:")
            for feedback in pronunciation_results['feedback']:
                print(f"- {feedback}")

    def _print_pitch_analysis(self, pitch_volume_results):
        """Print pitch and volume analysis section"""
        if pitch_volume_results:
            print("\n=== Pitch and Volume Analysis ===")
            print(f"Average pitch: {pitch_volume_results['average_pitch']} Hz")
            print(f"Average volume: {pitch_volume_results['average_volume']}")
            print(f"Gender detected: {pitch_volume_results['pitch_range']['detected_gender'].capitalize()}")
            print(f"Recommended pitch range: {pitch_volume_results['pitch_range']['min_recommended']}-{pitch_volume_results['pitch_range']['max_recommended']} Hz")
            print(f"Speech duration: {pitch_volume_results['total_duration']} seconds")
            print(f"Pitch score: {pitch_volume_results['pitch_analysis']['pitch_score']}/100")
            print("\nPitch time analysis:")
            print(f"  Time in optimal range: {pitch_volume_results['pitch_analysis']['time_optimal']} seconds")
            print(f"  Time too high: {pitch_volume_results['pitch_analysis']['time_too_high']} seconds")
            print(f"  Time too low: {pitch_volume_results['pitch_analysis']['time_too_low']} seconds")

            if 'pitch_details' in pitch_volume_results and 'feedback' in pitch_volume_results['pitch_details']:
                print("\nPitch feedback:")
                for feedback in pitch_volume_results['pitch_details']['feedback']:
                    print(f"- {feedback}")

    def _print_emphasis_analysis(self, emphasis_results):
        """Print emphasis analysis section"""
        if emphasis_results:
            print("\n=== Speech Emphasis Analysis ===")
            print(f"Emphasis score: {emphasis_results['emphasis_score']}/100")
            print(f"Emphasized segments: {emphasis_results['total_emphasized_segments']}")
            print(f"Emphasis density: {emphasis_results['emphasis_density_per_minute']} per minute")
            print(f"Key phrase emphasis coverage: {emphasis_results['emphasis_coverage']}%")

            if 'key_phrases' in emphasis_results and emphasis_results['key_phrases']:
                print("\nDetected key phrases that should be emphasized:")
                for i, phrase in enumerate(emphasis_results['key_phrases'][:5]):
                    print(f"  - {phrase}")
                if len(emphasis_results['key_phrases']) > 5:
                    print(f"  - ... and {len(emphasis_results['key_phrases']) - 5} more")

            if 'emphasized_words' in emphasis_results and emphasis_results['emphasized_words']:
                print("\nDetected emphasized words/phrases:")
                for i, phrase in enumerate(emphasis_results['emphasized_words'][:5]):
                    print(f"  - {phrase}")
                if len(emphasis_results['emphasized_words']) > 5:
                    print(f"  - ... and {len(emphasis_results['emphasized_words']) - 5} more")

            print("\nFeedback:")
            for feedback in emphasis_results['feedback']:
                print(f"- {feedback}")

    def _print_topic_relevance(self, topic_relevance_results):
        """Print topic relevance analysis section"""
        if topic_relevance_results:
            print("\n=== Topic Relevance Analysis ===")
            print(f"Topic: '{self.topic}'")
            print(f"Topic relevance score: {topic_relevance_results['topic_relevance_score']}/100")
            print(f"Semantic similarity: {topic_relevance_results['similarity']}")

            if topic_relevance_results['key_speech_topics']:
                print("\nKey topics in speech:")
                for topic in topic_relevance_results['key_speech_topics'][:5]:
                    print(f"  - {topic}")

            print("\nFeedback:")
            for feedback in topic_relevance_results['feedback']:
                print(f"- {feedback}")