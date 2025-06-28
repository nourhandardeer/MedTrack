import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medtrack/services/notification_service.dart';
import 'refillrequest.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class DatePage extends StatefulWidget {
  final String medicationName;
  final String selectedUnit;
  final String selectedFrequency;
  final String documentId;
  final String dosage;

  const DatePage({
    Key? key,
    required this.medicationName,
    required this.selectedUnit,
    required this.selectedFrequency,
    required this.documentId,
    required this.dosage,
  }) : super(key: key);

  @override
  _DatePageState createState() => _DatePageState();
}

class _DatePageState extends State<DatePage> {
  // Time pickers
  List<int> selectedHours = [];
  List<int> selectedMinutes = [];
  List<bool> isAMs = [];

  // Days of the week
  final List<String> daysOfWeek = [
    'Saturday',
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];
  Set<String> selectedDays = {};
  String? selectedSingleDay;

  // Recurring picker
  int recurringValue = 1;

  @override
  void initState() {
    super.initState();
    setupTimePickers();
  }

  void setupTimePickers() {
    int reminders = 1;
    if (widget.selectedFrequency == "Once a day") reminders = 1;
    if (widget.selectedFrequency == "Twice a day") reminders = 2;
    if (widget.selectedFrequency == "3 times a day") reminders = 3;

    selectedHours = List.filled(reminders, 8);
    selectedMinutes = List.filled(reminders, 0);
    isAMs = List.filled(reminders, true);
  }

  bool get isReminderSelection =>
      widget.selectedFrequency == "Once a day" ||
      widget.selectedFrequency == "Twice a day" ||
      widget.selectedFrequency == "3 times a day";

  bool get isOnceAWeek => widget.selectedFrequency == "Once a week";

  bool get isSpecificDays =>
      widget.selectedFrequency == "Specific days of the week";

  bool get isRecurringDays => widget.selectedFrequency.contains("Every X days");

  bool get isRecurringWeeks =>
      widget.selectedFrequency.contains("Every X weeks");

  bool get isRecurringMonths =>
      widget.selectedFrequency.contains("Every X months");

  String get recurringType {
    if (isRecurringDays) return "Days";
    if (isRecurringWeeks) return "Weeks";
    if (isRecurringMonths) return "Months";
    return "";
  }

  List<int> getRecurringValues() {
    if (isRecurringDays) return List.generate(30, (i) => i + 1);
    if (isRecurringWeeks) return List.generate(12, (i) => i + 1);
    if (isRecurringMonths) return List.generate(12, (i) => i + 1);
    return [];
  }

  bool _isLoading = false;
  FlutterTts flutterTts = FlutterTts();

  // Call this function when notification fires
  Future<void> speakReminder(String message) async {
    await flutterTts.setLanguage("en-US"); // Set language
    await flutterTts.setSpeechRate(0.5); // Slower speed for elderly
    await flutterTts.speak(message); // Speak the reminder
  }

  Future<void> saveSelection() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Map<String, dynamic> dataToSave = {
        'timestamp': FieldValue.serverTimestamp()
      };

      if (isReminderSelection) {
        dataToSave['reminderCount'] = selectedHours.length;
        List<String> reminderTimes = [];
        for (int i = 0; i < selectedHours.length; i++) {
          String formattedTime =
              "${selectedHours[i].toString().padLeft(2, '0')}:${selectedMinutes[i].toString().padLeft(2, '0')} ${isAMs[i] ? 'AM' : 'PM'}";
          reminderTimes.add(formattedTime);

          // Convert the selected time into a DateTime object
          DateTime now = DateTime.now();
          int hour =
              isAMs[i] ? (selectedHours[i] % 12) : (selectedHours[i] % 12) + 12;

          DateTime scheduledTime = DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            selectedMinutes[i],
          );

          if (scheduledTime.isBefore(now)) {
            scheduledTime = scheduledTime.add(const Duration(
                days: 1)); // Schedule for next day if time already passed
          }

          await NotificationService.scheduleRepeatedNotification(
            baseId: "${widget.documentId}_${i + 1}", // the unique med ID
            title: "Medication Reminder",
            bodyEn:
                "Time to take ${widget.dosage} ${widget.selectedUnit} of ${widget.medicationName}.",
            bodyAr:
                "حان وقت تناول ${widget.dosage} ${widget.selectedUnit} من ${widget.medicationName}.",
            ttsMessageEn:
                "It's time to take your medicine: please take ${widget.dosage} ${widget.selectedUnit} of ${widget.medicationName}.",
            ttsMessageAr:
                "حان وقت تناول دوائك : الرجاء تناول ${widget.dosage} ${widget.selectedUnit} من ${widget.medicationName}.",
            startTime: scheduledTime, // the actual scheduled DateTime

            repeatCount: 24,
            interval: Duration(minutes: 15),
            dosage: int.tryParse(widget.dosage) ?? 0,
            unit: widget.selectedUnit,
            medName: widget.medicationName,
          );
        }
        dataToSave['reminderTimes'] = reminderTimes;
        dataToSave['reminderCount'] = reminderTimes.length;
      } else if (isOnceAWeek) {
        if (selectedSingleDay == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a day!')),
          );
          return;
        }
        dataToSave['onceAWeekDay'] = selectedSingleDay;
        dataToSave['reminderTime1'] = "12:00 AM"; // default value
      } else if (isSpecificDays) {
        if (selectedDays.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select at least one day!')),
          );
          return;
        }
        dataToSave['specificDays'] = selectedDays.toList();
        dataToSave['reminderTime1'] = "12:00 AM"; // default value
      } else if (recurringType.isNotEmpty) {
        dataToSave['recurringFrequency'] =
            "Every $recurringValue $recurringType";
        dataToSave['recurringValue'] = recurringValue;
        dataToSave['recurringType'] = recurringType;
      }

      await FirebaseFirestore.instance
          .collection('meds')
          .doc(widget.documentId)
          .update(dataToSave);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RefillRequest(
            medicationName: widget.medicationName,
            selectedUnit: widget.selectedUnit,
            selectedFrequency: widget.selectedFrequency,
            reminderTime: dataToSave.toString(),
            documentId: widget.documentId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget buildReminderPickers() {
    return ListView.builder(
      itemCount: selectedHours.length,
      itemBuilder: (context, index) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${AppLocalizations.of(context)!.reminderTime} ${index + 1}", style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: selectedHours[index] - 1),
                    itemExtent: 32.0,
                    onSelectedItemChanged: (hourIndex) {
                      setState(() => selectedHours[index] = hourIndex + 1);
                    },
                    children: List.generate(
                        12,
                        (index) => Center(
                            child:
                                Text((index + 1).toString().padLeft(2, '0')))),
                  ),
                ),
                const Text(":", style: TextStyle(fontSize: 20)),
                Expanded(
                  child: CupertinoPicker(
                    scrollController: FixedExtentScrollController(
                        initialItem: selectedMinutes[index]),
                    itemExtent: 32.0,
                    onSelectedItemChanged: (minuteIndex) {
                      setState(() => selectedMinutes[index] = minuteIndex);
                    },
                    children: List.generate(
                        60,
                        (index) => Center(
                            child: Text(index.toString().padLeft(2, '0')))),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: CupertinoSegmentedControl<bool>(
                    groupValue: isAMs[index],
                    children: const {
                      true: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("AM")),
                      false: Padding(
                          padding: EdgeInsets.symmetric(vertical: 8.0),
                          child: Text("PM")),
                    },
                    onValueChanged: (bool val) {
                      setState(() => isAMs[index] = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        );
      },
    );
  }

  Widget buildSingleDayPicker() {
    return ListView.builder(
      itemCount: daysOfWeek.length,
      itemBuilder: (context, index) {
        final day = daysOfWeek[index];
        final isSelected = selectedSingleDay == day;
        return ListTile(
          title: Text(day),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.blue)
              : null,
          onTap: () => setState(() => selectedSingleDay = day),
        );
      },
    );
  }

  Widget buildMultiDayPicker() {
    return ListView.builder(
      itemCount: daysOfWeek.length,
      itemBuilder: (context, index) {
        final day = daysOfWeek[index];
        final isSelected = selectedDays.contains(day);

        return ListTile(
          title: Text(day),
          trailing: isSelected
              ? const Icon(Icons.check_circle, color: Colors.blue)
              : null,
          onTap: () {
            setState(() {
              if (isSelected) {
                selectedDays.remove(day);
              } else {
                selectedDays.add(day);
              }
            });
          },
        );
      },
    );
  }

  Widget buildRecurringPicker() {
    final pickerValues = getRecurringValues();

    return Column(
      children: [
        const SizedBox(height: 20),
        const Text("Every",
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue)),
        const SizedBox(height: 20),
        SizedBox(
          height: 150,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: 0),
            itemExtent: 50.0,
            onSelectedItemChanged: (index) {
              setState(() => recurringValue = pickerValues[index]);
            },
            children: pickerValues
                .map((value) => Center(
                    child: Text(value.toString(),
                        style:
                            const TextStyle(fontSize: 24, color: Colors.blue))))
                .toList(),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          recurringType == 'Days'
              ? "Day(s)"
              : recurringType == 'Weeks'
                  ? "Week(s)"
                  : "Month(s)",
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget bodyWidget;

    if (isReminderSelection) {
      bodyWidget = buildReminderPickers();
    } else if (isOnceAWeek) {
      bodyWidget = buildSingleDayPicker();
    } else if (isSpecificDays) {
      bodyWidget = buildMultiDayPicker();
    } else if (recurringType.isNotEmpty) {
      bodyWidget = buildRecurringPicker();
    } else {
      bodyWidget = const Center(child: Text("No option selected"));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dateAndTime),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: bodyWidget,
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _isLoading ? null : saveSelection,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              :  Text(AppLocalizations.of(context)!.next,
                  style: TextStyle(fontSize: 18, color: Colors.white)),
        ),
      ),
    );
  }
}
