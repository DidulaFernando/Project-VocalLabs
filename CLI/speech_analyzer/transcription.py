import re

def transcribe_audio(model, audio_path):
    print("Transcribing audio...")
    result = model.transcribe(
        audio_path,
        fp16=False,
        word_timestamps=True,
        initial_prompt=(
            "Please transcribe exactly as spoken. Include every um, uh, ah, er, pause, repetition, "
            "and false start. Do not clean up or correct the speech. Transcribe with maximum verbatim accuracy."
        )
    )
    return result

def process_transcription(result):
    transcription_with_pauses = []
    number_of_pauses = 0

    for i in range(len(result['segments'])):
        segment = result['segments'][i]
        words_in_segment = segment.get('words', [])

        for j in range(len(words_in_segment)):
            word_info = words_in_segment[j]
            word = word_info['word']
            transcription_with_pauses.append(word)

            if j < len(words_in_segment) - 1:
                current_word_end = word_info['end']
                next_word_start = words_in_segment[j + 1]['start']
                time_gap = next_word_start - current_word_end
                if time_gap >= 1.0:
                    pause_duration = round(time_gap, 1)
                    pause_marker = f"[{pause_duration} second pause]"
                    transcription_with_pauses.append(pause_marker)
                    number_of_pauses += 1

        if i < len(result['segments']) - 1:
            current_segment_end = segment['end']
            next_segment_start = result['segments'][i + 1]['start']
            time_gap = next_segment_start - current_segment_end
            if time_gap >= 2.0:
                pause_duration = round(time_gap, 1)
                pause_marker = f"[{pause_duration} second pause]"
                transcription_with_pauses.append(pause_marker)
                number_of_pauses += 1

    transcription_with_pauses = ' '.join(transcription_with_pauses)
    transcription_with_pauses = re.sub(r'\s+', ' ', transcription_with_pauses).strip()

    return transcription_with_pauses, number_of_pauses