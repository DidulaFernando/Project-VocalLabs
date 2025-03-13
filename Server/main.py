from fastapi import FastAPI, HTTPException, Depends, File, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from models.transcript import transcribe_audio, process_transcription
from models.filler_word_detection import analyze_filler_words, analyze_mid_sentence_pauses
from models.proficiency_evaluation import calculate_proficiency_score
from models.voice_modulation import analyze_voice_modulation
from models.vocabulary_evaluation import calculate_vocabulary_evaluation
from models.speech_effectiveness import evaluate_speech_effectiveness
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

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

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
    logger.info(f"Received file: {file.filename}")

    # Transcribe the audio file
    result = transcribe_audio(model, file_location)
    transcription, pause_duration = process_transcription(result)
    
    # Analyze filler words and pauses
    filler_analysis = analyze_filler_words(result)
    pause_analysis = analyze_mid_sentence_pauses(transcription)
    proficiency_scores = calculate_proficiency_score(filler_analysis, pause_analysis)
    
    # Analyze voice modulation
    modulation_analysis = analyze_voice_modulation(file_location)
    
    # Analyze vocabulary (grammar, word selection, pronunciation)
    vocabulary_evaluation = calculate_vocabulary_evaluation(result, transcription)
    
    # Analyze speech effectiveness
    effectiveness_evaluation = evaluate_speech_effectiveness(transcription)
    
    # Log transcription and evaluation information
    logger.info(f"Transcription: {transcription}")
    logger.info(f"Total pause duration: {pause_duration} seconds")
    logger.info("\nPause Analysis (Mid-sentence):")
    for category, count in pause_analysis.items():
        logger.info(f"{category}: {count}")
    logger.info("\nFiller Word Analysis:")
    for key, value in filler_analysis.items():
        logger.info(f"{key}: {value}")
    logger.info("\nProficiency Evaluation:")
    logger.info(f"Final Score: {proficiency_scores['final_score']}/20")
    logger.info(f"Filler Word Score: {proficiency_scores['filler_score']}/10")
    logger.info(f"Pause Score: {proficiency_scores['pause_score']}/10")
    
    # Log voice modulation scores
    logger.info("\nVoice Modulation Analysis:")
    logger.info(f"Total Voice Modulation Score: {modulation_analysis['scores']['total_score']}/20")
    logger.info(f"Pitch and Volume Score: {modulation_analysis['scores']['pitch_and_volume_score']}/10")
    logger.info(f"Emphasis Score: {modulation_analysis['scores']['emphasis_score']}/10")
    
    # Log vocabulary evaluation scores
    logger.info("\nVocabulary Evaluation:")
    logger.info(f"Overall Score: {vocabulary_evaluation['vocabulary_score']}/100")
    logger.info(f"Grammar and Word Selection Score: {vocabulary_evaluation['grammar_word_selection']['score']}/100")
    logger.info(f"Pronunciation Score: {vocabulary_evaluation['pronunciation']['score']}/100")
    
    # Log speech effectiveness scores
    logger.info("\nSpeech Effectiveness:")
    logger.info(f"Overall Score: {effectiveness_evaluation['effectiveness_score']}/100")
    logger.info(f"Clear Purpose Score: {effectiveness_evaluation['clear_purpose']['score']}/100")
    logger.info(f"Achievement of Purpose Score: {effectiveness_evaluation['achievement_of_purpose']['score']}/100")
    logger.info(f"Rating: {effectiveness_evaluation['rating']}")

    return {
        "filename": file.filename,
        "transcription": transcription,
        "pause_duration": pause_duration,
        "pause_analysis": pause_analysis,
        "filler_word_analysis": filler_analysis,
        "proficiency_scores": proficiency_scores,
        "modulation_analysis": modulation_analysis,
        "vocabulary_evaluation": vocabulary_evaluation,
        "effectiveness_evaluation": effectiveness_evaluation
    }

if __name__ == "__main__":
    import uvicorn
    logging.basicConfig(level=logging.INFO)
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)