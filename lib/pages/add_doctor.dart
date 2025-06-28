import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firestore_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddDoctor extends StatefulWidget {
  @override
  _AddDoctorState createState() => _AddDoctorState();
}

class _AddDoctorState extends State<AddDoctor> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController specialtyController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  bool isLoading = false;

  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> _saveDoctor() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (nameController.text.isEmpty ||
        phoneController.text.isEmpty ||
        specialtyController.text.isEmpty ||
        locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    setState(() {
      isLoading = true;
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
        collection: 'doctors',
        context: context,
        data: {
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'doctorName': nameController.text,
          'doctorPhone': phoneController.text,
          'specialty': specialtyController.text,
          'location': locationController.text,
          'createdAt': FieldValue.serverTimestamp(),
          //'linkedUserIds': linkedUsers,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Doctor saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print("Error saving doctor: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving doctor: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool isOptional = false,
    TextStyle? style,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: style,
      validator: (value) {
        if (!isOptional && (value == null || value.isEmpty)) {
          return 'Please enter $label';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: isOptional ? '$label (Optional)' : label,
        labelStyle: style,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.newDoctor)),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      buildTextField(
                          controller: nameController,
                          label: AppLocalizations.of(context)!.doctorName,
                          style: TextStyle(color: Colors.black)),
                      SizedBox(height: 16),
                      buildTextField(
                          controller: phoneController,
                          label: AppLocalizations.of(context)!.phone,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(color: Colors.black)),
                      SizedBox(height: 16),
                      buildTextField(
                          controller: specialtyController,
                          label: AppLocalizations.of(context)!.specialty,
                          style: TextStyle(color: Colors.black)),
                      SizedBox(height: 16),
                      buildTextField(
                          controller: locationController,
                          label: AppLocalizations.of(context)!.location,
                          style: TextStyle(color: Colors.black)),
                      SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              _saveDoctor();
                            }
                          },
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(AppLocalizations.of(context)!.save,
                                style: TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
