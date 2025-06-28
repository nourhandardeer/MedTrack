import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medtrack/services/firestore_service.dart';

import 'PhoneValidator.dart';


Future<String?> checkPhoneNumberUniqueness(String phone) async {
  final normalizedPhone = PhoneValidator.normalizePhone(phone);
  final usersRef = FirebaseFirestore.instance.collection('users');

  // ✅ Block only if already exists in 'users'
  final userQuery = await usersRef.where('phone', isEqualTo: normalizedPhone).get();
  if (userQuery.docs.isNotEmpty) {
    return 'This phone number is already registered.';
  }

  return null;
}
