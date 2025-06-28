import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:medtrack/main.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _profileImageUrl = "images/user.png";

  // Controllers for user input
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _ageController = TextEditingController();
  TextEditingController _illnesses = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load existing user data
  void _loadUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _profileImageUrl = data['profileImage']?.isNotEmpty == true
              ? data['profileImage']
              : "images/user.png";
          _firstNameController.text = data['firstName'] ?? "";
          _lastNameController.text = data['lastName'] ?? "";
          _phoneController.text = data['phone'] ?? "";
          _ageController.text = data['age'] ?? "Unknown";
          _illnesses.text = data['illnesses'] ?? "No illnesses specified";
        });
      }
    }
  }

  bool _isLoading = false;

  Future<void> pickAndUploadProfileImage() async {
    setState(() {
      _isLoading = true;
    });
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    } // User didn't pick an image

    final file = File(pickedFile.path);
    final cloudinaryUrl =
        Uri.parse("https://api.cloudinary.com/v1_1/defwfev8k/image/upload");

    try {
      // Create a multipart request to upload the image
      final request = http.MultipartRequest('POST', cloudinaryUrl)
        ..fields['upload_preset'] = 'medtrack'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final jsonResponse = json.decode(resStr);
        final imageUrl = jsonResponse['secure_url'];

        // Update the profile image URL in Firestore
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'profileImage': imageUrl,
          });

          // Update the local state with the new image URL
          setState(() {
            _profileImageUrl = imageUrl;
            _isLoading = false;
          });

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.profileImageUpdatedSuccess),),
          );
        }
      } else {
        throw Exception(Text(AppLocalizations.of(context)!.profileImageUpdatedFailed),);
      }
    } catch (e) {
      // Handle any errors during the upload process
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading image: $e")),
      );
    }
  }

  // Update user details in Firestore (UID remains unchanged)
  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      User? user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'profileImage': _profileImageUrl,
          'firstName': _firstNameController.text,
          'lastName': _lastNameController.text,
          'phone': _phoneController.text,
          'age': _ageController.text, // Convert age to integer
          'illnesses': _illnesses.text,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.profileupdated),),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.eeditProfile),),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: pickAndUploadProfileImage,
                  child: _isLoading
                      ? CircularProgressIndicator()
                      : CircleAvatar(
                          key: ValueKey(_profileImageUrl),
                          radius: 60,
                          backgroundImage: _profileImageUrl.startsWith('http')
                              ? NetworkImage(_profileImageUrl)
                              : AssetImage("images/user.png") as ImageProvider,
                          backgroundColor: Colors.transparent,
                        ),
                ),
                SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.imageChange),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.firstName),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your first name" : null,
                ),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.lastName),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your last name" : null,
                ),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(labelText:AppLocalizations.of(context)!.phone),
                  validator: (value) =>
                      value!.isEmpty ? "Enter your phone number" : null,
                ),
                TextFormField(
                  controller: _ageController,
                  decoration: InputDecoration(labelText:AppLocalizations.of(context)!.age),
                  //  validator: (value) => value!.isEmpty ? "Enter your age" : null,
                ),
                TextFormField(
                  controller: _illnesses,
                  decoration: InputDecoration(labelText: AppLocalizations.of(context)!.illnesses),
                  keyboardType: TextInputType.number,
                  //  validator: (value) => value!.isEmpty ? "Enter your illnesses" : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _updateProfile,
                  child: Text(AppLocalizations.of(context)!.saveChanges),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
