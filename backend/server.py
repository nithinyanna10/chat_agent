import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from openai import OpenAI
import json

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

def is_available(doctor, date, time):

    if (
        doctor == "Dr. Smith"
        and date == "October 10"
        and time == "10 AM"
    ):
        return False

    if (
        doctor == "Dr. Smith"
        and date == "October 10"
        and time == "11 AM"
    ):
        return False

    for appointment in appointments:

        if (
            appointment["doctorName"] == doctor
            and appointment["date"] == date
            and appointment["time"] == time
        ):
            return False

    return True
conversation = {
    "doctor": None,
    "date": None,
    "time":None,
    "patientName": "Demo Patient",

}
messages = [] 
doctors = [
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
def save_appointment(doctor, date, time, patient_name):

    for appointment in appointments:
        if (
            appointment["doctorName"] == doctor
            and appointment["date"] == date
            and appointment["time"] == time
        ):
            return False

    appointments.append({
        "doctorName": doctor,
        "date": date,
        "time": time,
        "patientName": patient_name,
    })

    return True
# tool calls for agent 
def list_doctors():
    return doctors

def check_doctor_availability(doctor, date, time):
    return is_available(doctor, date, time)


def book_doctor_appointment(doctor, date, time, patient_name):
    return save_appointment(
        doctor,
        date,
        time,
        patient_name,
    )



tools = [
    {
        "type": "function",
        "name": "list_doctors",
        "description": "Get the list of doctors at City Hospital.",
        "parameters": {
            "type": "object",
            "properties": {},
            "required": [],
        },
    },
    {
        "type": "function",
        "name": "check_doctor_availability",
        "description": "Check whether a doctor is available at a specific date and time.",
        "parameters": {
            "type": "object",
            "properties": {
                "doctor": {
                    "type": "string",
                    "description": "Doctor's name, for example Dr. Smith",
                },
                "date": {
                    "type": "string",
                    "description": "Appointment date, for example October 10",
                },
                "time": {
                    "type": "string",
                    "description": "Appointment time, for example 12 PM",
                },
            },
            "required": ["doctor", "date", "time"],
        },
    },
    {
        "type": "function",
        "name": "book_doctor_appointment",
        "description": "Book an available appointment for a patient.",
        "parameters": {
            "type": "object",
            "properties": {
                "doctor": {
                    "type": "string",
                },
                "date": {
                    "type": "string",
                },
                "time": {
                    "type": "string",
                },
                "patient_name": {
                    "type": "string",
                },
            },
            "required": [
                "doctor",
                "date",
                "time",
                "patient_name",
            ],
        },
    },
]


@app.post("/chat")
def chat(request: ChatRequest):
    messages.append({
        "role":"user" ,
        "content":request.message
    })




    response = client.responses.create( 
        tools = tools,
        model="gpt-4o-mini",
        input=[
            {
                "role": "system",
                "content": """
You are a hospital receptionist.

Understand what the patient wants.

Return ONLY JSON.

IMPORTANT:
You have tools available for accessing hospital information.

When the user asks for doctors, use the list_doctors tool.
When the user asks whether a doctor is available, use check_doctor_availability.
When the user wants to book an appointment, use book_doctor_appointment.

Do NOT return JSON intents such as {"intent":"list_doctors"}.
Use the tools directly when appropriate.

Possible intents:
- find_doctor
- list_doctors
- start_booking
- provide_date
- provide_time
- check_availability
- book_appointment
- greeting
- unknown
- confirm_booking
- provide_name

If the patient wants a type of doctor, identify the specialty.

Example:
User: I need a heart doctor
Return:
{"intent":"find_doctor","specialty":"Cardiology"}

User: I want to see a skin doctor
Return:
{"intent":"find_doctor","specialty":"Dermatology"}

User: hello
Return:
{"intent":"greeting","specialty":null}

If the patient gives a day or date, put it in "date".

User: next Monday
Return:
{"intent":"provide_date","date":"next Monday"}

User: October 10
Return:
{"intent":"provide_date","date":"October 10"}

User: 10 AM

Return:
{"intent":"provide_time","time":"10 AM"}

User: yes

Return:
{"intent":"confirm_booking"}

User: show me the list of doctors

Return:
{"intent":"list_doctors"}

User: I'd like to book an appointment

Return:
{"intent":"start_booking"}

User: I want to schedule an appointment

Return:
{"intent":"start_booking"}

User: My name is John

Return:
{"intent":"provide_name","name":"John"}

User: I'm Sarah

Return:
{"intent":"provide_name","name":"Sarah"}

"""
            },
            {
                "role": "user",
                "content": """..."""
            },
            *messages
        ]
    )

    for item in response.output:

        if item.type == "function_call":
            print("tool called",item.name)
            print("arguments::",item.arguments)
            arguments = json.loads(item.arguments)

            if item.name == "list_doctors":
                print("🏥 Running list_doctors()")

                result = list_doctors()

            elif item.name == "check_doctor_availability":
                print("🏥 Running check_doctor_availability()")


                result = check_doctor_availability(
                    arguments["doctor"],
                    arguments["date"],
                    arguments["time"],
                )

            elif item.name == "book_doctor_appointment":

                result = book_doctor_appointment(
                    arguments["doctor"],
                    arguments["date"],
                    arguments["time"],
                    arguments["patient_name"],
                )

            response = client.responses.create(
                model="gpt-4o-mini",
                tools=tools,
                input=[
                    *messages,
                    item,
                    {
                        "type": "function_call_output",
                        "call_id": item.call_id,
                        "output": json.dumps(result),
                    },
                ],
            )

            return {
                "response": response.output_text
            }
            print("🔥 GOT RESPONSE FROM OPENAI")
    print(response.output)

    for item in response.output:
        print("🔥 ITEM TYPE:", item.type)

        if item.type == "function_call":
            print("🔥🔥 TOOL CALLED:", item.name)
            print("🔥 ARGUMENTS:", item.arguments)


    result = json.loads(response.output_text)
    if result["intent"] == "provide_date":
        conversation["date"] = result["date"] 

        return {
            "response":"great what time would you like the appointment?"
        }
    if result["intent"] == "provide_time":

        conversation["time"] = result["time"]

        available = is_available(
            conversation["doctor"],
            conversation["date"],
            conversation["time"],
        )

        if available:
            return {
                "response": "That time is available. Would you like me to book it?"
            }
        else:
            return {
                "response": "Sorry, that time is already booked. Would you like another time?"
            }
    if result["intent"] == "confirm_booking":

        booked = save_appointment(
            conversation["doctor"],
            conversation["date"],
            conversation["time"],
            conversation["patientName"],
        )

        if booked:
            return {
                "response": (
                    f"Perfect! Your appointment with "
                    f"{conversation['doctor']} on "
                    f"{conversation['date']} at "
                    f"{conversation['time']} has been booked."
                )
            }

        return {
            "response": "Sorry, that appointment is no longer available."

        }
    if result["intent"] == "provide_name":

        conversation["patientName"] = result["name"]

        return {
            "response": f"Nice to meet you, {result['name']}! How can I help you today?"
        }
    
    if result["intent"] == "list_doctors":

        doctor_list = ""

        for doctor in doctors:
            doctor_list += (
                f"{doctor['name']} - "
                f"{doctor['specialty']} - "
                f"{doctor['startTime']} to {doctor['endTime']}\n"
            )

        return {
            "response": "Here are our doctors:\n" + doctor_list
        }
    
    if result["intent"] == "start_booking":

        return {
            "response": "Sure! What type of doctor would you like to see?"
        }

    if result["intent"] == "find_doctor":

        specialty = result["specialty"]

        for doctor in doctors:

            if doctor["specialty"] == specialty:
                conversation["doctor"] = doctor["name"]


                return {
                    "response": (
                        f"We have {doctor['name']} in {doctor['specialty']}. "
                        f"They are available from {doctor['startTime']} "
                        f"to {doctor['endTime']}. "
                        "What day would you like an appointment?"
                    )
                }

        return {
            "response": "Sorry, we don't currently have a doctor for that specialty."
        }

    if result["intent"] == "greeting":

        return {
            "response": "Hello! Welcome to City Hospital. How can I help you?"
        }

    return {
        "response": "I can help you find a doctor or book an appointment."
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
    return {
        "available": is_available(doctor, date, time)
    }

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