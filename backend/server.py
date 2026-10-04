import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

appointments = []


class AppointmentRequest(BaseModel):
    doctorName: str
    date: str
    time: str
    patientName: str

class ChatRequest(BaseModel):
    message:str 

@app.post("/chat")
def chat(request: ChatRequest):

    response = client.responses.create(
        model="gpt-4o-mini",
        input=[
            {
                "role": "system",
                "content": (
                    "You are the receptionist for City Hospital. "
                    "Be friendly, concise, and helpful."
                ),
            },
            {
                "role": "user",
                "content": request.message,
            },
        ],
    )

    return {
        "response": response.output_text
    }

@app.get("/")
def home():
    return {"message": "Hospital backend is running"}



@app.get("/doctors")
def get_doctors():
    return {
        "doctors": [
            {
                "name": "Dr. Smith",
                "specialty": "Cardiology",
                "startTime": "9 AM",
                "endTime": "3 PM",
            },
            {
                "name": "Dr. Brown",
                "specialty": "Dermatology",
                "startTime": "10 AM",
                "endTime": "4 PM",
            },
            {
                "name": "Dr. Jones",
                "specialty": "Pediatrics",
                "startTime": "8 AM",
                "endTime": "2 PM",
            },
            {
                "name": "Dr. Wilson",
                "specialty": "General Medicine",
                "startTime": "9 AM",
                "endTime": "5 PM",
            },
        ]
    }


@app.get("/availability")
def check_availability(
    doctor: str,
    date: str,
    time: str,
):
    if (
        doctor == "Dr. Smith"
        and date == "October 10"
        and time == "10 AM"
    ):
        return {"available": False}

    if (
        doctor == "Dr. Smith"
        and date == "October 10"
        and time == "11 AM"
    ):
        return {"available": False}

    return {"available": True}

@app.post("/appointments")
def book_appointment(appointment: AppointmentRequest):

    for existing in appointments:
        if (
            existing["doctorName"] == appointment.doctorName
            and existing["date"] == appointment.date
            and existing["time"] == appointment.time
        ):
            return {
                "success": False,
                "message": "That appointment is already booked.",
            }

    appointments.append({
        "doctorName": appointment.doctorName,
        "date": appointment.date,
        "time": appointment.time,
        "patientName": appointment.patientName,
    })

    return {
        "success": True,
        "message": "Appointment booked successfully.",
    }