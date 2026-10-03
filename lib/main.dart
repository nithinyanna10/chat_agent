import 'package:flutter/material.dart';

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

  List<String> messages = [
    "Hi welcome to city hospital, how can I help you today?",
  ];

  List<String> doctors = [
    "Dr. Smith - Cardiology - 9 AM to 3 PM",
    "Dr. Brown - Dermatology - 10 AM to 4 PM",
    "Dr. Jones - Pediatrics - 8 AM to 2 PM",
    "Dr. Wilson - General Medicine - 9 AM to 5 PM",
  ];

  int step = 0;

  void sendMessage() {
    String userMessage = controller.text;
    setState(() {
      messages.add("You: " + userMessage);

      if (step == 0) {
        messages.add("Receptionist:Nice to meet you what is your phone number");
        step = 1;
      } else if (step == 1) {
        messages.add(
          "receptionist:Receptionist: Thanks! What type of doctor would you like to see?",
        );
        step = 2;
      } else if (step == 2) {
        messages.add("receptionist  : here are our doctors:");
        for (String doctor in doctors) {
          messages.add(doctor);
        }
        step = 3;
      } else if (step == 3) {
        messages.add(
          "receptionist:great choice what day would you like the appointment?",
        );
        step = 4;
      } else if (step == 4) {
        messages.add("receptionsit:what time would you prefer?");
        step = 5;
      } else if (step == 5) {
        messages.add(
          "Receptionist: Perfect. Your appointment request has been recorded.",
        );
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
