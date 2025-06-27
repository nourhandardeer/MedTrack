// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class EditDoctorPage extends StatefulWidget {
//   final String doctorId;
//   final Map<String, dynamic> initialData;
//
//   const EditDoctorPage({
//     super.key,
//     required this.doctorId,
//     required this.initialData,
//   });
//
//   @override
//   State<EditDoctorPage> createState() => _EditDoctorPageState();
// }
//
// class _EditDoctorPageState extends State<EditDoctorPage> {
//   final _formKey = GlobalKey<FormState>();
//
//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;
//   late TextEditingController _specialtyController;
//   late TextEditingController _locationController;
//   late TextEditingController _notesController;
//
//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.initialData['doctorName']);
//     _phoneController = TextEditingController(text: widget.initialData['doctorPhone']);
//     _specialtyController = TextEditingController(text: widget.initialData['specialty']);
//     _locationController = TextEditingController(text: widget.initialData['location']);
//     _notesController = TextEditingController(text: widget.initialData['notes']);
//   }
//
//   Future<void> _saveChanges() async {
//     if (!_formKey.currentState!.validate()) return;
//
//     await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).update({
//       'doctorName': _nameController.text,
//       'doctorPhone': _phoneController.text,
//       'specialty': _specialtyController.text,
//       'location': _locationController.text,
//       'notes': _notesController.text,
//     });
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       const SnackBar(content: Text("Doctor updated successfully."), backgroundColor: Colors.green),
//     );
//     Navigator.pop(context);
//   }
//
//   Widget _buildCardField({
//     required IconData icon,
//     required String label,
//     required TextEditingController controller,
//     bool requiredField = true,
//     TextInputType? keyboardType,
//   }) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 8),
//       child: ListTile(
//         leading: Icon(icon, color: Colors.blue),
//         title: TextFormField(
//           controller: controller,
//           keyboardType: keyboardType,
//           decoration: InputDecoration(
//             labelText: label,
//             border: InputBorder.none,
//           ),
//           validator: requiredField
//               ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
//               : null,
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Edit Doctor"),
//         backgroundColor: Colors.white,
//         foregroundColor: Colors.black,
//         elevation: 1,
//       ),
//       backgroundColor: Colors.grey[100],
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               _buildCardField(icon: Icons.person, label: "Doctor Name", controller: _nameController),
//               _buildCardField(icon: Icons.phone, label: "Phone", controller: _phoneController, keyboardType: TextInputType.phone),
//               _buildCardField(icon: Icons.medical_services, label: "Specialty", controller: _specialtyController),
//               _buildCardField(icon: Icons.location_on, label: "Location", controller: _locationController),
//               _buildCardField(icon: Icons.note, label: "Notes", controller: _notesController, requiredField: false),
//               const SizedBox(height: 24),
//               ElevatedButton.icon(
//                 onPressed: _saveChanges,
//                 icon: const Icon(Icons.save),
//                 label: const Text("Save Changes"),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   minimumSize: const Size.fromHeight(50),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/PhoneValidator.dart';

class EditDoctorPage extends StatefulWidget {
  final String doctorId;
  final Map<String, dynamic> initialData;

  const EditDoctorPage({
    super.key,
    required this.doctorId,
    required this.initialData,
  });

  @override
  State<EditDoctorPage> createState() => _EditDoctorPageState();
}

class _EditDoctorPageState extends State<EditDoctorPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _specialtyController;
  late TextEditingController _locationController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialData['doctorName']);
    _phoneController = TextEditingController(text: widget.initialData['doctorPhone']);
    _specialtyController = TextEditingController(text: widget.initialData['specialty']);
    _locationController = TextEditingController(text: widget.initialData['location']);
    _notesController = TextEditingController(text: widget.initialData['notes']);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseFirestore.instance.collection('doctors').doc(widget.doctorId).update({
      'doctorName': _nameController.text,
      'doctorPhone': _phoneController.text,
      'specialty': _specialtyController.text,
      'location': _locationController.text,
      'notes': _notesController.text,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Doctor updated successfully."), backgroundColor: Colors.green),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Doctor"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildCardField(icon: Icons.person, label: "Doctor Name", controller: _nameController),
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
