from fastapi import FastAPI, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
import os
from models.transcript import transcribe_audio, process_transcription
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
    transcription, number_of_pauses = process_transcription(result)
    print(f"Transcription: {transcription}")
    print(f"Number of pauses: {number_of_pauses}")

    return {"filename": file.filename, "transcription": transcription, "number_of_pauses": number_of_pauses}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)