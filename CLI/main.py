import os
import nltk
from speech_analyzer.core import SpeechAnalyzer

if __name__ == "__main__":
    try:
        print("Initializing speech analyzer...")

        # Get topic if provided
        topic = None
        use_topic = input("Would you like to analyze relevance to a specific topic? (y/n): ")
        if use_topic.lower().startswith('y'):
            topic = input("Please enter the speech topic: ")

        # Update the audio path to the correct location
        audio_path = r"E:\IIT\Project-VocalLabs\CLI\Technology Tools for Leaders.wav"

        # Initialize with topic if provided
        analyzer = SpeechAnalyzer(audio_path=audio_path, topic=topic)

        print("Transcribing audio (this may take a while)...")
        result = analyzer.transcribe_audio()

        print("Processing transcription...")
        analyzer.process_transcription(result)

        print("Analyzing speech...")
        analyzer.print_analysis(result)

    except Exception as e:
        import traceback
        print(f"An error occurred during analysis: {e}")
        traceback.print_exc()