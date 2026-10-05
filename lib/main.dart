import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'appointment.dart';

import 'dart:convert';

import 'speech_input.dart';
import 'doctor.dart';

import 'chat_message.dart';
import 'speech_output.dart';

import 'package:audioplayers/audioplayers.dart';

void main() {
  runApp(MaterialApp(home: LoginPage()));
}

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() {
    return LoginPageState();
  }
}

class HeadingHospital extends StatelessWidget {
  const HeadingHospital({super.key});

  @override
  Widget build(BuildContext context) {
    // final screenWidth = MediaQuery.of(context).size.width;
    // final isMobile = screenWidth < 600;
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.blue,
      child: const Text(
        'City Hospital',
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
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
          const HeadingHospital(),
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
              Navigator.pushReplacement(
                // for three lines
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      HomePage(patientName: nameController.text),
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

// inside the side bar it is profile section
class ProfilePage extends StatelessWidget {
  final String patientName;

  ProfilePage({required this.patientName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profile")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Profile",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 20),

            Text("Name", style: TextStyle(fontWeight: FontWeight.bold)),

            SizedBox(height: 5),

            Text(patientName, style: TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
// step 2 for side bar - appointments display

class AppointmentsPage extends StatelessWidget {
  final List<Appointment> appointments;

  AppointmentsPage({required this.appointments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Appointments")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: appointments.isEmpty
            ? Text("No appointments")
            : ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  Appointment appointment = appointments[index];

                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            appointment.doctorName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          SizedBox(height: 8),

                          Text("Date: ${appointment.date}"),
                          Text("Time: ${appointment.time}"),
                          Text("Patient: ${appointment.patientName}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

// for side bar firsts step is to test so made it as stateless now changed to stateful
class HomePage extends StatefulWidget {
  final String patientName;

  HomePage({required this.patientName});

  @override
  State<HomePage> createState() {
    return HomePageState();
  }
}

class HomePageState extends State<HomePage> {
  List<Appointment> appointments = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("City Hospital")),

      drawer: Drawer(
        // FOR SIDE BAR
        child: ListView(
          children: [
            DrawerHeader(
              child: Text("🏥 City Hospital", style: TextStyle(fontSize: 24)),
            ),

            ListTile(
              leading: Icon(Icons.person), // emoji for person
              title: Text("Profile"),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage(patientName: widget.patientName),
                  ),
                );
              },
            ),

            ListTile(
              leading: Icon(
                Icons.calendar_month,
              ), // emoji for appointments i.e calender
              title: Text("Appointments"),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        AppointmentsPage(appointments: appointments),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      body: ChatPage(
        patientName: widget.patientName,
        appointments: appointments,
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String patientName;
  final List<Appointment> appointments;
  ChatPage({required this.patientName, required this.appointments});
  @override
  State<ChatPage> createState() {
    return ChatPageState();
  }
}

class ChatPageState extends State<ChatPage> {
  TextEditingController controller = TextEditingController();

  List<ChatMessage> messages = [];
  String selectedLanguage = "English"; // multi language setup
  SpeechInput speechInput = SpeechInput(); // initializing speech input
  AudioPlayer audioPlayer = AudioPlayer(); // spech output
  @override
  void initState() {
    super.initState();

    messages.add(
      ChatMessage(
        text: "Hi ${widget.patientName}, welcome to City Hospital",
        isUser: false,
      ),
    );
    loadAppointments();
  }

  Future<void> newChat() async {
    setState(() {
      messages.clear();

      messages.add(
        ChatMessage(
          text: "Hi ${widget.patientName}, welcome to City Hospital",
          isUser: false,
        ),
      );
    });
    await speakResponse("Hi ${widget.patientName}, welcome to City Hospital");
  }

  Future<void> startListening() async {
    bool ready = await speechInput.initialize();
    // for start listening initally nothing wait for future until vpoice comes
    if (!ready) {
      return;
    }

    await speechInput.listen(
      (text) {
        setState(() {
          controller.text = text;
        });
      },
      () {
        sendMessage();
      },
    );
  }

  String patientName = "";
  String phoneNumber = "";

  String selectedDoctor = "";
  String selectedDate = "";

  int step = 0;

  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    //dynamic is added cause audio is involved
    var response = await http.post(
      Uri.parse("http://127.0.0.1:8000/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "message": message,
        "patient_name": widget.patientName,
        "language": selectedLanguage, // sendin which lang selected to backed so that prompt knows
      }),
    );

    var data = jsonDecode(response.body);

    return data;
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

  Future<List<Appointment>> getAppointments() async {
    var response = await http.get(
      Uri.parse(
        "http://127.0.0.1:8000/appointments"
        "?patient=${Uri.encodeComponent(widget.patientName)}",
      ),
    );

    var data = jsonDecode(response.body);

    List<Appointment> appointments = [];

    for (var appointment in data["appointments"]) {
      appointments.add(
        Appointment(
          doctorName: appointment["doctorName"],
          date: appointment["date"],
          time: appointment["time"],
          patientName: appointment["patientName"],
        ),
      );
    }

    return appointments;
  }

  Future<void> loadAppointments() async {
    List<Appointment> result = await getAppointments();
    widget.appointments.clear();
    widget.appointments.addAll(result);

    setState(() {
      // also fill HomePage's list, so the Appointments page in the menu sees them
    });
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

  Future<void> speakResponse(String text) async {
    var response = await http.post(
      Uri.parse("http://127.0.0.1:8000/speech"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text}),
    );

    if (response.statusCode == 200) {
      await audioPlayer.play(
        BytesSource(response.bodyBytes, mimeType: "audio/mpeg"),
      );
    }
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

    // String response = await sendChatMessage(userMessage);

    // setState(() {
    //   messages.add(ChatMessage(text: response, isUser: false));
    // });
    Map<String, dynamic> data = await sendChatMessage(userMessage);

    String response = data["response"];

    setState(() {
      messages.add(ChatMessage(text: response, isUser: false));
    });
    await loadAppointments();

    // some replies (tool calls) come back without audio
    // if (data["audio"] != null) {
    //   await audioPlayer.play(BytesSource(base64Decode(data["audio"])));
    // }
    if (data["audio"] != null) {
      print("AUDIO RECEIVED");
      print("Audio length: ${data["audio"].length}");

      await audioPlayer.play(
        BytesSource(base64Decode(data["audio"]), mimeType: "audio/mpeg"),
      );

      print("PLAY CALLED");
    } else {
      print("NO AUDIO RECEIVED");
    }
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
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "🏥 City Hospital\nVirtual Receptionist",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),

        ElevatedButton(onPressed: newChat, child: Text("New Chat")),

        DropdownButton<String>(
          // user can select spanish or english and converse
          value: selectedLanguage,
          items: [
            DropdownMenuItem(value: "English", child: Text("English")),
            DropdownMenuItem(value: "Spanish", child: Text("Español")),
          ],
          onChanged: (value) {
            setState(() {
              selectedLanguage = value!;
            });
          },
        ),

        Expanded(
          child: Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                ChatMessage message = messages[index];

                return Text(
                  "${message.isUser ? 'You: ' : 'Receptionist: '}${message.text}", // for tags in chat for receptionist and you
                );
              },
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: controller,
            onSubmitted: (value) {
              // enables the key board enter for text input
              sendMessage();
            },
            decoration: InputDecoration(
              hintText: "type a message.....",
              border: OutlineInputBorder(),
            ),
          ),
        ),

        IconButton(onPressed: startListening, icon: Icon(Icons.mic)),

        ElevatedButton(onPressed: sendMessage, child: Text("SEND")),
      ],
    );
  }
}
