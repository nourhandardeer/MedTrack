import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medtrack/home.dart'; // Import Home Page
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class RefillRequest extends StatefulWidget {
  final String medicationName;
  final String selectedUnit;
  final String selectedFrequency;
  final String reminderTime;
  final String documentId; // Receive document ID

  const RefillRequest({
    Key? key,
    required this.medicationName,
    required this.selectedUnit,
    required this.selectedFrequency,
    required this.reminderTime,
    required this.documentId, // Pass document ID
  }) : super(key: key);

  @override
  _RefillRequestState createState() => _RefillRequestState();
}

class _RefillRequestState extends State<RefillRequest> {
  bool isReminderOn = false;
  TextEditingController reminderController = TextEditingController(text: "10 ");
  TextEditingController currentInventory = TextEditingController(text: "30 ");

  bool _isLoading = false;

  Future<void> saveRefillReminder() async {
    setState(() {
      _isLoading = true;
    });
    try {
      Map<String, dynamic> dataToUpdate = {};

      if (isReminderOn) {
        final currentInventoryValue =
            int.tryParse(currentInventory.text.trim());
        final remindMeWhenValue = int.tryParse(reminderController.text.trim());

        if (currentInventoryValue != null) {
          dataToUpdate['currentInventory'] = currentInventoryValue;
        }

        if (remindMeWhenValue != null) {
          dataToUpdate['remindMeWhen'] = remindMeWhenValue;
        }
      }

      if (dataToUpdate.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('meds')
            .doc(widget.documentId)
            .update(dataToUpdate);
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving refill reminder: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.refillReminder),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              top: 16,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    const Icon(
                      Icons.medical_services_rounded,
                      size: 80,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppLocalizations.of(context)!.refillReminderQuestion,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.remindMe,
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Switch(
                            value: isReminderOn,
                            onChanged: (value) {
                              setState(() {
                                isReminderOn = value;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (isReminderOn)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppLocalizations.of(context)!.currentInventoryy,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: currentInventory,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              AppLocalizations.of(context)!.remindWhenRemaining,
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: reminderController,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey[300],
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : saveRefillReminder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
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
                            : Text(
                                AppLocalizations.of(context)!.save,
                                style: TextStyle(
                                    fontSize: 18, color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
