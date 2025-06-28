import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/PhoneValidator.dart';
import '../services/firestore_service.dart';
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
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isLoading = false;
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final TextEditingController doctorNameController = TextEditingController();
  final TextEditingController doctorPhoneController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  List<String> suggestedDoctorNames = [];
  Map<String, Map<String, dynamic>> doctorDetailsMap = {};

  @override
  void initState() {
    super.initState();
    _loadDoctorSuggestions();
  }

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
    if (!_formKey.currentState!.validate() || selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final phoneNumber = userDoc['phone'];
      if (phoneNumber == null) throw Exception('Phone number not found.');

      final appointmentDateTime = DateTime(
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
        id: appointmentDateTime.millisecondsSinceEpoch.remainder(100000),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

      final ownSnapshot = await _firestore
          .collection('doctors')
          .where('userId', isEqualTo: uid)
          .get();

      Set<String> namesSet = {};
      Map<String, Map<String, dynamic>> detailsMap = {};

      for (var doc in [...snapshot.docs, ...ownSnapshot.docs]) {
        final name = doc['doctorName'];
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String? Function(String?) validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Doctor Name',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Autocomplete<String>(
                  optionsBuilder: (textEditingValue) {
                    return suggestedDoctorNames.where((name) =>
                        name.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                  },
                  onSelected: (selection) {
                    doctorNameController.text = selection;
                    final details = doctorDetailsMap[selection];
                    if (details != null) {
                      doctorPhoneController.text = details['phone'] ?? '';
                      specialtyController.text = details['specialty'] ?? '';
                      locationController.text = details['location'] ?? '';
                    }
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      onEditingComplete: onEditingComplete,
                      validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Doctor name is required' : null,
                      onChanged: (value) => doctorNameController.text = value,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  label: 'Doctor Phone',
                  controller: doctorPhoneController,
                  validator: (value) => PhoneValidator.validatePhoneNumber(value),
                ),
                _buildTextField(
                  label: 'Specialty',
                  controller: specialtyController,
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Specialty is required' : null,
                ),
                _buildTextField(
                  label: 'Location',
                  controller: locationController,
                  validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Location is required' : null,
                ),
                _buildTextField(
                  label: 'Notes (Optional)',
                  controller: notesController,
                  validator: (value) => null,
                ),
                const Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectDate(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedDate != null
                          ? DateFormat('EEE, dd MMM yyyy').format(selectedDate!)
                          : 'Select a date',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _selectTime(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      selectedTime != null
                          ? selectedTime!.format(context)
                          : 'Select a time',
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Appointment', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

