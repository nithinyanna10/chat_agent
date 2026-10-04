import 'package:flutter/material.dart';

import 'doctor.dart';

import 'appointment.dart';

void main() {
  runApp(MaterialApp(home: ChatPage()));
}

class ChatPage extends StatefulWidget {
  @override
  State<ChatPage> createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> {
  TextEditingController controller = TextEditingController();
  String patientName = "";
  String phoneNumber = "";

  List<String> messages = [
    "Hi welcome to city hospital, how can I help you today?",
  ];

  List<Doctor> doctors = [
    Doctor(
      name: "Dr. Smith",
      specialty: "Cardiology",
      startTime: "9 AM",
      endTime: "3 PM",
    ),
    Doctor(
      name: "Dr. Brown",
      specialty: "Dermatology",
      startTime: "10 AM",
      endTime: "4 PM",
    ),
    Doctor(
      name: "Dr. Jones",
      specialty: "Pediatrics",
      startTime: "8 AM",
      endTime: "2 PM",
    ),
    Doctor(
      name: "Dr. Wilson",
      specialty: "General Medicine",
      startTime: "9 AM",
      endTime: "5 PM",
    ),
  ];

  List<Appointment> appointments = [
    Appointment(
      doctorName: "Dr. Smith",
      date: "October 10",
      time: "10 AM",
      patientName: "John",
    ),
    Appointment(
      doctorName: "Dr. Smith",
      date: "October 10",
      time: "11 AM",
      patientName: "Sarah",
    ),
  ];

  bool isAvailable(String doctorName, String date, String time) {
    for (Appointment appointment in appointments) {
      if (appointment.doctorName == doctorName &&
          appointment.date == date &&
          appointment.time == time) {
        return false;
      }
    }
    return true;
  }

  String selectedDoctor = "";
  String selectedDate = "";

  int step = 0;

  void sendMessage() {
    String userMessage = controller.text;
    // print(isAvailable("Dr. Smith", "October 10", "10 AM"));
    // print(isAvailable("Dr. Smith", "October 10", "12 PM"));
    setState(() {
      messages.add("You: " + userMessage);

      if (step == 0) {
        patientName = userMessage;
        messages.add("Receptionist:Nice to meet you what is your phone number");
        step = 1;
      } else if (step == 1) {
        phoneNumber = userMessage;
        messages.add(
          "Receptionist: Thanks! What type of doctor would you like to see?",
        );
        step = 2;
      } else if (step == 2) {
        messages.add("receptionist  : here are our doctors:");
        for (Doctor doctor in doctors) {
          messages.add(
            "${doctor.name}-${doctor.specialty}-${doctor.startTime} to ${doctor.endTime}",
          );
        }
        step = 3;
      } else if (step == 3) {
        selectedDoctor = userMessage;
        messages.add(
          "receptionist:great choice what day would you like the appointment?",
        );
        step = 4;
      } else if (step == 4) {
        selectedDate = userMessage;
        messages.add("receptionsit:what time would you prefer?");
        step = 5;
      } else if (step == 5) {
        bool available = isAvailable(selectedDoctor, selectedDate, userMessage);
        if (available) {
          appointments.add(
            Appointment(
              doctorName: selectedDoctor,
              date: selectedDate,
              time: userMessage,
              patientName: patientName,
            ),
          );
          messages.add(
            "Receptionist: Perfect. Your appointment request has been recorded.",
          );
        } else {
          messages.add("Receptionist: Sorry, that time is already booked.");
        }
        step = 6;
      }
    });
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text("Virtual Assistant"),
          Text(messages.join("\n")),
          TextField(controller: controller),
          ElevatedButton(onPressed: sendMessage, child: Text("SEND")),
        ],
      ),
    );
  }
}
