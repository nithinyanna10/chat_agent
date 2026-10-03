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

  String message = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Text(message),

          TextField(controller: controller),

          ElevatedButton(
            onPressed: () {
              setState(() {
                message = controller.text;
              });
            },
            child: Text("SEND"),
          ),
        ],
      ),
    );
  }
}
