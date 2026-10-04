import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'doctor.dart';

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

  String selectedDoctor = "";
  String selectedDate = "";

  int step = 0;

  List<String> messages = [
    "Hi welcome to city hospital, how can I help you today?",
  ];

  Future<String> sendChatMessage(String message) async {
    var response = await http.post(
      Uri.parse("http://127.0.0.1:8000/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );

    var data = jsonDecode(response.body);

    return data["response"];
  }

  Future<List<Doctor>> getDoctors() async {
    var response = await http.get(Uri.parse("http://127.0.0.1:8000/doctors"));
    var data = jsonDecode(response.body);
    List<Doctor> doctors = [];

    for (var doctor in data["doctors"]) {
      doctors.add(
        Doctor(
          name: doctor["name"],
          specialty: doctor["specialty"],
          startTime: doctor["startTime"] ?? "",
          endTime: doctor["endTime"] ?? "",
        ),
      );
    }

    return doctors;
  }

  Future<bool> bookAppointment(
    String doctor,
    String date,
    String time,
    String patientname,
  ) async {
    var response = await http.post(
      Uri.parse("http://127.0.0.1:8000/appointments"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "doctorName": doctor,
        "date": date,
        "time": time,
        "patientName": patientname,
      }),
    );

    print(response.body);

    return response.body.contains('"success":true');
  }

  Future<bool> checkAvailability(
    String doctor,
    String date,
    String time,
  ) async {
    var response = await http.get(
      Uri.parse(
        "http://127.0.0.1:8000/availability"
        "?doctor=${Uri.encodeComponent(doctor)}"
        "&date=${Uri.encodeComponent(date)}"
        "&time=${Uri.encodeComponent(time)}",
      ),
    );

    print(response.body);

    return response.body.contains('"available":true');
  }

  Future<void> sendMessage() async {
    String userMessage = controller.text;

    if (userMessage.isEmpty) {
      return;
    }

    setState(() {
      messages.add("You: " + userMessage);
    });

    controller.clear();

    String response = await sendChatMessage(userMessage);

    setState(() {
      messages.add("Receptionist: " + response);
    });
  }

  // Future<void> sendMessage() async {
  //   String userMessage = controller.text;

  //   // talk to the backend.
  //   if (step == 5) {
  //     messages.add("You: " + userMessage);

  //     bool available = await checkAvailability(
  //       selectedDoctor,
  //       selectedDate,
  //       userMessage,
  //     );

  //     bool booked = false;

  //     if (available) {
  //       booked = await bookAppointment(
  //         selectedDoctor,
  //         selectedDate,
  //         userMessage,
  //         patientName,
  //       );
  //     }

  //     setState(() {
  //       if (booked) {
  //         messages.add(
  //           "Receptionist: Perfect. Your appointment request has been recorded.",
  //         );
  //       } else {
  //         messages.add("Receptionist: Sorry, that time is already booked.");
  //       }

  //       step = 6;
  //     });

  //     controller.clear();

  //     return;
  //   }

  //   // STEP 2 is special because we are getting doctors from the backend.
  //   if (step == 2) {
  //     messages.add("You: " + userMessage);

  //     List<Doctor> doctors = await getDoctors();

  //     setState(() {
  //       messages.add("Receptionist: Here are our doctors:");

  //       for (Doctor doctor in doctors) {
  //         messages.add(
  //           "${doctor.name} - ${doctor.specialty} - "
  //           "${doctor.startTime} to ${doctor.endTime}",
  //         );
  //       }

  //       step = 3;
  //     });

  //     controller.clear();

  //     return;
  //   }

  //   // All the normal conversation steps.
  //   setState(() {
  //     messages.add("You: " + userMessage);

  //     if (step == 0) {
  //       patientName = userMessage;

  //       messages.add(
  //         "Receptionist: Nice to meet you. What is your phone number?",
  //       );

  //       step = 1;
  //     } else if (step == 1) {
  //       phoneNumber = userMessage;

  //       messages.add(
  //         "Receptionist: Thanks! What type of doctor would you like to see?",
  //       );

  //       step = 2;
  //     } else if (step == 3) {
  //       selectedDoctor = userMessage;

  //       messages.add(
  //         "Receptionist: Great choice. What day would you like the appointment?",
  //       );

  //       step = 4;
  //     } else if (step == 4) {
  //       selectedDate = userMessage;

  //       messages.add("Receptionist: What time would you prefer?");

  //       step = 5;
  //     }
  //   });

  //   controller.clear();
  // }

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
