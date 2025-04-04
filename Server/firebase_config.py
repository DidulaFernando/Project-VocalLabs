# filepath: f:\SDGP_GIT_CONNECT\SDGP_GIT_CONNECT\Project-VocalLabs\Server\firebase_config.py
import firebase_admin
from firebase_admin import credentials, firestore, storage

# Path to your Firebase service account key JSON file
cred = credentials.Certificate(r"E:\IIT\Project-VocalLabs\Server\vocallabs-fc7d5-firebase-adminsdk-fbsvc-c9dfb67bfb.json")  # Replace with the actual path

# Initialize Firebase Admin SDK with the correct storage bucket
firebase_admin.initialize_app(cred, {
    'storageBucket': 'vocallabs-fc7d5.firebasestorage.app'  # Correct bucket name
})

# Firestore database instance
db = firestore.client()