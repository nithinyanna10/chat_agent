import os
import base64
from turtle import speed
from fastapi import FastAPI, Response
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

# appointments are saved to a file so they survive server restarts
APPOINTMENTS_FILE = os.path.join(os.path.dirname(__file__), "appointments.json")

if os.path.exists(APPOINTMENTS_FILE):
    with open(APPOINTMENTS_FILE) as f:
        appointments = json.load(f)
else:
    appointments = []


def save_appointments():
    with open(APPOINTMENTS_FILE, "w") as f:
        json.dump(appointments, f, indent=2)


class AppointmentRequest(BaseModel):
    doctorName: str
    date: str
    time: str
    patientName: str

class ChatRequest(BaseModel):
    message:str
    patient_name : str
    language: str = "English" #comes from frontend 

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
    save_appointments()

    return True
# tool calls for agent 
def list_doctors():
    return doctors

def find_doctor(name):
    for doctor in doctors:
        if name.lower() in doctor["name"].lower():
            return doctor

    return {
        "error": "Doctor not found"
    }

def find_doctor_by_specialty(specialty):

    results = []

    for doctor in doctors:

        if doctor["specialty"].lower() == specialty.lower():
            results.append(doctor)

    return results

def get_available_slots(doctor, date):

    selected_doctor = None

    for d in doctors:

        if d["name"].lower() == doctor.lower():
            selected_doctor = d
            break

    if selected_doctor is None:
        return {
            "error": "Doctor not found"
        }

    slots = generate_slots(
        selected_doctor["startTime"],
        selected_doctor["endTime"],
    )

    available_slots = []

    for slot in slots:

        if is_available(
            doctor,
            date,
            slot,
        ):
            available_slots.append(slot)

    return available_slots
def check_doctor_availability(doctor, date, time):
    return is_available(doctor, date, time)


def book_doctor_appointment(doctor, date, time, patient_name):
    return save_appointment(
        doctor,
        date,
        time,
        patient_name,
    )

def get_patient_appointments(patient_name):
    result = [] 

    for appointment in appointments:
        if appointment["patientName"].lower() == patient_name.lower():
            result.append(appointment)
    return result

def cancel_appointment(patient_name,doctor,date,time):
    for appointment in appointments:
        if (
            appointment["patientName"].lower() == patient_name.lower()
            and appointment["doctorName"].lower()==doctor.lower()
            and appointment["date"].lower() == date.lower() 
            and appointment["time"].lower() == time.lower()
        ):
            appointments.remove(appointment)
            save_appointments()

            return { 
                "success" : True,
                "message" : "appointment cancelled successfully"
            }
    return {
        "success": False,
        "message": "Appointment not found"
    }

def reschedule_appointment(patient_name,doctor,old_date,old_time,new_date,new_time):
    available = check_doctor_availability(
        doctor,new_date,new_time
    ) 
    if not available:
        return {
            "success":False,
            "message":"the nre appointment time is not available"
        }
    old_appointment = None 

    for appointment in appointments:
        if (
            appointment["patientName"].lower() == patient_name.lower() 
            and appointment["doctorName"].lower() == doctor.lower()
            and appointment["date"].lower() == old_date.lower()
            and appointment["time"].lower() == old_time.lower()
        ):
            old_appointment = appointment
            break

    if old_appointment is None:
        return {
            "success": False,
            "message": "The existing appointment was not found."
        }

    appointments.remove(old_appointment)
    save_appointments()

    # Create new appointment
    appointments.append({
        "doctorName": doctor,
        "date": new_date,
        "time": new_time,
        "patientName": patient_name,
    })
    save_appointments()

    return {
        "success": True,
        "message": "Appointment rescheduled successfully",
        "appointment": {
            "doctorName": doctor,
            "date": new_date,
            "time": new_time,
            "patientName": patient_name,
        }
    }
# its not a tool call its a helper function
def parse_time(time_string):

    parts = time_string.split()

    time = parts[0]
    period = parts[1].upper()

    hour, minute = time.split(":") if ":" in time else (time, "0")

    hour = int(hour)
    minute = int(minute)

    if period == "PM" and hour != 12:
        hour += 12

    if period == "AM" and hour == 12:
        hour = 0

    return hour * 60 + minute

def generate_slots(start_time, end_time):

    start = parse_time(start_time)
    end = parse_time(end_time)

    slots = []

    current = start

    while current < end:

        hour = current // 60
        minute = current % 60

        period = "AM"

        if hour >= 12:
            period = "PM"

        display_hour = hour

        if hour > 12:
            display_hour = hour - 12

        if hour == 0:
            display_hour = 12

        if minute == 0:
            time_string = f"{display_hour} {period}"
        else:
            time_string = f"{display_hour}:30 {period}"

        slots.append(time_string)

        current += 30

    return slots

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
        "description": "Check whether a specific doctor is available on a specific date and time. Use this tool when the user provides a doctor, date, and time.",
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
        "additionalProperties":False 
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
    {
    "type": "function",
    "name": "find_doctor",
    "description": "Find a specific doctor by name.",
    "parameters": {
        "type": "object",
        "properties": {
            "name": {
                "type": "string",
                "description": "The doctor's name, such as Smith or Dr. Smith"
            }
        },
        "required": ["name"],
        "additionalProperties": False
    }
},
    {
    "type": "function",
    "name": "get_patient_appointments",
    "description": "Get all appointments booked for the current patient.",
    "parameters": {
        "type": "object",
        "properties": {
            "patient_name": {
                "type": "string",
                "description": "The patient's name"
            }
        },
        "required": ["patient_name"],
        "additionalProperties": False
    }
},
{
    "type": "function",
    "name": "find_doctor_by_specialty",
    "description": "Find doctors who specialize in a specific medical specialty.",
    "parameters": {
        "type": "object",
        "properties": {
            "specialty": {
                "type": "string",
                "description": "Medical specialty, such as Cardiology, Dermatology, Pediatrics, or General Medicine"
            }
        },
        "required": ["specialty"],
        "additionalProperties": False
    }
},
{
    "type": "function",
    "name": "get_available_slots",
    "description": "Get available appointment times for a doctor on a specific date.",
    "parameters": {
        "type": "object",
        "properties": {
            "doctor": {
                "type": "string",
                "description": "Doctor's name"
            },
            "date": {
                "type": "string",
                "description": "Appointment date"
            }
        },
        "required": [
            "doctor",
            "date"
        ],
        "additionalProperties": False
    }
},
]

@app.post("/chat")
def chat(request: ChatRequest):

    print(" USER:", request.message)

    # Save user's message
    messages.append({
        "role": "user",
        "content": request.message,
    })
#      English                      │             Spanish (type or say this)             │
#   ├──────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
#   │ Hi                                               │ Hola                                               │
#   ├──────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
#   │ May I see your doctors list?                     │ ¿Puedo ver la lista de doctores?                   │
#   ├──────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
#   │ I'd like to book an appointment with this doctor │ Me gustaría reservar una cita con el Dr. [Wilson]  │
#   ├──────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
#   │ …on this date and time                           │ para el [12 de octubre] a las [10:30 de la mañana] │
#   ├──────────────────────────────────────────────────┼────────────────────────────────────────────────────┤
#   │ Thanks                                           │ Gracias

    language = request.language # the prompt change for conversing 

    if language == "Spanish":
        language_instruction = """
    Respond entirely in Spanish.
    You are a friendly hospital receptionist.
    """
    else:
        language_instruction = """
    Respond entirely in English.
    You are a friendly hospital receptionist.
    """

    system_prompt = f"""
You are the virtual receptionist for City Hospital.

{language_instruction}

The current patient's name is {request.patient_name}.

You help patients:
- find doctors
- list doctors
- check appointment availability
- book appointments

Use the available tools whenever you need hospital information.

If the user asks for a list of doctors, use list_doctors.

If the user asks for a specific doctor, use find_doctor.

If the user provides a doctor, date, and time, use check_doctor_availability.

If the user asks about their appointments, use get_patient_appointments
with the current patient's name.

If the user wants to cancel an appointment, use cancel_appointment.

Before cancelling, make sure you know the doctor, date, and time.

Never cancel an appointment belonging to another patient.

If the user asks for a doctor based on a medical specialty,
use find_doctor_by_specialty.

For example:
"I need a heart doctor" means Cardiology.
"I need a skin doctor" means Dermatology.
"I need a doctor for my child" means Pediatrics.

If the user asks what times are available for a doctor on a particular date,
use get_available_slots.

For example:

"Can I see Dr. Smith tomorrow?"
"Do you have any times available with Dr. Smith on October 10?"

Use get_available_slots instead of checking one specific time.

IMPORTANT BOOKING RULES:

1. Always check availability before booking.
2. Never book an appointment without checking availability first.
3. After confirming that a requested time is available, ask the user
   whether they want to book it.
4. Only call book_doctor_appointment after the user clearly confirms.
5. If the user says yes, book the appointment using the doctor, date,
   and time from the conversation.
6. If the appointment is unavailable, do not book it.
7. If information is missing, ask the user for it.
8.Keep replies to one or two short sentences. Offer a few options, not full lists.
9. When booking, always use the current patient's name ({request.patient_name})
   as patient_name. Never ask the patient for their name.

Remember information from earlier messages in the conversation.

Do not invent doctors, working hours, availability, or appointments.

Be conversational and helpful.
"""

    response = client.responses.create(
        model="gpt-4o-mini",
        tools=tools,
        input=[
            {
                "role": "system",
                "content": system_prompt,
            },
            *messages,
        ],
    )

    print(" FIRST RESPONSE:", response.output)


    # the model can call several tools in a row (for example: check
    # availability, then book), so keep going until it answers with text
    tool_inputs = []

    for step in range(5):  # ponytail: max 5 tool rounds per message, raise if real flows need more

        tool_calls = [item for item in response.output if item.type == "function_call"]

        if not tool_calls:
            break

        for item in tool_calls:

            print(" TOOL CALLED:", item.name)
            print("ARGUMENTS:", item.arguments)

            arguments = json.loads(item.arguments)


            if item.name == "list_doctors":

                print(" Running list_doctors()")

                result = list_doctors()
            
            elif item.name == "find_doctor":
                print("running find doctor")

                result = find_doctor(
                    arguments["name"]
                )

            elif item.name == "check_doctor_availability":

                print("Running check_doctor_availability()")

                result = check_doctor_availability(
                    arguments["doctor"],
                    arguments["date"],
                    arguments["time"],
                )

            elif item.name == "book_doctor_appointment":

                print(" Running book_doctor_appointment()")

                result = book_doctor_appointment(
                    arguments["doctor"],
                    arguments["date"],
                    arguments["time"],
                    arguments["patient_name"],
                )
            
            elif item.name == "get_patient_appointments":
                print("running get patient appointment") 

                result = get_patient_appointments(
                    arguments["patient_name"]
                )
            
            elif item.name == "cancel_appointment":
                print("running cancellation") 

                result = cancel_appointment(
                    arguments["patient_name"],
                    arguments["doctor"],
        arguments["date"],
        arguments["time"],
                )
            
            elif item.name == "find_doctor_by_specialty":
                print("running find doctor tool") 

                result = find_doctor_by_specialty(arguments["specialty"])
            
            elif item.name == "get_available_slots":

                print("running get_available_slots()")

                result = get_available_slots(
                    arguments["doctor"],
                    arguments["date"],
                )


            else:

                result = {
                    "error": "Unknown tool"
                }

            print(" TOOL RESULT:", result)

            tool_inputs.append(item)
            tool_inputs.append({
                "type": "function_call_output",
                "call_id": item.call_id,
                "output": json.dumps(result),
            })

        response = client.responses.create(
            model="gpt-4o-mini",
            tools=tools,
            input=[
                {
                    "role": "system",
                    "content": system_prompt,
                },
                *messages,
                *tool_inputs,
            ],
        )

    response_text = response.output_text

    # never send empty text to text-to-speech (it crashes)
    if response_text == "":
        response_text = "Sorry, something went wrong. Could you say that again?"

    print(" FINAL RESPONSE:", response_text)

    messages.append({
        "role": "assistant",
        "content": response_text,
    })

    speech = client.audio.speech.create(
        model="gpt-4o-mini-tts",
        voice="nova",
        input=response_text,
        speed=1.25,
    )

    audio_base64 = base64.b64encode(speech.content).decode("utf-8")

    return {
        "response": response_text,
        "audio": audio_base64,
    }


    # result = json.loads(response.output_text)
    # if result["intent"] == "provide_date":
    #     conversation["date"] = result["date"] 

    #     return {
    #         "response":"great what time would you like the appointment?"
    #     }
    # if result["intent"] == "provide_time":

    #     conversation["time"] = result["time"]

    #     available = is_available(
    #         conversation["doctor"],
    #         conversation["date"],
    #         conversation["time"],
    #     )

    #     if available:
    #         return {
    #             "response": "That time is available. Would you like me to book it?"
    #         }
    #     else:
    #         return {
    #             "response": "Sorry, that time is already booked. Would you like another time?"
    #         }
    # if result["intent"] == "confirm_booking":

    #     booked = save_appointment(
    #         conversation["doctor"],
    #         conversation["date"],
    #         conversation["time"],
    #         conversation["patientName"],
    #     )

    #     if booked:
    #         return {
    #             "response": (
    #                 f"Perfect! Your appointment with "
    #                 f"{conversation['doctor']} on "
    #                 f"{conversation['date']} at "
    #                 f"{conversation['time']} has been booked."
    #             )
    #         }

    #     return {
    #         "response": "Sorry, that appointment is no longer available."

    #     }
    # if result["intent"] == "provide_name":

    #     conversation["patientName"] = result["name"]

    #     return {
    #         "response": f"Nice to meet you, {result['name']}! How can I help you today?"
    #     }
    
    # if result["intent"] == "list_doctors":

    #     doctor_list = ""

    #     for doctor in doctors:
    #         doctor_list += (
    #             f"{doctor['name']} - "
    #             f"{doctor['specialty']} - "
    #             f"{doctor['startTime']} to {doctor['endTime']}\n"
    #         )

    #     return {
    #         "response": "Here are our doctors:\n" + doctor_list
    #     }
    
    # if result["intent"] == "start_booking":

    #     return {
    #         "response": "Sure! What type of doctor would you like to see?"
    #     }

    # if result["intent"] == "find_doctor":

    #     specialty = result["specialty"]

    #     for doctor in doctors:

    #         if doctor["specialty"] == specialty:
    #             conversation["doctor"] = doctor["name"]


    #             return {
    #                 "response": (
    #                     f"We have {doctor['name']} in {doctor['specialty']}. "
    #                     f"They are available from {doctor['startTime']} "
    #                     f"to {doctor['endTime']}. "
    #                     "What day would you like an appointment?"
    #                 )
    #             }

    #     return {
    #         "response": "Sorry, we don't currently have a doctor for that specialty."
    #     }

    # if result["intent"] == "greeting":

    #     return {
    #         "response": "Hello! Welcome to City Hospital. How can I help you?"
    #     }

    # return {
    #     "response": "I can help you find a doctor or book an appointment."
    # }

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

@app.get("/appointments")
def list_appointments(patient: str):
    return {"appointments": get_patient_appointments(patient)}

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
    save_appointments()

    return {
        "success": True,
        "message": "Appointment booked successfully.",
    }

from fastapi.responses import Response 

# for speech model text to speech
class SpeechRequest(BaseModel):
    text: str

#  testing with speed endpoint but resulte din delay of voice so moving it chat itself 
# @app.post("/speech")
# def speech(request: SpeechRequest):

#     response = client.audio.speech.create(
#         model="gpt-4o-mini-tts",
#         voice="nova",
#         speed = 1.25,
#         input=request.text,
#     )

#     return Response(
#         content=response.content,
#         media_type="audio/mpeg",
#     )