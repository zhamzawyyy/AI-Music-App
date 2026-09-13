# 🎵 AI Music App

A full-stack AI-powered music application built with **Flutter** and **FastAPI**.

The app allows users to generate music using AI prompts, identify songs from short audio recordings, manage their personal music library, and play generated tracks directly from the mobile application.

---

## ✨ Features

### 🎼 AI Music Generation

* Generate music using natural-language prompts.
* Optional AI prompt refinement using OpenAI.
* Music generation powered by ModelsLab.
* Track generation handled through asynchronous jobs.
* Real-time job status polling from the mobile app.

### 🎤 Song Recognition

* Record a short audio clip directly from the mobile application.
* Send the recording securely to the backend.
* Identify songs using external audio-identification services such as AudD / ACRCloud.

### 🔐 Authentication

* User registration and login.
* JWT-based authentication.
* Access and refresh tokens.
* Secure token storage on the mobile device.

### 📚 Personal Music Library

* View generated and recognized tracks.
* Delete tracks from the personal library.
* Access tracks directly from the music player.

### ▶️ Audio Player

* Built-in audio playback.
* Powered by `just_audio`.
* Simple and lightweight player experience.

---

## 🏗️ Project Architecture

The project is divided into two main applications:

```text
AI-Music-App/
│
├── backend/
│   ├── app/
│   │   ├── api/
│   │   │   ├── auth.py
│   │   │   ├── generation.py
│   │   │   ├── library.py
│   │   │   └── recognition.py
│   │   │
│   │   ├── core/
│   │   │   ├── config.py
│   │   │   ├── database.py
│   │   │   ├── rate_limit.py
│   │   │   └── security.py
│   │   │
│   │   ├── models/
│   │   ├── schemas/
│   │   ├── services/
│   │   │   ├── audio_id_client.py
│   │   │   ├── modelslab_client.py
│   │   │   └── openai_client.py
│   │   └── main.py
│   │
│   ├── requirements.txt
│   ├── smoke_test.py
│   └── .env.example
│
└── mobile/
    ├── lib/
    │   ├── app/
    │   ├── features/
    │   │   ├── auth/
    │   │   ├── generation/
    │   │   ├── library/
    │   │   ├── player/
    │   │   └── recognition/
    │   │
    │   └── shared/
    │       └── services/
    │
    └── pubspec.yaml
```

---

## 🛠️ Tech Stack

### Mobile

* **Flutter**
* **Dart**
* `go_router`
* `provider`
* `just_audio`
* `record`
* `flutter_secure_storage`
* `http`
* `path_provider`

### Backend

* **Python**
* **FastAPI**
* **SQLAlchemy**
* **SQLite** for local development
* JWT Authentication
* Pydantic
* REST API

### AI & External Services

* **OpenAI** — prompt refinement
* **ModelsLab** — AI music generation
* **AudD / ACRCloud** — audio/song identification

---

## 🔄 Application Flow

```text
             ┌─────────────────┐
             │  Flutter Mobile │
             │      App        │
             └────────┬────────┘
                      │
                      │ REST API
                      ▼
             ┌─────────────────┐
             │     FastAPI     │
             │     Backend     │
             └───────┬─────────┘
                     │
        ┌────────────┼─────────────┐
        │            │             │
        ▼            ▼             ▼
   ┌─────────┐  ┌──────────┐  ┌────────────┐
   │Database │  │ OpenAI   │  │ ModelsLab  │
   └─────────┘  └──────────┘  └────────────┘
                     │
                     ▼
              AI Generated Music

       Audio Recording
             │
             ▼
        FastAPI Backend
             │
             ▼
      Audio Identification
        AudD / ACRCloud
```

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/YOUR_REPOSITORY.git
cd YOUR_REPOSITORY
```

---

# 🔧 Backend Setup

Navigate to the backend:

```bash
cd backend
```

Create a virtual environment:

```bash
python -m venv venv
```

Activate it on Windows:

```bash
venv\Scripts\activate
```

Or on macOS/Linux:

```bash
source venv/bin/activate
```

Install dependencies:

```bash
pip install -r requirements.txt
```

Create your environment file:

```bash
copy .env.example .env
```

On macOS/Linux:

```bash
cp .env.example .env
```

Add your API credentials to `.env`.

Example:

```env
OPENAI_API_KEY=your_openai_api_key
MODELSLAB_API_KEY=your_modelslab_api_key
AUDIO_ID_API_KEY=your_audio_identification_api_key
DATABASE_URL=sqlite:///./app.db
```

> Never commit real API keys or secrets to GitHub.

---

## ▶️ Run the Backend

From the `backend` directory:

```bash
uvicorn app.main:app --reload
```

The API will be available at:

```text
http://localhost:8000
```

Interactive API documentation:

```text
http://localhost:8000/docs
```

---

## 🧪 Backend Testing

The project includes a smoke test:

```bash
python smoke_test.py
```

The test covers the main application flow, including:

```text
Register
   ↓
Login
   ↓
Create Generation Job
   ↓
Check Job Status
   ↓
Check Library
```

External AI calls are mocked during the smoke test, so real AI API keys are not required for the test.

---

# 📱 Mobile Setup

Navigate to the mobile application:

```bash
cd mobile
```

Install Flutter dependencies:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run the application:

```bash
flutter run
```

---

## 🔗 Backend Configuration

The mobile application can be pointed to a different backend URL using `API_BASE_URL`.

### Android Emulator

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

### iOS Simulator

```bash
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

---

## 🎙️ Required Permissions

### Android

Add the required permissions to:

```text
android/app/src/main/AndroidManifest.xml
```

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.INTERNET" />
```

### iOS

Add microphone permission to:

```text
ios/Runner/Info.plist
```

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Used only to identify a song you're currently listening to. The recording is not saved.</string>
```

---

# 🔌 API Endpoints

| Method   | Endpoint                | Authentication | Description                      |
| -------- | ----------------------- | -------------- | -------------------------------- |
| `POST`   | `/auth/register`        | ❌              | Create a new user                |
| `POST`   | `/auth/login`           | ❌              | Login and receive tokens         |
| `POST`   | `/auth/refresh`         | 🔑             | Refresh access token             |
| `POST`   | `/generation`           | 🔑             | Start an AI music generation job |
| `GET`    | `/generation/{job_id}`  | 🔑             | Check generation status          |
| `GET`    | `/library`              | 🔑             | Get user's music library         |
| `DELETE` | `/library/{track_id}`   | 🔑             | Delete a track                   |
| `POST`   | `/recognition/identify` | 🔑             | Identify an audio recording      |
| `GET`    | `/health`               | ❌              | Backend health check             |

---

## 🔐 Security

The application includes several security-related mechanisms:

* JWT access and refresh tokens.
* Secure token storage on mobile.
* Password hashing.
* Authentication-protected endpoints.
* API rate limiting.
* File upload size limits.
* Environment variables for external API credentials.
* Separation between the mobile application and external AI services.

The mobile app communicates with the backend instead of directly exposing AI service credentials.

---

## 🗃️ Database

The project uses SQLite for local development.

For production deployments, the database configuration can be changed to PostgreSQL through the `DATABASE_URL` environment variable.

Example:

```env
DATABASE_URL=postgresql://user:password@host:5432/database
```

---

## 📂 Main Application Modules

### Authentication

Handles:

* Registration
* Login
* Access tokens
* Refresh tokens
* Protected routes

### Generation

Handles:

* Music generation requests
* AI prompt processing
* Generation jobs
* Job status
* Generated tracks

### Recognition

Handles:

* Audio uploads
* Song identification
* External identification APIs

### Library

Handles:

* User tracks
* Track listing
* Track deletion

### Player

Handles:

* Audio playback
* Playing generated tracks
* Basic playback controls

---

## 🔮 Future Improvements

Possible improvements for future versions include:

* 🎨 More advanced UI/UX design
* 🔄 Pull-to-refresh and improved loading states
* 💾 Offline music-library caching
* 🔔 Push notifications when music generation is complete
* ⚡ WebSocket/SSE-based generation status updates
* 🐘 PostgreSQL for production
* 🚀 Production deployment
* 🧪 More automated tests
* 🎵 More advanced music-player controls

---

## 📌 Project Status

**Version:** `0.1.0`

This project is currently an early full-stack version demonstrating AI-powered music generation, song recognition, authentication, personal music management, and mobile audio playback.

---

## 👨‍💻 Author

**Ziad Sayed Ahmed**

Junior Data Scientist / AI & Software Development Enthusiast

Interested in:

* Python
* SQL
* Data Science
* Machine Learning
* AI Applications
* FastAPI
* Flutter

---

## ⭐ If You Like This Project

If you find this project interesting, consider giving the repository a ⭐ on GitHub.
