import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/PhoneValidator.dart';

class EditAppointmentPage extends StatefulWidget {
  final String appointmentId;
  final Map<String, dynamic> initialData;

  const EditAppointmentPage({
    super.key,
    required this.appointmentId,
    required this.initialData,
  });

  @override
  State<EditAppointmentPage> createState() => _EditAppointmentPageState();
}

class _EditAppointmentPageState extends State<EditAppointmentPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _doctorNameController;
  late TextEditingController _phoneController;
  late TextEditingController _specialtyController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;
  late TextEditingController _dateController;
  late TextEditingController _timeController;

  @override
  void initState() {
    super.initState();
    _doctorNameController = TextEditingController(text: widget.initialData['doctorName']);
    _phoneController = TextEditingController(text: widget.initialData['doctorPhone']);
    _specialtyController = TextEditingController(text: widget.initialData['specialty']);
    _locationController = TextEditingController(text: widget.initialData['location']);
    _notesController = TextEditingController(text: widget.initialData['notes']);
    _dateController = TextEditingController(text: widget.initialData['appointmentDate']);
    _timeController = TextEditingController(text: widget.initialData['appointmentTime']);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('appointments').doc(widget.appointmentId).update({
      'doctorName': _doctorNameController.text,
      'doctorPhone': _phoneController.text,
      'specialty': _specialtyController.text,
      'location': _locationController.text,
      'notes': _notesController.text,
      'appointmentDate': _dateController.text,
      'appointmentTime': _timeController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Appointment updated successfully."), backgroundColor: Colors.green),
    );
    Navigator.pop(context);
  }

  Widget _buildCardField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    bool requiredField = true,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
          validator: validator ??
              (requiredField
                  ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
                  : null),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text("Edit Appointment"),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCardField(icon: Icons.person, label: "Doctor Name", controller: _doctorNameController),
              _buildCardField(
                icon: Icons.phone,
                label: "Phone",
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: PhoneValidator.validatePhoneNumber,
              ),
              _buildCardField(icon: Icons.medical_services, label: "Specialty", controller: _specialtyController),
              _buildCardField(icon: Icons.location_on, label: "Location", controller: _locationController),
              _buildCardField(icon: Icons.note, label: "Notes", controller: _notesController, requiredField: false),
              _buildCardField(icon: Icons.date_range, label: "Date", controller: _dateController),
              _buildCardField(icon: Icons.access_time, label: "Time", controller: _timeController),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _saveChanges,
                icon: const Icon(Icons.save),
                label: const Text("Save Changes"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

