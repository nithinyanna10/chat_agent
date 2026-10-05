# chat_agent

A hospital virtual receptionist. Patients chat (by text or voice, in English or Spanish) to find doctors, check open slots and book appointments.

- **Frontend:** Flutter app, runs in Chrome (web) and on the iOS simulator. Login with your name, chat screen, voice input (mic) and voice replies, English/Spanish switch, and a side menu with your profile and booked appointments.
- **Backend:** Python FastAPI + OpenAI (chat with tool calling, text-to-speech)

## Run it

**1. Backend**

```
cd backend
python -m venv .venv
.venv/bin/pip install fastapi uvicorn openai
echo 'OPENAI_API_KEY=your-key-here' > .env
export $(grep OPENAI_API_KEY .env | xargs)
.venv/bin/uvicorn server:app --reload
```

The server runs at http://127.0.0.1:8000.

**2. App** (in a second terminal, from the project root)

```
flutter pub get
flutter run -d chrome
```

Enter your name, then chat. Tap the mic to talk; voice messages get a spoken reply.
