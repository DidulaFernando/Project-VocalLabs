import re
import soundfile as sf
import wave

def get_audio_duration(audio_path):
    try:
        info = sf.info(audio_path)
        return info.duration
    except Exception as e:
        print(f"Error getting audio duration using soundfile: {e}")
        try:
            with wave.open(audio_path, 'rb') as wf:
                frames = wf.getnframes()
                rate = wf.getframerate()
                duration = frames / float(rate)
                return duration
        except Exception as e:
            print(f"Error getting audio duration using wave: {e}")
            return 60

def neutralize_time_durations(audio_path, transcription_with_pauses, transcription_result, total_time):
    total_time = get_audio_duration(audio_path)

    if total_time <= 0 and isinstance(transcription_result, dict):
        total_time = transcription_result.get('duration', 0)
        if total_time <= 0 and 'segments' in transcription_result and transcription_result['segments']:
            total_time = transcription_result['segments'][-1].get('end', 0)

    total_time = max(total_time, 1.0)

    pauses_pattern = r'\[(\d+\.\d+) second pause\]'
    pause_matches = re.findall(pauses_pattern, transcription_with_pauses)

    total_pause_time = sum(float(duration) for duration in pause_matches)

    neutralized_duration = max(total_time - total_pause_time, 0.1)

    words_without_pauses = re.sub(pauses_pattern, '', transcription_with_pauses)
    word_count = len([w for w in words_without_pauses.split() if w.strip()])

    word_count = max(word_count, 1)

    speaking_rate = word_count / neutralized_duration

    return {
        'original_duration': total_time,
        'pause_time': total_pause_time,
        'neutralized_duration': neutralized_duration,
        'word_count': word_count,
        'speaking_rate': round(speaking_rate, 2)
    }