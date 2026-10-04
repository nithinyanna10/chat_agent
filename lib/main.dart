import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'dart:convert';

import 'doctor.dart';

import 'chat_message.dart';

void main() {
  runApp(MaterialApp(home: LoginPage()));
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() {
    return LoginPageState();
  }
}

class LoginPageState extends State<LoginPage> {
  TextEditingController nameController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "🏥 City Hospital",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          SizedBox(height: 10),

          Text("Virtual Receptionist"),

          SizedBox(height: 30),

          Padding(
            padding: EdgeInsets.all(20),
            child: TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: "Enter your name",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatPage(patientName: nameController.text),
                ),
              );
            },
            child: Text("Continue"),
          ),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String patientName;
  ChatPage({required this.patientName});
  @override
  State<ChatPage> createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> {
  TextEditingController controller = TextEditingController();

  List<ChatMessage> messages = [];

  @override
  void initState() {
    super.initState();

    messages.add(
      ChatMessage(
        text: "Hi ${widget.patientName}, welcome to City Hospital",
        isUser: false,
      ),
    );
  }

  String patientName = "";
  String phoneNumber = "";

  String selectedDoctor = "";
  String selectedDate = "";

  int step = 0;

  Future<String> sendChatMessage(String message) async {
    var response = await http.post(
      Uri.parse("http://127.0.0.1:8000/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "message": message,
        "patient_name": widget.patientName,
      }),
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
      messages.add(ChatMessage(text: userMessage, isUser: true));
    });

    controller.clear();

    String response = await sendChatMessage(userMessage);

    setState(() {
      messages.add(ChatMessage(text: response, isUser: false));
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
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              "🏥 City Hospital\nVirtual Receptionist",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),

          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(),
                borderRadius: BorderRadius.circular(12),
              ), // for border and box decoration
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  ChatMessage message = messages[index];

                  return Text(message.text);
                },
              ),
            ),
          ),

          Padding(
            padding: EdgeInsetsGeometry.symmetric(horizontal: 16),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "type a message.....",
                border: OutlineInputBorder(),
              ),
            ),
          ),

          ElevatedButton(onPressed: sendMessage, child: Text("SEND")),
        ],
      ),
    );
  }
}
