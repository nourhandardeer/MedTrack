import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medtrack/NavigationBar/manage_page.dart';
import 'package:intl/intl.dart';
import 'package:medtrack/home.dart';
import '../services/notification_service.dart';

import '../services/firestore_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddAppointment extends StatefulWidget {
  const AddAppointment({super.key});

  @override
  State<AddAppointment> createState() => _AddAppointmentState();
}

class _AddAppointmentState extends State<AddAppointment> {
  bool _isLoading = false;

  List<String> suggestedDoctorNames = [];
  Map<String, Map<String, dynamic>> doctorDetailsMap = {};

  @override
  void initState() {
    super.initState();
    _loadDoctorSuggestions(); // Load previous doctor names
  }

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController doctorPhoneController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      setState(() => selectedDate = pickedDate);
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (pickedTime != null) {
      setState(() => selectedTime = pickedTime);
    }
  }

  Future<void> _saveAppointment() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (selectedDate == null ||
        selectedTime == null ||
        doctorNameController.text.isEmpty ||
        doctorPhoneController.text.isEmpty ||
        specialtyController.text.isEmpty ||
        locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });
    String uid = user!.uid;

    try {
      // Fetch the current user's document
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String? phoneNumber = userDoc['phone']; // Fetch user's phone number

      if (phoneNumber == null) {
        print("DEBUG: No phone number found for the current user.");
        return;
      }
      _firestoreService.saveData(
        collection: 'appointments',
        context: context,
        data: {
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'doctorName': doctorNameController.text,
          'doctorPhone': doctorPhoneController.text,
          'specialty': specialtyController.text,
          'location': locationController.text,
          'notes': notesController.text,
          'appointmentDate': DateFormat('yyyy-MM-dd').format(selectedDate!),
          'appointmentTime': selectedTime!.format(context),
          'createdAt': FieldValue.serverTimestamp(),
          //'linkedUserIds': linkedUsers,
        },
      );
      DateTime appointmentDateTime = DateTime(
        selectedDate!.year,
        selectedDate!.month,
        selectedDate!.day,
        selectedTime!.hour,
        selectedTime!.minute,
      );

      // Schedule notification 60 minutes before appointment
      DateTime today = DateTime.now();
      bool isSameDay = today.year == selectedDate!.year &&
                 today.month == selectedDate!.month &&
                 today.day == selectedDate!.day;
      if (isSameDay) {
      final DateTime reminderTime =
          appointmentDateTime.subtract(const Duration(minutes: 60));

      await NotificationService.scheduleNotification(
        id: appointmentDateTime.millisecondsSinceEpoch
            .remainder(100000), // unique-ish ID
        title: 'Appointment Reminder',
        bodyEn:
            'You have an appointment with Dr. ${doctorNameController.text} at ${selectedTime!.format(context)}',
        bodyAr:
            'لديك موعد مع الدكتور ${doctorNameController.text} في الساعة ${selectedTime!.format(context)}',
        scheduledTime: reminderTime,
        ttsMessageEn:
            'Reminder! Appointment with Dr. ${doctorNameController.text} at ${selectedTime!.format(context)}.',
        ttsMessageAr:
            'تذكير! لديك موعد مع الدكتور ${doctorNameController.text} في الساعة ${selectedTime!.format(context)}.',
      );
      print('Appointment Notification scheduled for $reminderTime');
      } else {
  print("Notification not scheduled because appointment is not today.");
}

      Navigator.pop(context);
    } catch (e) {
      print("Error saving medication: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadDoctorSuggestions() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      final snapshot = await _firestore
          .collection('doctors')
          .where('linkedUserIds', arrayContains: uid)
          .get();
      // Also get appointments directly created by the current user
      final ownSnapshot = await _firestore
          .collection('doctors')
          .where('userId', isEqualTo: uid)
          .get();

      Set<String> namesSet = {};
      Map<String, Map<String, dynamic>> detailsMap = {};

      for (var doc in snapshot.docs) {
        String name = doc['doctorName'];
        namesSet.add(name);

        detailsMap[name] = {
          'phone': doc['doctorPhone'],
          'specialty': doc['specialty'],
          'location': doc['location'],
        };
      }

      setState(() {
        suggestedDoctorNames = namesSet.toList();
        doctorDetailsMap = detailsMap;
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.newAppointment)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text( AppLocalizations.of(context)!.doctorName,
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) {
                      return suggestedDoctorNames.where((name) => name
                          .toLowerCase()
                          .contains(textEditingValue.text.toLowerCase()));
                    },
                    onSelected: (String selection) {
                      doctorNameController.text = selection;
                      final details = doctorDetailsMap[selection];
                      if (details != null) {
                        doctorPhoneController.text = details['phone'] ?? '';
                        specialtyController.text = details['specialty'] ?? '';
                        locationController.text = details['location'] ?? '';
                      }
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onEditingComplete) {
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onEditingComplete: onEditingComplete,
                        onChanged: (value) => doctorNameController.text = value,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
              _buildTextField( AppLocalizations.of(context)!.phone, doctorPhoneController),
              _buildTextField(AppLocalizations.of(context)!.specialty, specialtyController),
              _buildTextField(AppLocalizations.of(context)!.location, locationController),
              _buildTextField( AppLocalizations.of(context)!.notes, notesController),
               Text(AppLocalizations.of(context)!.date,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedDate != null
                        ? DateFormat('EEE, dd MMM yyyy').format(selectedDate!)
                        : AppLocalizations.of(context)!.selectDate,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
               Text(AppLocalizations.of(context)!.time,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => _selectTime(context),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    selectedTime != null
                        ? selectedTime!.format(context)
                        : AppLocalizations.of(context)!.selectTime,
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveAppointment,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                      )
                    :  Text(AppLocalizations.of(context)!.save,
                        style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
