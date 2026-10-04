import 'doctor.dart';
import 'appointment.dart';

class Hospital {
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

  void bookAppointment(
    String doctorName,
    String date,
    String time,
    String patientName,
  ) {
    appointments.add(
      Appointment(
        doctorName: doctorName,
        date: date,
        time: time,
        patientName: patientName,
      ),
    );
  }
}
