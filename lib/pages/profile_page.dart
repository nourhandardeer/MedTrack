import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/UpdateCurrentUserLocation.dart';
import '../services/firestore_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _fullName = "Loading...";
  String _profileImageUrl = "images/user.png";
  String _age = "";
  String _illnesses = "";
  String? _linkedPatientName;
  String? _userId;
  List<Map<String, dynamic>> _emergencyContacts = [];
  final FirestoreService _firestoreService = FirestoreService();
  bool _isEmergencyContact = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    updateCurrentUserLocation();
    _checkIfEmergencyContact();
  }

  void _checkIfEmergency() async {
    final result = await _firestoreService.isEmergencyContact();
    setState(() {
      _isEmergencyContact = result;
    });
  }
  Future<void> _fetchUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userId = user.uid;
          _fullName = "${data['firstName']} ${data['lastName']}";
          _profileImageUrl = data['profileImage']?.isNotEmpty == true
              ? data['profileImage']
              : "images/user.png";
          _age = (data['age'] != null && data['age'].isNotEmpty)
              ? data['age']
              : "Unknown";
          _illnesses =
              (data['illnesses'] != null && data['illnesses'].isNotEmpty)
                  ? data['illnesses']
                  : "No illnesses specified";
        });

        _fetchEmergencyContacts(user.uid);
      }
    } catch (e) {
      _showSnackBar("Error fetching profile: $e");
    }
  }

  Future<void> _fetchEmergencyContacts(String userId) async {
    try {
      QuerySnapshot contactsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('emergencyContacts')
          .get();

      List<Map<String, dynamic>> contacts = contactsSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          "id": doc.id,
          "name": data["name"] ?? "Unknown",
          "phone": data["phone"] ?? "No phone",
          "relation": data["relation"] ?? "No relation",
        };
      }).toList();

      setState(() {
        _emergencyContacts = contacts;
      });
    } catch (e) {
      _showSnackBar("Error fetching emergency contacts: $e");
    }
  }

  Future<void> _checkIfEmergencyContact() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || userDoc['phone'] == null) return;
      String phoneNumber = userDoc['phone'];

      String? patientId =
          await _firestoreService.getOriginalPatientId(phoneNumber);

      if (patientId == null) return; // No linked patient found

      DocumentSnapshot patientDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .get();

      if (patientDoc.exists) {
        setState(() {
          _linkedPatientName =
              "${patientDoc['firstName']} ${patientDoc['lastName']}";
          _isEmergencyContact = true;
        });
      }
    } catch (e) {
      _showSnackBar("Error checking emergency contact status: $e");
    }
  }
  void _deleteEmergencyContact(Map<String, dynamic> contact) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Delete from user's subcollection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('emergencyContacts')
          .doc(contact['id'])
          .delete();

      // Delete from top-level emergencyContacts collection (using phone as ID)
      final String? phone = contact['phone'];
      if (phone != null && phone.isNotEmpty) {
        final emergencyRef = FirebaseFirestore.instance
            .collection('emergencyContacts')
            .doc(phone);
        final emergencyDoc = await emergencyRef.get();

        if (emergencyDoc.exists) {
          await emergencyRef.delete();
        }
      }

      // Update UI
      setState(() {
        _emergencyContacts.remove(contact);
      });
      _showSnackBar("Contact deleted successfully.");
    } catch (e) {
      _showSnackBar("Error deleting contact: $e");
    }
  }


  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
            'Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _profileImageUrl.startsWith('http')
                    ? NetworkImage(_profileImageUrl)
                    : AssetImage("images/user.png") as ImageProvider,
                backgroundColor: Colors.transparent,
              ),
              SizedBox(height: 16),
              Text(_fullName,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 4),
              if (!_isEmergencyContact)
                Text('Age: $_age | $_illnesses',
                    style: TextStyle(fontSize: 18, color: Colors.grey)),

              SizedBox(height: 16),
              if (_linkedPatientName != null)
                Container(
                  padding: EdgeInsets.all(15),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "You are an emergency contact for $_linkedPatientName.",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900]),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (!_isEmergencyContact)
                Text('Emergency Contacts',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              if (!_isEmergencyContact)
              Expanded(
                child: _emergencyContacts.isEmpty
                    ? Text("No emergency contacts available.")
                    : ListView.separated(
                        itemCount: _emergencyContacts.length,
                        separatorBuilder: (_, __) => Divider(),
                        itemBuilder: (context, index) {
                          var contact = _emergencyContacts[index];
                          return ListTile(
                            leading: Icon(Icons.phone, color: Colors.green),
                            title: Text(contact["name"],
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            subtitle: Text('${contact["phone"]}'),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEmergencyContact(contact),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
