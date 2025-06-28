import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medtrack/services/firestore_service.dart';
import 'package:medtrack/services/notification_service.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:medtrack/NavigationBar/manage_page.dart';
import 'package:medtrack/NavigationBar/medications_page.dart';
import 'package:medtrack/NavigationBar/refills_page.dart';
import 'package:medtrack/pages/profile_page.dart';
import 'package:medtrack/pages/setting/settings_page.dart';
import 'package:flutter_animate/flutter_animate.dart';
//import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:medtrack/main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<String, bool> _medTakenStatus = {};
  final FirestoreService _firestoreService = FirestoreService();
  bool? _isEmergencyContact;
  Timer? _medCheckTimer;

  @override
  void initState() {
    super.initState();
    loadTakenMedsForToday();
    _checkEmergencyContactStatus();
    fetchAndCheckMissedDoses();
    startPeriodicCheck();
  }

  void startPeriodicCheck() {
    fetchAndCheckMissedDoses();

    _medCheckTimer = Timer.periodic(Duration(minutes: 15), (timer) {
      fetchAndCheckMissedDoses();
    });
  }

  @override
  void dispose() {
    _medCheckTimer?.cancel();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _checkEmergencyContactStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    bool status = await _firestoreService.isEmergencyContact();
    setState(() {
      _isEmergencyContact = status;
      print('🚨 the user is emergency $_isEmergencyContact');
    });

    if (!status && FirebaseAuth.instance.currentUser != null) {
      await NotificationService.scheduleDailyMedReminders(user.uid);
      await NotificationService.rescheduleUpcomingAppointments(user.uid);

      print("👤 User logged in: ${user.uid}, and notifications scheduled");
      print(
          "📅 User logged in: ${user.uid}, and Appointments notifications scheduled");
    } else {
      print(
          "⛔ No medication notifications scheduled for emergency contact user: ${user.uid}");
    }
  }

  Stream<List<QueryDocumentSnapshot>> fetchMedsCollectionNotifi() async* {
    final currentUserPhone = FirebaseAuth.instance.currentUser?.phoneNumber;
    if (currentUserPhone == null) {
      yield [];
      return;
    }

    final emergencyContactDoc = await FirebaseFirestore.instance
        .collection('emergencyContacts')
        .doc(currentUserPhone)
        .get();

    if (!emergencyContactDoc.exists) {
      yield [];
      return;
    }

    final linkedPatientId = emergencyContactDoc.data()?['linkedPatientId'];
    if (linkedPatientId == null) {
      yield [];
      return;
    }

    yield* FirebaseFirestore.instance
        .collection('meds')
        .where('linkedUserIds', arrayContains: linkedPatientId)
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  void fetchAndCheckMissedDoses() async {
    final medsSnapshot = await fetchMedsCollectionAll().first;
    await checkUnTakenDoses(medsSnapshot);
  }

  Future<void> checkUnTakenDoses(List<QueryDocumentSnapshot> meds) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final currentUserUid = currentUser.uid;

    // Fetch phone from the users collection using UID
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUid)
        .get();

    if (!userDoc.exists) return;

    final currentUserPhone = userDoc.data()?['phone'];

    if (currentUserPhone == null) return;

    // Use phone number to access emergencyContacts collection
    final emergencyContactDoc = await FirebaseFirestore.instance
        .collection('emergencyContacts')
        .doc(currentUserPhone)
        .get();

    if (!emergencyContactDoc.exists) return;

    final linkedPatientId = emergencyContactDoc.data()?['linkedPatientId'];

    if (linkedPatientId == null) return;

    final today = DateTime.now();
    final todayName = getDayName(today.weekday);

    for (var medDoc in meds) {
      var medData = medDoc.data() as Map<String, dynamic>;
      String frequency = (medData['frequency'] ?? '').toString().toLowerCase();
      String medId = medDoc.id;

      List<String> doseKeys = [];
      List<String> reminderTimes =
          List<String>.from(medData['reminderTimes'] ?? []);

      if (frequency == 'once a day') {
        doseKeys = ['${medId}_1'];
      } else if (frequency == 'twice a day') {
        doseKeys = ['${medId}_1', '${medId}_2'];
      } else if (frequency == '3 times a day') {
        doseKeys = ['${medId}_1', '${medId}_2', '${medId}_3'];
      } else if (frequency == 'once a week') {
        if (medData['onceAWeekDay'] == todayName) {
          doseKeys = [medId];
        }
      } else if (medData.containsKey('specificDays')) {
        List<dynamic> specificDays = medData['specificDays'];
        if (specificDays.contains(todayName)) {
          doseKeys = [medId];
        }
      } else {
        doseKeys = [medId];
      }

      for (var i = 0; i < doseKeys.length; i++) {
        final doseKey = doseKeys[i];
        print("🔍 Dose key $doseKey status: ${_medTakenStatus[doseKey]}");

        if (!(_medTakenStatus[doseKey] ?? false)) {
          if (i < reminderTimes.length) {
            final reminderTimeStr = reminderTimes[i];
            final reminderTime = parseReminderTimeToDateTime(reminderTimeStr);
            final medName = medData['name'] ?? "Medication";

            if (DateTime.now()
                .isAfter(reminderTime.add(const Duration(minutes: 15)))) {
              await NotificationService.checkAndNotifyUnTakenDose(
                  doseKey, linkedPatientId, medName);
              print("🚨 Missed dose notification sent for $doseKey");
            }
          }
        }
      }
    }
  }

  DateTime parseReminderTimeToDateTime(String timeStr) {
    final now = DateTime.now();
    final format = DateFormat("hh:mm a"); // 12-hour format with AM/PM
    final time = format.parse(timeStr);

    return DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
  }

  Widget _buildUserName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Text('Guest',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            shadows: [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 1.0,
                color: Colors.black45,
              ),
            ],
          ));
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text('Loading...',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 1.0,
                    color: Colors.black45,
                  ),
                ],
              ));
        } else if (snapshot.hasError) {
          return const Text('Error',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 1.0,
                    color: Colors.black45,
                  ),
                ],
              ));
        }

        final document = snapshot.data;

        if (document == null || !document.exists) {
          return const Text('User',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Colors.black,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 1.0,
                    color: Colors.black45,
                  ),
                ],
              ));
        }

        final data = document.data() as Map<String, dynamic>;
        final fullName = "${data['firstName']} ${data['lastName']}";

        return Text(fullName,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.black,
              shadows: [
                Shadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 1.0,
                  color: Colors.black45,
                ),
              ],
            ));
      },
    );
  }

  Widget _buildUserImage() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const CircleAvatar(
        radius: 40,
        backgroundColor: Colors.transparent,
        backgroundImage: AssetImage('images/user.png'),
      );
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            child: CircularProgressIndicator(color: Colors.white),
          );
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('images/user.png'),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final profileImage = data['profileImage'] ?? '';

        if (profileImage.isEmpty || profileImage == 'images/user.png') {
          return const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            backgroundImage: AssetImage('images/user.png'),
          );
        }

        return CircleAvatar(
          radius: 20,
          backgroundColor: Colors.transparent,
          backgroundImage: NetworkImage(profileImage),
        );
      },
    );
  }

  Widget _buildCalendar() {
    return Container(
      height: 110, // ✅ ensure full rendering of weekdays
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TableCalendar(
        locale: Localizations.localeOf(context).languageCode,
        firstDay: DateTime.utc(2020, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
          isSameDay(selectedDay, DateTime.now())
              ? loadTakenMedsForToday()
              : loadTakenMedsForDate(selectedDay);
        },
        calendarFormat: CalendarFormat.week,
        rowHeight: 75, // ✅ critical fix
        daysOfWeekHeight: 30, // adjust to fit label height

        startingDayOfWeek: StartingDayOfWeek.saturday,
        headerVisible: false,
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: Colors.blue,
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: Colors.blue.shade700,
            shape: BoxShape.circle,
          ),
          todayTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          selectedTextStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekendStyle: TextStyle(
            color: Color.fromARGB(255, 156, 156, 156),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          weekdayStyle: TextStyle(
            color: Color.fromARGB(255, 156, 156, 156),
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Stream<List<QueryDocumentSnapshot>> fetchAppointmentsCollection() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('appointments')
        .where('linkedUserIds', arrayContains: user.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs); // Convert snapshot to list of docs
  }

  Widget _buildAppointmentsWithinTwoDaysRange() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: fetchAppointmentsCollection(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading appointments"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No appointments for today"));
        }

        final appointments = snapshot.data!;
        final selectedDate = _selectedDay ?? _focusedDay;
        final selectedDay =
            DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        //   final oneDayBefore = selectedDay.subtract(const Duration(days: 1));
        final oneDayAfter = selectedDay.add(const Duration(days: 1));

        List<QueryDocumentSnapshot> filteredAppointments = [];
        List<String> reminders = [];

        for (var appointment in appointments) {
          final data = appointment.data() as Map<String, dynamic>;
          final appointmentDateStr = data['appointmentDate'];
          if (appointmentDateStr == null) continue;

          try {
            final appointmentDate = DateTime.parse(appointmentDateStr);
            final appointmentDay = DateTime(appointmentDate.year,
                appointmentDate.month, appointmentDate.day);

            if (appointmentDay == selectedDay) {
              filteredAppointments.add(appointment);
            }

            if (appointmentDay == oneDayAfter) {
              final doctorName = data['doctorName'] ?? 'Unknown';
              final appointmentTime = data['appointmentTime'] ?? 'Unknown';
              final message = AppLocalizations.of(context)!
                  .appointmentTomorrow(doctorName, appointmentTime);

              reminders.add(message);
            }
          } catch (e) {
            print(" Error parsing date: $appointmentDateStr — $e");
            continue;
          }
        }

        if (filteredAppointments.isEmpty && reminders.isEmpty) {
          return Center(
              child: Text(AppLocalizations.of(context)!.noAppointments));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminders.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 10.0),
                child: Column(
                  children: reminders.map((msg) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            blurRadius: 4,
                            spreadRadius: 1,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.notifications_active,
                              color: Colors.orange, size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              msg,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ListView.builder(
              padding: const EdgeInsets.all(5),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredAppointments.length,
              itemBuilder: (context, index) {
                final data =
                    filteredAppointments[index].data() as Map<String, dynamic>;

                final doctorName = data['doctorName'] ?? 'Unknown';
                final appointmentDate = data['appointmentDate'] ?? 'N/A';
                final appointmentTime = data['appointmentTime'] ?? 'N/A';

                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 180, 213, 240),
                          Color(0xFFFFFFFF)
                        ],
                        begin: Alignment.bottomRight,
                        end: Alignment.topLeft,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blueGrey.shade100,
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(255, 255, 255, 255),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.calendar_month,
                                color: Colors.blue, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Dr. $doctorName",
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'PlayfairDisplay'),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Date: $appointmentDate",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      "Time: $appointmentTime",
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // ================ Medications ===================
  Stream<List<QueryDocumentSnapshot>> fetchMedsCollectionAll() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection('meds')
        .where('linkedUserIds', arrayContains: user.uid) // Filter meds for user
        .snapshots()
        .map((snapshot) => snapshot.docs); // Convert snapshot to list of docs
  }

  Widget _buildMedicationsList() {
    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: fetchMedsCollectionAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text("Error loading medications"));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("No medications found"));
        }

        var medications = snapshot.data!;
        final selectedDate = _selectedDay ?? _focusedDay;
        final today = DateTime.now();
        bool isToday = isSameDay(selectedDate, today);

        var filteredMeds = medications.where((doc) {
          var medData = doc.data() as Map<String, dynamic>;
          String frequency =
              (medData['frequency'] ?? '').toString().toLowerCase();

          final selectedDate = _selectedDay ?? _focusedDay;
          final todayName = getDayName(selectedDate.weekday);
          final medId = doc.id;

          if (frequency == 'once a week') {
            String? onceAWeekDay = medData['onceAWeekDay'];
            if (onceAWeekDay == null || onceAWeekDay != todayName) {
              return false;
            }
            if (_medTakenStatus.containsKey(medId) &&
                _medTakenStatus[medId] == true) {
              return false;
            }
            return true;
          }

          if (medData.containsKey('specificDays')) {
            List<dynamic> specificDays = medData['specificDays'];
            if (specificDays.isNotEmpty && !specificDays.contains(todayName)) {
              return false;
            }
            if (_medTakenStatus.containsKey(medId) &&
                _medTakenStatus[medId] == true) {
              return false;
            }
            return true;
          }

          if (frequency == 'once a day') {
            if (_medTakenStatus.containsKey('${medId}_1') &&
                _medTakenStatus['${medId}_1'] == true) {
              return false;
            }
            return true;
          }

          if (frequency == 'twice a day') {
            if ((_medTakenStatus['${medId}_1'] ?? false) &&
                (_medTakenStatus['${medId}_2'] ?? false)) {
              return false;
            }
            return true;
          }

          if (frequency == '3 times a day') {
            if ((_medTakenStatus['${medId}_1'] ?? false) &&
                (_medTakenStatus['${medId}_2'] ?? false) &&
                (_medTakenStatus['${medId}_3'] ?? false)) {
              return false;
            }
            return true;
          }

          if (_medTakenStatus.containsKey(medId) &&
              _medTakenStatus[medId] == true) {
            return false;
          }

          return true;
        }).toList();

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: filteredMeds.length,
          itemBuilder: (context, index) {
            var med = filteredMeds[index];
            var medData = med.data() as Map<String, dynamic>;

            String frequency =
                (medData['frequency'] ?? '').toString().toLowerCase();
            List<String> reminderTimes =
                List<String>.from(medData['reminderTimes'] ?? []);
            String rawTime = "";
            String doseKey = med.id;

            if (frequency == "twice a day") {
              if (!(_medTakenStatus['${med.id}_1'] ?? false)) {
                rawTime = reminderTimes.isNotEmpty ? reminderTimes[0] : "";
                doseKey = '${med.id}_1';
              } else {
                rawTime = reminderTimes.length > 1 ? reminderTimes[1] : "";
                doseKey = '${med.id}_2';
              }
            } else if (frequency == "3 times a day") {
              if (!(_medTakenStatus['${med.id}_1'] ?? false)) {
                rawTime = reminderTimes.isNotEmpty ? reminderTimes[0] : "";
                doseKey = '${med.id}_1';
              } else if (!(_medTakenStatus['${med.id}_2'] ?? false)) {
                rawTime = reminderTimes.length > 1 ? reminderTimes[1] : "";
                doseKey = '${med.id}_2';
              } else {
                rawTime = reminderTimes.length > 2 ? reminderTimes[2] : "";
                doseKey = '${med.id}_3';
              }
            } else {
              rawTime = reminderTimes.isNotEmpty ? reminderTimes[0] : "";
              doseKey = '${med.id}_1';
            }

            String timeText = formatReminderTime(rawTime);

            return Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Updated: Bold time display above each med card
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 15),
                          if (!(_medTakenStatus[doseKey] ?? false) &&
                              isSameDay(
                                  _selectedDay ?? _focusedDay, DateTime.now()))
                            Animate(
                              effects: const [
                                FadeEffect(
                                    duration: Duration(milliseconds: 300)),
                                ScaleEffect(
                                    begin: Offset(0.8, 0.8),
                                    duration: Duration(milliseconds: 300)),
                              ],
                              child: Theme(
                                data: Theme.of(context).copyWith(
                                  unselectedWidgetColor: Colors.blue,
                                  checkboxTheme: CheckboxThemeData(
                                    fillColor: MaterialStateProperty
                                        .resolveWith<Color>((states) {
                                      if (states
                                          .contains(MaterialState.selected))
                                        return Colors.blue;
                                      return Colors.transparent;
                                    }),
                                    checkColor:
                                        MaterialStateProperty.all<Color>(
                                            Colors.white),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6)),
                                    side: const BorderSide(
                                        color: Colors.black, width: 2),
                                    splashRadius: 20,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                                child: Transform.scale(
                                  scale: 1.2,
                                  child: Checkbox(
                                    value: false,
                                    onChanged: (_isEmergencyContact == true)
                                        ? null // disables interaction for emergency contacts
                                        : (bool? value) async {
                                            if (value == null || !value) return;
                                            setState(() {
                                              _medTakenStatus[doseKey] = true;
                                            });
                                            final dosageStr =
                                                medData['dosage'].toString();
                                            await markMedicationAsTaken(
                                                doseKey, dosageStr);
                                          },
                                    // onChanged: (bool? value) async {
                                    //   if (value == null || !value) return;
                                    //   setState(() {
                                    //     _medTakenStatus[doseKey] = true;
                                    //   });
                                    //   final dosageStr =
                                    //       medData['dosage'].toString();
                                    //   await markMedicationAsTaken(
                                    //       doseKey, dosageStr);
                                    // },
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  title: Text(
                                      medData['name'] ?? "Medication Info"),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Dosage: ${medData['dosage']} ${medData['unit']}"),
                                      const SizedBox(height: 8),
                                      Text(
                                          "Intake Advice: ${medData['intakeAdvice']} "),
                                      const SizedBox(height: 8),
                                      Text(
                                          "Frequency: ${medData['frequency']}"),
                                      const SizedBox(height: 8),
                                      if (medData['notes'] != null &&
                                          medData['notes']
                                              .toString()
                                              .isNotEmpty)
                                        Text("Notes: ${medData['notes']}"),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                      child: const Text("Close"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color.fromARGB(255, 180, 213, 240),
                                  Color(0xFFFFFFFF)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blueGrey.shade100,
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color.fromARGB(
                                        255, 255, 255, 255),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.medication,
                                      color: Colors.blue, size: 28),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medData['name'] ?? "Unknown",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                          fontFamily: 'PlayfairDisplay',
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Take ${medData['dosage'] ?? '1'} ${medData['unit'] ?? 'pill(s)'}",
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black54,
                                            fontFamily: 'PlayfairDisplay'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  bool isFutureDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
  }

  bool isTodaySelected() {
    final today = DateTime.now();
    return _selectedDay == null
        ? isSameDay(_focusedDay, today)
        : isSameDay(_selectedDay!, today);
  }

  String getDayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        return '';
    }
  }

  String formatReminderTime(String time) {
    if (time.isEmpty) return "";
    time = time.toUpperCase();
    if (time.contains('AM') || time.contains('PM')) {
      time = time.replaceAll('AM', ' AM').replaceAll('PM', ' PM');
    }
    return time.trim();
  }

  void loadTakenMedsForToday() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayDate = "${now.year}-${now.month}-${now.day}";

    try {
      List<String> linkedUsers = await _firestoreService.getLinkedUserIds();
      print("load taken meds for $linkedUsers");

      for (String userId in linkedUsers) {
        QuerySnapshot snapshot = await _firestoreService.firestore
            .collection('users')
            .doc(userId) // 🔹 Use the correct userId (linked patient/emergency)
            .collection('medsTaken')
            .where('date', isEqualTo: todayDate)
            .get();

        if (snapshot.docs.isNotEmpty) {
          setState(() {
            for (var doc in snapshot.docs) {
              final doseKey = doc['medId'];
              _medTakenStatus[doseKey] = true;
            }
          });
        }
      }
    } catch (e) {
      print("Error loading taken medications: $e");
    }
  }

  Future<void> markMedicationAsTaken(String doseKey, String dosageStr) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    final todayDate = "${now.year}-${now.month}-${now.day}";

    try {
      String? docId = await _firestoreService.saveData(
        collection: 'users/${user.uid}/medsTaken',
        data: {
          'medId': doseKey,
          'takenAt': now,
          'date': todayDate,
        },
        context: context,
      );

      if (docId == null) return;

      if (mounted) {
        setState(() {
          _medTakenStatus[doseKey] = true;
        });
      }

      final baseMedId = doseKey.contains('_') ? doseKey.split('_')[0] : doseKey;

      if (_medTakenStatus[doseKey] == true) {
        final docSnapshot = await FirebaseFirestore.instance
            .collection('meds')
            .doc(baseMedId)
            .get();

        final data = docSnapshot.data();
        final List<dynamic> reminderTimes = data?['reminderTimes'] ?? [];

        final String takenTime =
            doseKey; // This should be the time when the med was taken
        final int doseIndex = reminderTimes.indexOf(takenTime);

        await NotificationService.cancelSingleReminderNotifications(takenTime);
        print("🔔 Cancelled notifications for ${takenTime}");
      }
      final medDocRef =
          FirebaseFirestore.instance.collection('meds').doc(baseMedId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final medSnapshot = await transaction.get(medDocRef);
        if (!medSnapshot.exists) return;

        final medData = medSnapshot.data() as Map<String, dynamic>;

        final currentInventory = (medData['currentInventory'] ?? 0).toDouble();
        final dosage = double.tryParse(dosageStr) ?? 0;
        final newInventory =
            (currentInventory - dosage).clamp(0, double.infinity);

        transaction.update(medDocRef, {'currentInventory': newInventory});
      });
    } catch (e) {
      print('Error updating medication: $e');
    }
  }

  Future<void> loadTakenMedsForDate(DateTime date) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final dateStr = "${date.year}-${date.month}-${date.day}";
    print("🔄 Loading taken meds for $dateStr");

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medsTaken')
          .where('date', isEqualTo: dateStr)
          .get();

      setState(() {
        _medTakenStatus.clear();
        for (var doc in snapshot.docs) {
          final doseKey = doc['medId'];
          _medTakenStatus[doseKey] = true;
        }
      });
    } catch (e) {
      print("⚠️ Error loading taken medications for $dateStr: $e");
    }
  }

  Widget _homeScreenContent() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildCalendar(),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.of(context)!.medications,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  offset: Offset(1.0, 1.0),
                  blurRadius: 1.0,
                  color: Colors.black45,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _buildMedicationsList(),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.appointments,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(1.0, 1.0),
                    blurRadius: 1.0,
                    color: Colors.black45,
                  ),
                ],
              )),
          const SizedBox(height: 10),
          _buildAppointmentsWithinTwoDaysRange(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent, // ✅ Transparent AppBar
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ProfilePage()),
                );
              },
              child: _buildUserImage(),
            ),
            const SizedBox(width: 15),
            Expanded(child: _buildUserName()),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),

      // 🌈 Apply gradient background here
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _homeScreenContent(),
          const RefillsPage(),
          const MedicationsPage(),
          ManagePage(),
        ],
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _onNavItemTapped,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
           BottomNavigationBarItem(icon: Icon(Icons.home), label:AppLocalizations.of(context)!.home),
           BottomNavigationBarItem(
              icon: Icon(Icons.auto_mode), label: AppLocalizations.of(context)!.refills),
          BottomNavigationBarItem(
            icon: const Icon(Icons.medication_liquid_outlined),
            label: AppLocalizations.of(context)!.medications,
          ),
           BottomNavigationBarItem(icon: Icon(Icons.menu), label:AppLocalizations.of(context)!.manage,),
        ],
      ),
    );
  }
}
