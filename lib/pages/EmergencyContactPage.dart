import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../EmergencyContactHelper.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:medtrack/main.dart';

class EmergencyContactPage extends StatefulWidget {
  const EmergencyContactPage({super.key});

  @override
  _EmergencyContactPageState createState() => _EmergencyContactPageState();
}
Map<String, dynamic>? patientLocation;

class _EmergencyContactPageState extends State<EmergencyContactPage> {
  List<Map<String, dynamic>> _emergencyContacts = [];
  String? linkedPatientId;
  Map<String, dynamic>? patientData;

  @override
  void initState() {
    super.initState();
    _fetchEmergencyContacts();
    _fetchLinkedPatientData();
  }

  /// Fetch Emergency Contacts for Logged-In User
  Future<void> _fetchEmergencyContacts() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emergencyContacts')
          .get();

      setState(() {
        _emergencyContacts = snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
      });
    } catch (e) {
      print("Error fetching contacts: $e");
    }
  }

  /// Fetch Linked Patient Data for Emergency Contact
   Future<void> _fetchLinkedPatientData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    QuerySnapshot contactQuery = await FirebaseFirestore.instance
        .collection('emergencyContacts')
        .where('phone', isEqualTo: user.phoneNumber)
        .get();

    if (contactQuery.docs.isNotEmpty) {
      String linkedPatientId = contactQuery.docs.first['linkedPatientId'];

      FirebaseFirestore.instance
          .collection('users')
          .doc(linkedPatientId)
          .snapshots()
          .listen((patientDoc) {
        if (patientDoc.exists) {
          setState(() {
            patientData = patientDoc.data();
             if (patientData != null && patientData!['location'] != null) {
            patientLocation = Map<String, dynamic>.from(patientData!['location']);
          }
          });
        }
      });
    }
  }
  /// Add Emergency Contact
  void _addEmergencyContact() {
    EmergencyContactHelper.EmergencyContactDialog(context, (newContact) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      try {
        // Store contact under the patient's emergencyContacts collection
        DocumentReference ref = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('emergencyContacts')
            .add(newContact);

        // Also store a reference under emergencyContacts collection (for lookup)
        await FirebaseFirestore.instance
            .collection('emergencyContacts')
            .doc(newContact["phone"]) // Using email as the document ID
            .set({
          ...newContact,
          'linkedPatientId': user.uid, // Link this contact to the patient
        });

        setState(() {
          _emergencyContacts.add(newContact);
        });

        print("Emergency contact added successfully.");
      } catch (e) {
        print("Error adding contact: $e");
      }
    });
  }

  /// Delete Emergency Contact
  void _deleteEmergencyContact(Map<String, dynamic> contact) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emergencyContacts')
          .where('phone', isEqualTo: contact['phone'])
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      await FirebaseFirestore.instance
          .collection('emergencyContacts')
          .doc(contact['phone'])
          .delete();

      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: contact['phone'])
          .get();

      for (var doc in userSnapshot.docs) {
        await doc.reference.delete();
      }

      setState(() {
        _emergencyContacts.remove(contact);
      });

      print("Contact deleted successfully.");
    } catch (e) {
      print("Error deleting contact: $e");
    }
  }

  /// Send Push Notification to Emergency Contacts
  void _sendPushNotification(String token, String title, String body) async {
    const String serverKey = 'YOUR_SERVER_KEY'; // Replace with Firebase server key

    final response = await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverKey',
      },
      body: jsonEncode({
        'to': token,
        'notification': {
          'title': title,
          'body': body,
        },
      }),
    );

    print("Push Notification Sent: ${response.body}");
  }

  /// Send Medication Update Notification
  void _updateMedications(List<String> newMeds) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
      'medications': newMeds,
    });

    QuerySnapshot contactsSnapshot = await FirebaseFirestore.instance
        .collection('emergencyContacts')
        .where('linkedPatientId', isEqualTo: user.uid)
        .get();

    for (var doc in contactsSnapshot.docs) {
      String? token = doc['fcmToken'];
      if (token != null && token.isNotEmpty) {
        _sendPushNotification(token, "Medication Update", "New medications added!");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.emergencyContacts)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              
              child: ListView.builder(
                
                itemCount: _emergencyContacts.length,
                itemBuilder: (context, index) {
                  var contact = _emergencyContacts[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.phone, color: Colors.red),
                      title: Text(contact["name"]!, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      subtitle: Text( '${contact["phone"]}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteEmergencyContact(contact),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (patientLocation != null) ...[
  Text(
    "Patient Location:",
    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
  ),
  Text(
    "Latitude: ${patientLocation!['latitude']}, Longitude: ${patientLocation!['longitude']}",
    style: TextStyle(fontSize: 16),
  ),
  SizedBox(height: 12),
],

            ElevatedButton(
              onPressed: _addEmergencyContact,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, padding: EdgeInsets.symmetric(vertical: 12)),
              child: Text(AppLocalizations.of(context)!.addContact, style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}