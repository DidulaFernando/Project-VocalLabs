from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import os
from models.transcript import transcribe_audio, process_transcription
from models.filler_word_detection import analyze_filler_words, analyze_mid_sentence_pauses
from models.proficiency_evaluation import calculate_proficiency_score
from models.voice_modulation import analyze_voice_modulation
import whisper
app = FastAPI()

# Enable CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=True,
    allow_methods=["*"],  # Allows all methods
    allow_headers=["*"],  # Allows all headers
)

UPLOAD_DIR = "uploads"
os.makedirs(UPLOAD_DIR, exist_ok=True)

# Load your transcription model here
model = whisper.load_model("medium")

@app.post("/upload/")
async def upload_file(file: UploadFile = File(...)):
    file_location = os.path.join(UPLOAD_DIR, file.filename)
    with open(file_location, "wb") as f:
        f.write(await file.read())
    print(f"Received file: {file.filename}")

    # Transcribe the audio file
    result = transcribe_audio(model, file_location)
    transcription, pause_duration = process_transcription(result)
    filler_analysis = analyze_filler_words(result)
    pause_analysis = analyze_mid_sentence_pauses(transcription)
    proficiency_scores = calculate_proficiency_score(filler_analysis, pause_analysis)
    
    # Analyze voice modulation
    modulation_analysis = analyze_voice_modulation(file_location)
    
    print(f"Transcription: {transcription}")
    print(f"Total pause duration: {pause_duration} seconds")
    print("\nPause Analysis (Mid-sentence):")
    for category, count in pause_analysis.items():
        print(f"{category}: {count}")
    print("\nFiller Word Analysis:")
    for key, value in filler_analysis.items():
        print(f"{key}: {value}")
    print("\nProficiency Evaluation:")
    print(f"Final Score: {proficiency_scores['final_score']}/20")
    print(f"Filler Word Score: {proficiency_scores['filler_score']}/10")
    print(f"Pause Score: {proficiency_scores['pause_score']}/10")
    
    # Print voice modulation scores
    print("\nVoice Modulation Analysis:")
    print(f"Total Voice Modulation Score: {modulation_analysis['scores']['total_score']}/20")
    print(f"Pitch and Volume Score: {modulation_analysis['scores']['pitch_and_volume_score']}/20")
    print(f"Emphasis Score: {modulation_analysis['scores']['emphasis_score']}/20")

    return {
        "filename": file.filename,
        "transcription": transcription,
        "pause_duration": pause_duration,
        "pause_analysis": pause_analysis,
        "filler_word_analysis": filler_analysis,
        "proficiency_scores": proficiency_scores,
        "modulation_analysis": modulation_analysis
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)