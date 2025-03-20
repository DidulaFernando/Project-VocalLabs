from fastapi import FastAPI, HTTPException, Depends, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel  # Add this import
import os
from models.transcript import transcribe_audio, process_transcription
from models.filler_word_detection import analyze_filler_words, analyze_mid_sentence_pauses
from models.proficiency_evaluation import calculate_proficiency_score
from models.voice_modulation import analyze_voice_modulation
from models.user import User, SessionLocal, engine
from sqlalchemy.orm import Session
from passlib.context import CryptContext
import whisper
import logging

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

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Dependency to get DB session
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Pydantic models
class UserCreate(BaseModel):
    name: str
    email: str
    password: str

class UserLogin(BaseModel):
    email: str
    password: str

# Create user endpoint
@app.post("/register/")
async def register_user(user: UserCreate, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed_password = pwd_context.hash(user.password)
    db_user = User(name=user.name, email=user.email, hashed_password=hashed_password)
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

# Login user endpoint
@app.post("/login/")
async def login_user(user: UserLogin, db: Session = Depends(get_db)):
    db_user = db.query(User).filter(User.email == user.email).first()
    if not db_user or not pwd_context.verify(user.password, db_user.hashed_password):
        raise HTTPException(status_code=400, detail="Invalid credentials")
    return {"message": "Login successful", "name": db_user.name}

@app.post("/upload/")
async def upload_file(file: UploadFile = File(...)):
    file_location = os.path.join(UPLOAD_DIR, file.filename)
    with open(file_location, "wb") as f:
        f.write(await file.read())
    logging.info(f"Received file: {file.filename}")

    # Transcribe the audio file
    result = transcribe_audio(model, file_location)
    transcription, pause_duration = process_transcription(result)
    filler_analysis = analyze_filler_words(result)
    pause_analysis = analyze_mid_sentence_pauses(transcription)
    proficiency_scores = calculate_proficiency_score(filler_analysis, pause_analysis)
    
    # Analyze voice modulation
    modulation_analysis = analyze_voice_modulation(file_location)
    
    # Log transcription and evaluation information
    logging.info(f"Transcription: {transcription}")
    logging.info(f"Total pause duration: {pause_duration} seconds")
    logging.info("\nPause Analysis (Mid-sentence):")
    for category, count in pause_analysis.items():
        logging.info(f"{category}: {count}")
    logging.info("\nFiller Word Analysis:")
    for key, value in filler_analysis.items():
        logging.info(f"{key}: {value}")
    logging.info("\nProficiency Evaluation:")
    logging.info(f"Final Score: {proficiency_scores['final_score']}/20")
    logging.info(f"Filler Word Score: {proficiency_scores['filler_score']}/10")
    logging.info(f"Pause Score: {proficiency_scores['pause_score']}/10")
    
    # Log voice modulation scores
    logging.info("\nVoice Modulation Analysis:")
    logging.info(f"Total Voice Modulation Score: {modulation_analysis['scores']['total_score']}/20")
    logging.info(f"Pitch and Volume Score: {modulation_analysis['scores']['pitch_and_volume_score']}/10")
    logging.info(f"Emphasis Score: {modulation_analysis['scores']['emphasis_score']}/10")

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
    logging.basicConfig(level=logging.INFO)
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)