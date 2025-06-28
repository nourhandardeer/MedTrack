//import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter_tts/flutter_tts.dart';
//import 'package:medtrack/services/firestore_service.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:ui';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final FlutterTts _tts = FlutterTts();

  static bool _isInitialized = false;
  static const String _prefsKey = "notifications_enabled";

  // ✅ Initialization
  static Future<void> initialize() async {
    if (_isInitialized) return;

    requestNotificationPermission();

    // Get the device's timezone (e.g., 'Asia/Kolkata', 'America/New_York')
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();

    tz.initializeTimeZones();
    print("Timezone initialized: $timeZoneName");

    // Set the local timezone
    final tz.Location location = tz.getLocation(timeZoneName);
    tz.setLocalLocation(location);

    await _initTTS();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const AndroidNotificationChannel medicationChannel =
        AndroidNotificationChannel(
      'medication_channel_id',
      'Medication Reminders',
      description: 'Channel for medication reminder notifications',
      importance: Importance.high,
    );

    const AndroidNotificationChannel instantChannel =
        AndroidNotificationChannel(
      'instant_channel_id',
      'Instant Notifications',
      description: 'Channel for instant notifications',
      importance: Importance.max,
    );

    const AndroidNotificationChannel emergencyChannel =
        AndroidNotificationChannel(
      'emergency_channel_id',
      'Emergency Alerts',
      description: 'Alerts for missed medications by elderly users',
      importance: Importance.max,
    );

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(medicationChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(instantChannel);

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(emergencyChannel);

    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    await _notificationsPlugin.initialize(
      settings,
      onDidReceiveNotificationResponse: (NotificationResponse response) async {
        if (response.payload != null && response.payload!.isNotEmpty) {
          await _speakMessage(response.payload!);
        }
      },
    );

    _isInitialized = true;
  }

  static Future<void> _initTTS() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
  }

  static Future<void> _speakMessage(String message) async {
    try {
      if (!_isInitialized) await initialize();

      // Detect Arabic based on characters
      final bool isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(message);

      if (isArabic) {
        await _tts.setLanguage("ar-SA"); // Use "ar-XA" or "ar" if needed
      } else {
        await _tts.setLanguage("en-US");
      }

      await _tts.speak(message);
    } catch (e) {
      print("Error speaking message: $e");
    }
  }

  static Future<void> requestNotificationPermission() async {
    final status = await Permission.notification.status;
    if (!status.isGranted) {
      await Permission.notification.request();
    }
  }

  // ✅ Preferences Logic
  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    bool enabled =
        prefs.getBool(_prefsKey) ?? true; // Default to true if not set
    print(
        "Notifications Enabled: $enabled"); // Debugging line to print the state
    return enabled;
  }

  static Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, enabled);

    if (!enabled) {
      await cancelAllNotifications();
      print("🔕 Notifications disabled");
    } else {
      print("🔔 Notifications enabled");
    }
  }

  // ✅ Single Notification
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String bodyEn,
    required String bodyAr,
    required DateTime scheduledTime,
    String? ttsMessageAr,
    String? ttsMessageEn,
    bool speakImmediately = false,
  }) async {
    if (!_isInitialized) await initialize();
    bool enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final String languageCode = PlatformDispatcher.instance.locale.languageCode;

    // Choose TTS message based on device language
    String? selectedTtsMessage;
    String localizedBody;

    if (languageCode == 'ar') {
      selectedTtsMessage = ttsMessageAr;
      localizedBody = bodyAr;
    } else {
      selectedTtsMessage = ttsMessageEn;
      localizedBody = bodyEn;
    }

    final tz.TZDateTime tzScheduledTime =
        tz.TZDateTime.from(scheduledTime, tz.local);

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'medication_channel_id',
      'Medication Reminders',
      channelDescription: 'Channel for medication reminder notifications',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      localizedBody,
      tzScheduledTime,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: selectedTtsMessage,
    );

    if (speakImmediately && selectedTtsMessage != null) {
      await _speakMessage(selectedTtsMessage);
    }
  }

  // ✅ Instant Notification
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? ttsMessage,
  }) async {
    if (!_isInitialized) await initialize();
    bool enabled = await areNotificationsEnabled();
    if (!enabled) return;

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'instant_channel_id',
      'Instant Notifications',
      channelDescription: 'Channel for instant notifications',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _notificationsPlugin.show(
      0,
      title,
      body,
      platformDetails,
      payload: ttsMessage,
    );

    if (ttsMessage != null) {
      await _speakMessage(ttsMessage);
    }
  }

  // ✅ Repeated Notification
  static Future<void> scheduleRepeatedNotification({
    required String baseId,
    required String title,
    required String bodyEn,
    required String bodyAr,
    required DateTime startTime,
    String? ttsMessageAr,
    String? ttsMessageEn,
    required int repeatCount,
    required Duration interval,
    required int dosage,
    required String unit,
    required String medName,
  }) async {
    if (!_isInitialized) await initialize();
    bool enabled = await areNotificationsEnabled();
    if (!enabled) return;

    final String languageCode = PlatformDispatcher.instance.locale.languageCode;

    // Choose TTS message based on device language
    String? selectedTtsMessage;
    String localizedBody;
    // Helper to convert digits to Arabic numerals
    String convertToArabicNumbers(String input) {
      final arabicNumbers = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
      return input.replaceAllMapped(RegExp(r'\d'), (match) {
        return arabicNumbers[int.parse(match.group(0)!)];
      });
    }

    String selectedLanguage = languageCode == 'ar' ? 'ar' : 'en';
    await _tts.setLanguage(selectedLanguage);

    if (languageCode == 'ar' && ttsMessageAr != null) {
      // Replace placeholders with variables
      String unitAr = _translateUnitToArabic(unit);

      String arabicMessage = ttsMessageAr
          .replaceAll('${dosage}', convertToArabicNumbers(dosage.toString()))
          .replaceAll('${unit}', unitAr)
          .replaceAll('${medName}', medName);

      selectedTtsMessage = arabicMessage;
      localizedBody = bodyAr;
    } else if (ttsMessageEn != null) {
      String message = ttsMessageEn
          .replaceAll('${dosage}', dosage.toString())
          .replaceAll('${unit}', unit)
          .replaceAll('${medName}', medName);

      selectedTtsMessage = message;
      localizedBody = bodyEn;
    } else {
      selectedTtsMessage = null;
      localizedBody = bodyEn;
    }

    try {
      for (int i = 0; i < repeatCount; i++) {
        final int id = generateNotificationId(baseId, i);

        ;

        final scheduledTime = startTime.add(interval * i);
        final tz.TZDateTime tzScheduledTime =
            tz.TZDateTime.from(scheduledTime, tz.local);

        const AndroidNotificationDetails androidDetails =
            AndroidNotificationDetails(
          'medication_channel_id',
          'Medication Reminders',
          channelDescription: 'Channel for medication reminder notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        );

        const NotificationDetails platformDetails =
            NotificationDetails(android: androidDetails);

        await _notificationsPlugin.zonedSchedule(
          id,
          title,
          localizedBody,
          tzScheduledTime,
          platformDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
          payload: selectedTtsMessage,
        );

       

        await _storeScheduledId(id);
        
      }
    } catch (e) {
      print("❌ Failed to schedule repeated notification: $e");
    }
    
    
  }

  static Future<void> scheduleDailyMedReminders(String uid) async {
    if (!_isInitialized) await initialize();
    bool enabled = await areNotificationsEnabled();
    if (!enabled) return;

    print("🔄 Starting to schedule daily medication reminders for user: $uid");

    final medsSnapshot = await FirebaseFirestore.instance
        .collection('meds')
        .where('linkedUserIds', arrayContains: uid)
        .get();
    print("📂 Medications fetched: ${medsSnapshot.docs.length}");

    final now = DateTime.now();
    final timeFormat = DateFormat.jm(); // Format for parsing "06:46 AM"

    for (final doc in medsSnapshot.docs) {
      final data = doc.data();
      if (!data.containsKey('reminderTimes')) {
        print("⚠️ Skipping '${doc.id}': No 'reminderTimes' field found.");
        continue;
      }
      final reminderTimes = data['reminderTimes'] as List<dynamic>;

      for (int i = 0; i < reminderTimes.length; i++) {
        final timeString = reminderTimes[i] as String;

        final time = timeFormat.parse(timeString);

        final medName = data['name'] ?? 'Medication Reminder';
        final docId = doc.id;
        final dosage = data['dosage'] ?? 'Dosage not specified';
        final selectedUnit = data['unit'] ?? 'Unit not specified';

        DateTime scheduledDateTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );

        if (scheduledDateTime.isBefore(now)) {
          scheduledDateTime = scheduledDateTime.add(Duration(days: 1));
        }

        await scheduleRepeatedNotification(
          baseId: "${docId}_${i + 1}",
          title: 'Time for $medName',
          bodyEn: "Time to take ${dosage} ${selectedUnit} of ${medName}",
          bodyAr:
              "حان وقت تناول ${dosage} ${_translateUnitToArabic(selectedUnit)} من ${medName}",
          startTime: scheduledDateTime,
          ttsMessageEn:
              "It's time to take your medicine: please take ${dosage} ${selectedUnit} of ${medName}.",
          ttsMessageAr:
              "حان وقت تناول دوائك: الرجاء تناول ${dosage} ${selectedUnit} من ${medName}.",
          repeatCount: 24,
          interval: const Duration(minutes: 15),
          dosage: dosage,
          unit: selectedUnit,
          medName: medName,
        );
      }
    }

    print("✅ All reminders and alarms scheduled for user: $uid");
  }

  static Future<void> rescheduleUpcomingAppointments(String uid) async {
  if (!_isInitialized) await initialize();
  bool enabled = await areNotificationsEnabled();
  if (!enabled) return;

  print("🔄 Rescheduling upcoming appointments for user: $uid");

  final appointmentSnapshot = await FirebaseFirestore.instance
      .collection('appointments')
      .where('linkedUserIds', arrayContains: uid)
      .get();

  print("📅 Appointments fetched: ${appointmentSnapshot.docs.length}");

  final now = DateTime.now();
  final dateFormat = DateFormat('yyyy-MM-dd');
  final timeFormat = DateFormat.jm(); // e.g., "6:30 PM"

  for (final doc in appointmentSnapshot.docs) {
    final data = doc.data();

    final dateStr = data['appointmentDate'] as String?;
    final timeStr = data['appointmentTime'] as String?;
    final doctorName = data['doctorName'] ?? 'Doctor';
    final docId = doc.id;

    if (dateStr == null || timeStr == null) {
      print("⚠️ Skipping $docId: missing date or time");
      continue;
    }

    try {
      final date = dateFormat.parse(dateStr);
      final time = timeFormat.parse(timeStr);

      final appointmentDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );

      if (appointmentDateTime.isAfter(now)) {
        final reminderTime = appointmentDateTime.subtract(Duration(minutes: 60));

        await NotificationService.scheduleNotification(
          id: appointmentDateTime.millisecondsSinceEpoch.remainder(100000),
          title: 'Appointment Reminder',
          bodyEn: 'You have an appointment with Dr. $doctorName at $timeStr',
          bodyAr: 'لديك موعد مع الدكتور $doctorName في الساعة $timeStr',
          scheduledTime: reminderTime,
          ttsMessageEn: 'Reminder! Appointment with Dr. $doctorName at $timeStr.',
          ttsMessageAr: 'تذكير! لديك موعد مع الدكتور $doctorName في الساعة $timeStr.',
        );

        print("✅ Scheduled reminder for $appointmentDateTime");
      } else {
        print("⏭️ Skipping past appointment at $appointmentDateTime");
      }
    } catch (e) {
      print("❌ Error parsing appointment for $docId: $e");
    }
  }
}


  static String _translateUnitToArabic(String unit) {
    const unitMap = {
      "Pill(s)": "حبّة",
      "Ampoule(s)": "أمبولة",
      "Tablet(s)": "قرص",
      "Capsule(s)": "كبسولة",
      "IU": "وحدة دولية",
      "Application": "تطبيق",
      "Drop": "قطرة",
      "Gram": "غرام",
      "Injection": "حقنة",
      "Milligram": "ميليغرام",
      "Milliliter": "ميليلتر",
      "MM": "ملم",
      "Packet": "علبة",
      "Pessary": "تحميلة مهبلية",
      "Piece": "قطعة",
      "Portion": "جزء",
      "Puff": "رشة",
      "Spray": "بخاخ",
      "Suppository": "تحميلة",
      "Teaspoon": "ملعقة صغيرة",
      "Vaginal Capsule": "كبسولة مهبلية",
      "Vaginal Suppository": "تحميلة مهبلية",
      "Vaginal Tablet": "قرص مهبلي",
      "MG": "ميليغرام",
    };

    return unitMap[unit] ?? unit; // fallback to original if not found
  }

  static Future<void> notifyEmergencyContacts({
    required String elderlyUserId,
    required String alertMessage,
  }) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('emergencyContacts')
          .where('linkedPatientId', isEqualTo: elderlyUserId)
          .get();

      if (snapshot.docs.isEmpty) {
        print("🚫 No emergency contacts found for user: $elderlyUserId");
        return;
      }

      for (final doc in snapshot.docs) {
        final contactId = doc.id;

        await _notificationsPlugin.show(
          generateNotificationId(elderlyUserId, contactId.hashCode),
          '🚨 Missed Medication Alert',
          alertMessage,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'emergency_channel_id',
              'Emergency Alerts',
              channelDescription:
                  'Alerts for missed medications by elderly users',
              importance: Importance.max,
              priority: Priority.high,
              playSound: true,
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Failed to notify emergency contacts: $e");
    }
  }

  @pragma('vm:entry-point')
  static Future<void> checkAndNotifyUnTakenDose(
      String doseKey, String userId, String medName) async {
    final now = DateTime.now();
    final todayDate =
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('medsTaken')
        .where('medId', isEqualTo: doseKey)
        .where('date', isEqualTo: todayDate)
        .get();

    if (snapshot.docs.isEmpty) {
      print(
          "⚠️ Medication $doseKey not taken by $userId. Notifying emergency contacts...");
      await NotificationService.notifyEmergencyContacts(
        elderlyUserId: userId,
        alertMessage:
            "Your lovely one has not taken their medication $medName.",
      );
    } else {
      print("✅ Medication $doseKey was taken. No alert needed.");
    }
  }

  static Future<void> _storeScheduledId(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('scheduledNotificationIds') ?? [];
    if (!ids.contains(id.toString())) {
      ids.add(id.toString());
      await prefs.setStringList('scheduledNotificationIds', ids);
    } else {}
  }

  // ✅ Cancel Helpers
  static int generateNotificationId(String medId, int index) {
    return "$medId\_$index".hashCode.abs() % 100000;
  }

  static Future<void> cancelTrackedNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final idStrings = prefs.getStringList('scheduledNotificationIds') ?? [];

    if (idStrings.isEmpty) {
      print("ℹ️ No tracked notifications to cancel.");
      return;
    }

    for (final idStr in idStrings) {
      final id = int.tryParse(idStr);
      if (id != null) {
        await _notificationsPlugin.cancel(id);
      }
    }

    await prefs.remove('scheduledNotificationIds');
    print("🗑️ Cleared stored notification ID list");
  }

  static Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelRepeatedNotification(int id) async {
    await _notificationsPlugin.cancel(id);
  }

  static Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
    await cancelTrackedNotifications();
  }

  static Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  static Future<void> cancelSingleReminderNotifications(String baseId) async {
    if (!_isInitialized) await initialize();

    try {
      final repeatCountPerReminder = 24;

      for (int j = 0; j < repeatCountPerReminder; j++) {
        int id = generateNotificationId(baseId, j);

        await _notificationsPlugin.cancel(id);
      }

      print("✅ Cancelled notifications of $baseId");
    } catch (e) {
      print("❌ Error cancelling single reminder notifications: $e");
    }
  }
}
