# 🎤 VocalLabs – Speech Analysis Software for Toastmasters

VocalLabs is a mobile-based speech analysis and feedback system designed to help users—especially Toastmasters—improve their public speaking skills. This cross-platform application provides insights into filler word usage, voice modulation, vocabulary, grammar, and more, using powerful machine learning and natural language processing techniques.

## 🚀 Features

- 🔍 **Speech Analysis**: Transcribes and analyzes recorded speech in real-time.
- 🧠 **Filler Word Detection**: Identifies and counts overused filler words.
- 🎚 **Voice Modulation Evaluation**: Analyzes pitch variation and delivery.
- 📊 **Vocabulary & Grammar Feedback**: Assesses word complexity and grammatical accuracy.
- 🧾 **Speech Structure Assessment**: Evaluates introduction, body, and conclusion quality.
- 📱 **Mobile App**: Built with Flutter for Android and iOS platforms.
- ☁️ **Real-time Storage**: Firebase integration for seamless data persistence.
- 🔐 **User Authentication**: Secure login and registration system.

## 🛠️ Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (Dart) |
| Backend | Python, FastAPI |
| Cloud Services | Firebase (Auth, Firestore, Storage) |
| Libraries | NLTK, librosa, NumPy, SciPy |
| Architecture | Client-Server, RESTful APIs |
| Platforms | Android, iOS, Web (optional) |

## 📁 Project Structure

```
recommendation-system/
├── data/                       # Raw and processed CSV files (Git LFS)
├── models/                     # Pickle model files for ML (Git LFS)
├── backend/                    # Python FastAPI backend
├── frontend/                   # Flutter mobile app
├── cli/                        # Command-line interface tools
├── README.md
└── requirements.txt
```

## ⚙️ Installation

1. Clone this repo:
```bash
git clone https://github.com/naela-girsy-projects/Project-VocalLabs.git
cd Project-VocalLabs
```

2. Install backend dependencies:
```bash
pip install -r backend/requirements.txt
```

3. Run the backend server:
```bash
cd backend
Server run
```

4. Run the Flutter frontend:
```bash
cd frontend
flutter pub get
flutter run
```

⚠️ **Note**: This repo uses Git LFS to manage large files such as datasets and trained model binaries. Ensure you have Git LFS installed.

## 📈 Demo & Screenshots

Check out our landing page for live demos and screenshots: [VocalLabs Landing Page](https://vocal-labs-landing-page.vercel.app/)

## 🧪 Testing

- Unit and functional tests for backend modules.
- Usability testing for the frontend app.
- Performance benchmarking of speech processing components.

## 👨‍💻 Authors

- Didula Fernando
- Nisith Dharmawardane
- Sashini Jayakodi
- Naela Girsy
- Dunuhinga Wihanga
- Oshan Wijesinghe

## 📄 License

This project is for educational use at the University of Westminster. Commercial use is not permitted.
