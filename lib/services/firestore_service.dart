import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'PhoneValidator.dart';

class FirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> updatePatientLocation() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await firestore.collection('users').doc(user.uid).update({
        'location': {
          'lat': position.latitude,
          'lng': position.longitude,
          'timestamp': FieldValue.serverTimestamp(),
        }
      });

      print("Patient location updated.");
    } catch (e) {
      print("Error updating location: $e");
    }
  }

  Future<String?> saveData({
    required String collection,
    required Map<String, dynamic> data,
    required BuildContext context,
  }) async {
    User? user = _auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User not logged in'), backgroundColor: Colors.red),
      );
      return null;
    }

    try {
      List<String> linkedUsers = await getLinkedUserIds();
      String patientId = linkedUsers.first; // Use first ID as patientId
      print(linkedUsers);
      DocumentReference docRef = await firestore.collection(collection).add({
        ...data,
        'linkedUserIds': linkedUsers,
        'linkedFrom': patientId,
        'createdBy': user.uid,
        'timestamp': FieldValue.serverTimestamp(),
      });

      return docRef.id;
    } catch (e) {
      print("Error saving data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error saving data'), backgroundColor: Colors.red),
      );
      return null;
    }
  }

  Future<String?> getOriginalPatientId(String emergencyContactPhone) async {
    try {
      final normalizedPhone = PhoneValidator.normalizePhone(emergencyContactPhone);
      final doc = await firestore
          .collection('emergencyContacts')
          .doc(normalizedPhone)
          .get();

      if (doc.exists) {
        return doc['linkedPatientId'];
      }
    } catch (e) {
      print("Error fetching original patient ID: $e");
    }
    return null;
  }

  Future<List<String>> getLinkedUserIds() async {
    User? user = _auth.currentUser;
    if (user == null) return [];

    final Set<String> linkedUserIds = {};
    String currentUserId = user.uid;
    linkedUserIds.add(currentUserId);

    DocumentSnapshot userDoc =
    await firestore.collection('users').doc(currentUserId).get();
    String? phoneNumber = userDoc['phone'];

    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      String normalizedPhone = PhoneValidator.normalizePhone(phoneNumber);
      String? linkedPatientId = await getOriginalPatientId(normalizedPhone);
      if (linkedPatientId != null) {
        linkedUserIds.add(linkedPatientId);
      }
    }

    List<String> emergencyContacts = await getEmergencyUserIds(currentUserId);
    linkedUserIds.addAll(emergencyContacts);

    return linkedUserIds.toList();
  }

  Future<List<String>> getEmergencyUserIds(String patientId) async {
    List<String> emergencyContactUserIds = [patientId];
    try {
      QuerySnapshot emergencyContactsSnapshot = await firestore
          .collection('users')
          .doc(patientId)
          .collection('emergencyContacts')
          .get();

      for (var doc in emergencyContactsSnapshot.docs) {
        String rawPhone = doc['phone'];
        String normalizedPhone = PhoneValidator.normalizePhone(rawPhone);

        QuerySnapshot userSnapshot = await firestore
            .collection('users')
            .where('phone', isEqualTo: normalizedPhone)
            .get();

        if (userSnapshot.docs.isNotEmpty) {
          emergencyContactUserIds.add(userSnapshot.docs.first.id);
        }
      }
    } catch (e) {
      print("Error fetching emergency contact IDs -> $e");
    }
    return emergencyContactUserIds;
  }

  Future<QuerySnapshot> getMedications(List<String> linkedUserIds) {
    return firestore
        .collection('meds')
        .where('linkedUserIds', arrayContainsAny: linkedUserIds)
        .get();
  }

  Future<List<QueryDocumentSnapshot>> getAppointments(List<String> linkedUserIds) async {
    if (linkedUserIds.isEmpty) return [];

    List<QuerySnapshot> snapshots = await Future.wait(
      linkedUserIds.map((id) => firestore
          .collection('appointments')
          .where('linkedUserIds', arrayContains: id)
          .get()),
    );

    final allDocs = snapshots.expand((s) => s.docs).toList();
    final uniqueDocs = {
      for (var doc in allDocs) doc.id: doc
    }.values.toList();

    return uniqueDocs;
  }

  Future<List<QueryDocumentSnapshot>> getDoctors(List<String> linkedUserIds) async {
    if (linkedUserIds.isEmpty) return [];

    List<QuerySnapshot> snapshots = await Future.wait(
      linkedUserIds.map((id) => firestore
          .collection('doctors')
          .where('linkedUserIds', arrayContains: id)
          .get()),
    );

    final allDocs = snapshots.expand((s) => s.docs).toList();
    final uniqueDocs = {
      for (var doc in allDocs) doc.id: doc
    }.values.toList();

    return uniqueDocs;
  }

  Future<bool> isEmergencyContact() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("User is null");
      return false;
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();

    final rawPhone = userDoc.data()?['phone'] as String?;
    if (rawPhone == null || rawPhone.isEmpty) {
      print("Phone is null or empty from Firestore user doc: $rawPhone");
      return false;
    }

    final normalizedPhone = PhoneValidator.normalizePhone(rawPhone);

    print("Checking emergencyContacts for doc id: $normalizedPhone");
    final snapshot = await FirebaseFirestore.instance
        .collection('emergencyContacts')
        .doc(normalizedPhone)
        .get();

    print("Document exists? ${snapshot.exists}");
    return snapshot.exists;
  }
  Future<bool> checkAndLinkEmergencyContact(
      User user, String userId, String phone) async {
    final normalizedPhone = PhoneValidator.normalizePhone(phone);
    try {
      final contactDoc = await FirebaseFirestore.instance
          .collection('emergencyContacts')
          .doc(normalizedPhone)
          .get();

      if (contactDoc.exists) {
        String patientId = contactDoc['linkedPatientId'];

        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'linkedPatientId': patientId,
          'isEmergency': true,
        }, SetOptions(merge: true));

        await _linkEmergencyToPatientData(patientId, userId);
        return true;
      }
    } catch (e) {
      print("Link error: $e");
    }

    // Default fallback
    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'isEmergency': false,
    }, SetOptions(merge: true));

    return false;
  }
  Future<void> _linkEmergencyToPatientData(
      String patientId, String emergencyContactId) async {
    final collections = ['meds', 'appointments', 'doctors'];

    for (String collection in collections) {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection)
          .where('linkedUserIds', arrayContains: patientId)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.update({
          'linkedUserIds': FieldValue.arrayUnion([emergencyContactId]),
        });
      }
    }
  }
}
