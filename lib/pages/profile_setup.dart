import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medtrack/home.dart';
import 'package:http/http.dart' as http;

import '../EmergencyContactHelper.dart';
import '../services/PhoneValidator.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ProfileSetupPage extends StatefulWidget {
  final String userId;
  final String firstName;
  final String lastName;
  final String phone;

  const ProfileSetupPage({
    super.key,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
  });

  @override
  _ProfileSetupPageState createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  File? _profileImageFile;
  String? _uploadedImageUrl;
  final ImagePicker _picker = ImagePicker();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phone;
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _illnessesController = TextEditingController();
  List<Map<String, String>> emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _phone = TextEditingController(text: widget.phone);
  }

  bool _isUploadingImage = false;

  Future<void> pickAndUploadProfileImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    setState(() {
      _profileImageFile = File(pickedFile.path);
      _isUploadingImage = true;
    });

    final cloudinaryUrl =
        Uri.parse("https://api.cloudinary.com/v1_1/defwfev8k/image/upload");

    final request = http.MultipartRequest('POST', cloudinaryUrl)
      ..fields['upload_preset'] = 'medtrack'
      ..files.add(
          await http.MultipartFile.fromPath('file', _profileImageFile!.path));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User not logged in");
      return;
    }

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final jsonResponse = json.decode(resStr);
      final imageUrl = jsonResponse['secure_url'];

      if (!mounted) return;

      setState(() {
        _uploadedImageUrl = imageUrl;
        _isUploadingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Image uploaded successfully!")),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'profileImage': imageUrl,
        });
      }
    } else {
      final resStr = await response.stream.bytesToString();
      print("Image upload failed: $resStr");
      setState(() {
        _isUploadingImage = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload image")),
      );
    }
  }

  void _saveProfile() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      String userId = widget.userId;

      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User not logged in!')),
        );
        return;
      }

      await firestore.collection('users').doc(userId).set({
        'email': user.email,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'profileImage': _uploadedImageUrl ?? "images/user.png",
        'age': _ageController.text.trim(),
        'illnesses': _illnessesController.text.trim(),
        'phone': PhoneValidator.normalizePhone(_phone.text.trim()),

      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile saved successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (error) {
      print("Error saving profile: $error");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to save profile. Try again!")),
      );
    }
  }
  void _addEmergencyContact() {
    EmergencyContactHelper.EmergencyContactDialog(context, (newContact) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        // Normalize the phone number
        String normalizedPhone = PhoneValidator.normalizePhone(newContact["phone"]!);
        newContact["phone"] = normalizedPhone;

        // Store under user's emergencyContacts subcollection
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('emergencyContacts')
            .add(newContact);

        // Store in main emergencyContacts collection
        await FirebaseFirestore.instance
            .collection('emergencyContacts')
            .doc(normalizedPhone)
            .set({
          ...newContact,
          'linkedPatientId': user.uid,
        });

        if (!mounted) return;

        setState(() {
          emergencyContacts.add(newContact);
        });

        print("Emergency contact added successfully.");
      } catch (e) {
        print("Error adding contact: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileImage = _uploadedImageUrl != null
        ? NetworkImage(_uploadedImageUrl!)
        : AssetImage("images/user.png") as ImageProvider;

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.profileSetup)),
      body: Padding(
        padding: EdgeInsets.all(15.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickAndUploadProfileImage,
              child: _isUploadingImage
                  ? CircularProgressIndicator()
                  : CircleAvatar(
                      radius: 60,
                      backgroundImage: profileImage,
                      backgroundColor: Colors.transparent,
                    ),
            ),
            SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.addProfilePhoto),
            SizedBox(height: 20),
            TextField(
              controller: _ageController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.age),
              maxLines: 3,
            ),
            TextField(
              controller: _illnessesController,
              decoration: InputDecoration(labelText: AppLocalizations.of(context)!.illnesses),
              maxLines: 3,
            ),
            SizedBox(height: 20),
            Text(AppLocalizations.of(context)!.emergencyContacts,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: emergencyContacts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(emergencyContacts[index]["name"]!),
                    subtitle: Text(" ${emergencyContacts[index]["phone"]!}"),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          emergencyContacts.removeAt(index);
                        });
                      },
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _addEmergencyContact,
              child: Text(AppLocalizations.of(context)!.addEmergencyContact),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfile,
              child: Text(AppLocalizations.of(context)!.saveProfile),
            ),
          ],
        ),
      ),
    );
  }
}
