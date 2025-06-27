import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'FrequencySelectionPage.dart';
import 'UnitSelectionPage.dart';

class MedicationDetailsPage extends StatefulWidget {
  final String medId;

  const MedicationDetailsPage({Key? key, required this.medId})
      : super(key: key);

  @override
  _MedicationDetailsPageState createState() => _MedicationDetailsPageState();
}

class _MedicationDetailsPageState extends State<MedicationDetailsPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, dynamic>? medData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicationData();
  }

  Future<void> _loadMedicationData() async {
    try {
      DocumentSnapshot snapshot = await FirebaseFirestore.instance
          .collection('meds')
          .doc(widget.medId)
          .get();
      if (snapshot.exists) {
        setState(() {
          medData = snapshot.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          medData = null;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error loading medication data: $e");
    }
  }

  Future<void> _updateData(String field, String newValue) async {
    try {
      await FirebaseFirestore.instance
          .collection('meds')
          .doc(widget.medId)
          .update({field: newValue});
      setState(() {
        medData?[field] = newValue;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$field updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error updating $field: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateReminderTime(int index, String newTime) async {
    try {
      List<dynamic> times = List.from(medData?['reminderTimes'] ?? []);
      if (index >= 0 && index < times.length) {
        times[index] = newTime;
        await FirebaseFirestore.instance
            .collection('meds')
            .doc(widget.medId)
            .update({'reminderTimes': times});
        setState(() {
          medData?['reminderTimes'] = times;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Reminder time updated successfully!"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print("Error updating reminder time: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Failed to update reminder time."),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showTimePickerForReminder(int index) {
    TimeOfDay selectedTime = TimeOfDay(hour: 0, minute: 0);
    showTimePicker(
      context: context,
      initialTime: selectedTime,
    ).then((pickedTime) {
      if (pickedTime != null) {
        final hour = pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;
        final minute = pickedTime.minute.toString().padLeft(2, '0');
        final period = pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
        final formattedTime = "$hour:$minute $period";
        _updateReminderTime(index, formattedTime);
      }
    });
  }

  void _showCustomInputDialog(TextEditingController controller) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Enter Custom Intake Advice"),
          content: TextField(
            controller: controller,
            decoration:
                const InputDecoration(hintText: "Write your intake advice..."),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String value = controller.text.trim();
                if (value.isNotEmpty) {
                  _updateData("intakeAdvice", "Custom");
                  _updateData("customIntakeAdvice", value);
                }
                Navigator.of(context).pop();
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Delete Medication"),
          content:
              const Text("Are you sure you want to delete this medication?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('meds')
                    .doc(widget.medId)
                    .delete();
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String value,
    required String field,
    VoidCallback? onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(value),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: onTap ?? () {},
        ),
      ),
    );
  }

  Widget _buildInventoryControl({
    required IconData icon,
    required String title,
    required String field,
    required int value,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blueAccent,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text('$value'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (value > 0) _updateData(field, (value - 1).toString());
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _updateData(field, (value + 1).toString());
              },
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text("Medication Details"),
      backgroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
          appBar: _buildAppBar(context),
          body: const Center(child: CircularProgressIndicator()));
    }

    if (medData == null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(
            child: Text("Medication not found.",
                style: TextStyle(fontSize: 18, color: Colors.grey))),
      );
    }

    String frequency = medData!['frequency'] ?? '';
    bool isTwiceADay = frequency == "Twice a day";
    //int currentInventory = int.tryParse(medData!['currentInventory'].toString()) ?? 0;
    int currentInventory = 0;
    final inventoryValue = medData?['currentInventory'];

    if (inventoryValue is int) {
      currentInventory = inventoryValue;
    } else if (inventoryValue is double) {
      currentInventory = inventoryValue.round(); // or .toInt()
    } else if (inventoryValue is String) {
      currentInventory = int.tryParse(inventoryValue) ?? 0;
    }

    String intakeAdvice = medData!['intakeAdvice'] ?? 'None';
    TextEditingController intakeController = TextEditingController(
      text: medData!['customIntakeAdvice'] ?? '',
    );

    return Scaffold(
      appBar: _buildAppBar(context),
      backgroundColor: Colors.grey[100],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              icon: Icons.calendar_today,
              title: "Frequency",
              value: frequency,
              field: "frequency",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FrequencySelectionPage(
                      initialFrequency: frequency,
                      onSave: (Map<String, dynamic> data) async {
                        await _updateData("frequency", data['frequency']);
                        if (data.containsKey('specificDays')) {
                          await _updateData("specificDays", data['specificDays']);
                        }
                      },
                    ),
                  ),
                );
              },

            ),

            for (int i = 0; i < (medData!['reminderTimes']?.length ?? 0); i++)
              _buildSection(
                icon: Icons.alarm,
                title: "Reminder Time ",
                value: medData!['reminderTimes'][i] ?? 'N/A',
                field: "reminderTime\${i + 1}",
                onTap: () => _showTimePickerForReminder(i),
              ),

            if (isTwiceADay && (medData!['reminderTimes']?.length ?? 0) < 2)
              _buildSection(
                icon: Icons.alarm,
                title: "Reminder Time \${medData!['reminderTimes']?.length + 1}",
                value: 'N/A',
                field: "reminderTime\${medData!['reminderTimes']?.length + 1}",
              ),

            _buildInventoryControl(
              icon: Icons.inventory,
              title: "Current Inventory",
              field: "currentInventory",
              value: currentInventory,
            ),
            _buildSection(
              icon: Icons.straighten,
              title: "Unit",
              value: medData!['unit'] ?? 'N/A',
              field: "unit",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnitSelectionPage(
                      initialUnit: medData!['unit'] ?? '',
                      onUnitSelected: (selectedUnit) async {
                        await _updateData('unit', selectedUnit);
                      },
                    ),
                  ),
                );
              },
            ),
            Card(
              margin: const EdgeInsets.symmetric(vertical: 10),
              child: ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blueAccent,
                  child: Icon(Icons.fastfood, color: Colors.white),
                ),
                title: const Text("Intake Advice"),
                subtitle: DropdownButton<String>(
                  value: intakeAdvice == "Custom" ? "Custom entry" : intakeAdvice,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: [
                    "None",
                    "Before meal",
                    "With meal",
                    "After meal",
                    "Custom entry",
                  ].map((option) {
                    return DropdownMenuItem<String>(
                      value: option,
                      child: Text(option),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == "Custom entry") {
                      _showCustomInputDialog(intakeController);
                    } else {
                      _updateData("intakeAdvice", value!);
                    }
                  },
                ),
              ),
            ),

          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          onPressed: _confirmDelete,
          icon: const Icon(Icons.delete),
          label: const Text("Delete Medication"),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
      ),
    );
  }
}
