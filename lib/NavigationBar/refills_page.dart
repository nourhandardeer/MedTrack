import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medtrack/Refills/refill_details.dart';
import 'package:medtrack/services/notification_service.dart'; // Import NotificationService
import 'package:intl/intl.dart';
import '../services/UserLocationHolder.dart'; // تأكد ان المسار صح
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RefillsPage extends StatefulWidget {
  const RefillsPage({Key? key}) : super(key: key);

  @override
  _RefillsPageState createState() => _RefillsPageState();
}

class _RefillsPageState extends State<RefillsPage> {
  final Set<String> _notifiedMeds = {};
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(
        child: Text(
          "Please log in to view refills.",
          style: TextStyle(color: Colors.black),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: _buildRefillsList(user.uid),
    );
  }

  Widget _buildRefillsList(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('meds')
          .where('linkedUserIds', arrayContains: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }

        var documents = snapshot.data?.docs ?? [];
        if (documents.isEmpty) {
          return const Center(child: Text("No refills needed"));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: documents.length,
          separatorBuilder: (_, __) =>
          const Divider(thickness: 1, color: Colors.grey),
          itemBuilder: (context, index) {
            final data = documents[index].data() as Map<String, dynamic>;
            final medName = data["name"]?.toString() ?? "Unknown Medication";

            // Inventory parsing
            int inventory = 0;
            final inventoryRaw = data['currentInventory'];
            if (inventoryRaw is int) {
              inventory = inventoryRaw;
            } else if (inventoryRaw is double) {
              inventory = inventoryRaw.toInt();
            } else if (inventoryRaw is String) {
              inventory = int.tryParse(inventoryRaw) ?? 0;
            }

            // Reminder threshold
            int remindMeWhen = 5;
            final thresholdRaw = data['remindMeWhen'];
            if (thresholdRaw is String) {
              remindMeWhen = int.tryParse(thresholdRaw) ?? 5;
            } else if (thresholdRaw is num) {
              remindMeWhen = thresholdRaw.toInt();
            }

            final List<dynamic>? reminderTimes = data["reminderTimes"];
            final String reminderTimeStr =
            (reminderTimes != null && reminderTimes.isNotEmpty)
                ? (reminderTimes[0] as String)
                : "Not set";

            // Notifications (مش مغيره هنا)
            if (inventory > 0 &&
                inventory <= remindMeWhen &&
                !_notifiedMeds.contains(medName)) {
              _notifiedMeds.add(medName);

              final DateTime now = DateTime.now();
              final DateTime notificationTime =
              now.add(const Duration(seconds: 5));

              NotificationService.scheduleNotification(
                id: medName.hashCode ^ notificationTime.hashCode,
                title: "Refill Reminder: $medName",
                bodyEn: "Your medication inventory is low! Please refill soon.",
                bodyAr: "مخزون دوائك منخفض! يرجى إعادة التعبئة قريبًا.",
                ttsMessageEn:
                "Your medication $medName inventory is low! Please refill soon.",
                ttsMessageAr:
                "مخزون دوائك $medName منخفض! يرجى إعادة التعبئة قريبًا.",
                scheduledTime: notificationTime,
                speakImmediately: true,
              );
            }

            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 220, 232, 242),
                    Color(0xFFFFFFFF),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Card(
                color: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading:
                  Image.asset("images/drugs.png", width: 32, height: 32),
                  title: Text(
                    medName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
        AppLocalizations.of(context)!
            .currentInventory(inventory.toString(), data["unit"] ?? ""),
        style:
            const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      Text(
        AppLocalizations.of(context)!
            .reminderTimes(reminderTimeStr),
        style:
            const TextStyle(fontSize: 12, color: Colors.blue),
      ),
                    ],
                  ),
                  onTap: () {
                    // نسخ البيانات واضافة الموقع من UserLocationHolder
                    Map<String, dynamic> medDataWithLocation =
                    Map<String, dynamic>.from(data);
                    medDataWithLocation['latitude'] =
                        UserLocationHolder.latitude ?? 0;
                    medDataWithLocation['longitude'] =
                        UserLocationHolder.longitude ?? 0;

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            RefillDetailsPage(medData: medDataWithLocation
                              , userId: userId
                              ,isEmergencyContact: false, // ← Because this is for the normal user


                            ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }

  DateTime _convertTimeToDateTime(String timeStr) {
    try {
      final format = DateFormat("hh:mm a");
      final time = format.parse(timeStr);
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, time.hour, time.minute);
    } catch (_) {
      return DateTime.now();
    }
  }
}
