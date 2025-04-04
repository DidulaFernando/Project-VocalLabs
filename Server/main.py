from fastapi import FastAPI, HTTPException, Depends, File, UploadFile, Form
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import os
from models.transcript import transcribe_audio, process_transcription
from models.filler_word_detection import analyze_filler_words, analyze_mid_sentence_pauses
from models.proficiency_evaluation import calculate_proficiency_score
from models.voice_modulation import analyze_voice_modulation
from models.speech_development import evaluate_speech_development
from passlib.context import CryptContext
import whisper
import logging
from nltk_download import download_nltk_resources  # Import the utility function
from firebase_config import db
from firebase_admin import firestore
from firebase_admin import storage
import json
from fastapi.encoders import jsonable_encoder
from models.speech_effectiveness import evaluate_speech_effectiveness  # Add this import
from models.vocabulary_evaluation import evaluate_speech  # Add this import

app = FastAPI()

# Download NLTK resources at server startup
try:
    download_nltk_resources()
except Exception as e:
    logging.error(f"Error downloading NLTK resources: {str(e)}")

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
model = whisper.load_model("base")

# Password hashing
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

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
async def register_user(user: UserCreate):
    users_ref = db.collection("users")
    existing_user = users_ref.where("email", "==", user.email).get()
    if existing_user:
        raise HTTPException(status_code=400, detail="Email already registered")

    new_user = {
        "name": user.name,
        "email": user.email,
        "createdAt": firestore.SERVER_TIMESTAMP,
    }
    users_ref.add(new_user)

    return {"message": "User registered successfully"}

# Login user endpoint
@app.post("/login/")
async def login_user(user: UserLogin):
    users_ref = db.collection("users")
    user_docs = users_ref.where("email", "==", user.email).get()
    if not user_docs:
        raise HTTPException(status_code=400, detail="Invalid credentials")

    user_data = user_docs[0].to_dict()
    return {"message": "Login successful", "name": user_data["name"]}

def generate_timing_feedback(actual_duration_str, expected_duration, speech_type):
    """Generate feedback about timing compliance based on actual vs expected duration"""
    try:
        # Convert actual duration string (MM:SS) to seconds
        parts = actual_duration_str.split(':')
        actual_duration = int(parts[0]) * 60 + int(parts[1])
        
        # Parse expected duration
        expected_duration = expected_duration.lower().replace('–', '-')
        if '-' in expected_duration:
            # Range format like "5-7 minutes"
            parts = expected_duration.split('-')
            min_minutes = float(parts[0].strip())
            max_minutes_part = parts[1].strip()
            max_minutes = float(max_minutes_part.split(' ')[0])
        else:
            # Single value like "5 minutes"
            min_minutes = max_minutes = float(expected_duration.split(' ')[0])
            
        # Convert to seconds
        min_seconds = min_minutes * 60
        max_seconds = max_minutes * 60
        
        # Calculate compliance
        actual_minutes = actual_duration / 60
        
        if actual_duration < min_seconds * 0.9:  # More than 10% shorter
            compliance = "too_short"
            message = f"Your {speech_type.lower()} was too short. Aim for {expected_duration} as required."
        elif actual_duration > max_seconds * 1.1:  # More than 10% longer
            compliance = "too_long"
            message = f"Your {speech_type.lower()} exceeded the expected duration of {expected_duration}."
        else:
            compliance = "within_range"
            message = f"Great job keeping your {speech_type.lower()} within the expected duration of {expected_duration}."
        
        # Calculate percentage compliance
        target_duration = (min_seconds + max_seconds) / 2
        percentage_diff = abs(actual_duration - target_duration) / target_duration * 100
        
        return {
            "status": compliance,
            "feedback": message,
            "actual_minutes": round(actual_minutes, 1),
            "expected_range": {
                "min_minutes": min_minutes,
                "max_minutes": max_minutes
            },
            "percentage_difference": round(percentage_diff, 1),
            "within_expected_range": compliance == "within_range"
        }
    except Exception as e:
        logging.warning(f"Error generating timing feedback: {e}")
        return {
            "status": "unknown",
            "feedback": "Unable to analyze timing compliance.",
            "actual_minutes": 0,
            "expected_range": {"min_minutes": 0, "max_minutes": 0},
            "percentage_difference": 0,
            "within_expected_range": False
        }

@app.post("/upload/")
async def upload_file(file: UploadFile = File(...), 
                      topic: str = Form(None),
                      speech_type: str = Form(None), 
                      expected_duration: str = Form(None), 
                      actual_duration: str = Form(None), 
                      user_id: str = Form(...)):
    logging.info(f"Received file: {file.filename}")
    logging.info(f"Topic: {topic}, Speech Type: {speech_type}, Expected Duration: {expected_duration}, Actual Duration: {actual_duration}, User ID: {user_id}")
    
    if not topic or not speech_type or not expected_duration or not actual_duration or not user_id:
        raise HTTPException(status_code=422, detail="Missing required fields")
    
    # Save file locally first
    file_location = os.path.join(UPLOAD_DIR, file.filename)
    try:
        # Read the file content
        file_content = await file.read()
        
        # Save locally
        with open(file_location, "wb") as f:
            f.write(file_content)
        
        # Get user data from Firestore
        user_ref = db.collection("users").document(user_id)
        user_data = user_ref.get().to_dict()
        user_name = user_data.get("name", "unknown_user")
        
        # Get the number of existing speeches for the user
        speeches_ref = user_ref.collection("speeches")
        speech_count = len(speeches_ref.get())
        
        # Create a unique filename
        unique_filename = f"{user_name}_{topic}_{speech_count + 1}.wav"
        
        # Upload to Firebase Storage
        bucket = storage.bucket()
        blob = bucket.blob(f"audio/{user_id}/{unique_filename}")
        
        # Upload from local file
        blob.upload_from_filename(file_location)
        blob.make_public()
        audio_url = blob.public_url
        logging.info(f"File uploaded to Firebase Storage: {audio_url}")
        
        # Process the audio file
        result = transcribe_audio(model, file_location)
        if not result:
            raise HTTPException(status_code=500, detail="Transcription failed")
            
        transcription, pause_duration = process_transcription(result)
        filler_analysis = analyze_filler_words(result)
        pause_analysis = analyze_mid_sentence_pauses(transcription)
        
        # Convert actual_duration
        actual_duration_seconds = 0
        try:
            parts = actual_duration.split(':')
            actual_duration_seconds = int(parts[0]) * 60 + int(parts[1])
        except:
            logging.warning("Could not parse actual_duration")
        
        # Get all analysis results
        proficiency_scores = calculate_proficiency_score(
            filler_analysis, 
            pause_analysis,
            actual_duration,
            expected_duration
        )
        
        modulation_analysis = analyze_voice_modulation(file_location)
        speech_development = evaluate_speech_development(
            transcription,
            actual_duration_seconds,
            expected_duration
        )
        
        speech_effectiveness = evaluate_speech_effectiveness(
            transcription, 
            topic or "General Speech",
            expected_duration or "5-7 minutes",
            actual_duration_seconds
        )
        
        vocabulary_evaluation = evaluate_speech(result, transcription, file_location, "general")
        timing_feedback = generate_timing_feedback(actual_duration, expected_duration, speech_type)
        
        # Generate speech type feedback
        speech_type_feedback = ""
        if speech_type == "Prepared Speech":
            speech_type_feedback = "Prepared speeches should be well-structured with clear introduction, body, and conclusion."
        elif speech_type == "Impromptu Speech":
            speech_type_feedback = "Impromptu speeches show your ability to think quickly and should be coherent and relevant."
        else:
            speech_type_feedback = "Speech type feedback is unavailable."
        
        # Clean up local file
        if os.path.exists(file_location):
            os.remove(file_location)
        
        # Store results in Firestore
        try:
            # Extract scores correctly from individual analysis results
            speech_development_score = (speech_development.get("structure", {}).get("score", 0) + 
                                     speech_development.get("time_utilization", {}).get("score", 0))
            
            vocabulary_score = vocabulary_evaluation.get("vocabulary_score", 0)
            effectiveness_score = speech_effectiveness.get("total_score", 0)
            voice_analysis_score = modulation_analysis["scores"].get("total_score", 0)
            proficiency_score = proficiency_scores.get("final_score", 0)

            # Calculate overall score (sum of all main scores)
            overall_score = (speech_development_score + 
                           vocabulary_score + 
                           effectiveness_score + 
                           voice_analysis_score + 
                           proficiency_score)

            speech_data = {
                # Core metrics - ensure all scores are out of 20
                "speech_development_score": speech_development_score,
                "vocabulary_evaluation_score": vocabulary_score,
                "effectiveness_score": effectiveness_score,
                "voice_analysis_score": voice_analysis_score,
                "proficiency_score": proficiency_score,
                "overall_score": overall_score,  # Add the overall score
                
                # Basic info
                "topic": topic,
                "speech_type": speech_type,
                "expected_duration": expected_duration,
                "actual_duration": actual_duration,
                "audio_url": audio_url,
                "transcription": transcription,
                
                # Metadata
                "user_id": user_id,
                "recorded_at": firestore.SERVER_TIMESTAMP
            }
            
            # Save under the user's document in Firestore
            speeches_ref.add(speech_data)
            
            logging.info(f"Speech data saved for user: {user_id}")
        except Exception as db_error:
            logging.error(f"Error storing speech data in Firestore: {str(db_error)}")
            # Continue execution even if database storage fails

        # Prepare enhanced response
        response = {
            "message": "Speech uploaded and analyzed successfully",
            "speech_data": speech_data,
            "filename": unique_filename,
            "transcription": transcription,
            "pause_duration": pause_duration,
            "pause_analysis": pause_analysis,
            "filler_analysis": filler_analysis,
            "proficiency_scores": proficiency_scores,
            "modulation_analysis": modulation_analysis,
            "speech_development": speech_development,
            "speech_effectiveness": speech_effectiveness,
            "vocabulary_evaluation": vocabulary_evaluation,
            "timing_feedback": timing_feedback,
            "speech_type_feedback": speech_type_feedback,
            "audio_url": audio_url,
            "speech_details": {
                "topic": topic,
                "speech_type": speech_type,
                "expected_duration": expected_duration,
                "actual_duration": actual_duration
            },
            "enhanced_analysis": {
                "timing_compliance": timing_feedback,
                "speech_type_feedback": speech_type_feedback,
                "topic_relevance": {
                    "score": proficiency_scores.get('timing_score', 7) * 10,
                    "feedback": f"Your speech on '{topic}' was analyzed for content and delivery quality."
                },
                "recommendations": [
                    f"Practice keeping your {speech_type.lower()} within the {expected_duration} timeframe.",
                    "Focus on reducing filler words to sound more confident.",
                    "Use pauses strategically rather than mid-sentence."
                ] + speech_development.get("structure", {}).get("feedback", [])
            }
        }

        # Log serialization attempts for debugging
        for key, value in response.items():
            try:
                json.dumps({key: value})
            except Exception as e:
                logging.error(f"Serialization error in field '{key}': {e}")
                response[key] = str(value)  # Fallback to string conversion

        return JSONResponse(content=jsonable_encoder(response))
        
    except Exception as e:
        logging.error(f"Error processing file: {str(e)}")
        # Clean up local file if it exists
        if os.path.exists(file_location):
            os.remove(file_location)
        raise HTTPException(status_code=500, detail=f"Error processing file: {str(e)}")
