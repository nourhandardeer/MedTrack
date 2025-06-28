import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite/sqflite.dart';
import '../services/MedicineDatabaseHelper.dart';
import '../services/firestore_service.dart';
import 'times.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddMedicationPage extends StatefulWidget {
  @override
  _AddMedicationPageState createState() => _AddMedicationPageState();
}

class _AddMedicationPageState extends State<AddMedicationPage> {
  final TextEditingController medicationController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  // final MedicationService medicationService = MedicationService();
  List<String> medicationSuggestions = [];
  final _databaseHelper = MedicineDatabaseHelper.instance;
  List<String> _suggestions = [];
  String? selectedUnit;
  int dosage = 1;
  String? tempDocId;

  final List<String> units = [
    "Pill(s)",
    "Ampoule(s)",
    "Tablet(s)",
    "Capsule(s)",
    "IU",
    "Application",
    "Drop",
    "Gram",
    "Injection",
    "Milligram",
    "Milliliter",
    "MM",
    "Packet",
    "Pessary",
    "Piece",
    "Portion",
    "Puff",
    "Spray",
    "Suppository",
    "Teaspoon",
    "Vaginal Capsule",
    "Vaginal Suppository",
    "Vaginal Tablet",
    "MG"
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late Future<Database> _databaseInitFuture;

  @override
  void initState() {
    super.initState();
    _checkDatabaseReady(); // Just check if it's ready
    _loadInitialSuggestions();
    _databaseHelper.debugDatabase();
  }

  Future<void> _checkDatabaseReady() async {
    print("Checking if database is ready in AddMedicationPage...");
    // Accessing the database getter will ensure it's initialized
    await _databaseHelper.database;
    print("Database ready for use in AddMedicationPage.");
  }

  Future<void> _loadInitialSuggestions() async {
    await _getOfflineSuggestions("");
  }

  Future<void> _getOfflineSuggestions(String query) async {
    print("_getOfflineSuggestions called with query: $query");
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final db = await _databaseHelper.database;
    final List<Map<String, dynamic>> results = await db.rawQuery(
      "SELECT name FROM ${MedicineDatabaseHelper.table} WHERE name LIKE ? COLLATE NOCASE",
      ['$query%'],
    );

    setState(() {
      _suggestions = results.map((row) => row['name'] as String).toList();
    });

    print("🔍 Results found: ${_suggestions.length}");
  }

  bool _isLoading = false;

  Future<void> _saveMedicationData() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('User not logged in'), backgroundColor: Colors.red),
      );
      return;
    }
    String uid = user.uid;
    setState(() {
      _isLoading = true;
    });

    try {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      String? phoneNumber = userDoc['phone'];
      if (phoneNumber == null) return;

      String? docId = await _firestoreService.saveData(
        collection: 'meds',
        context: context,
        data: {
          'name': medicationController.text,
          'unit': selectedUnit,
          'dosage': dosage,
          'timestamp': FieldValue.serverTimestamp(),
        },
      );

      if (docId != null) {
        tempDocId = docId;
        _navigateToTimesPage(docId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Error saving data'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToTimesPage(String docId) {
    try {
      if (selectedUnit != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TimesPage(
              medicationName: medicationController.text,
              selectedUnit: selectedUnit!,
              documentId: docId,
              startDate: '',
              dosage: dosage.toString(),
            ),
          ),
        );
      }
    } catch (e) {
      print("❌ Navigation Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // ✅ Dynamic
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(
              AppLocalizations.of(context)!.selectMedicationForReminder,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) async {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                await _getOfflineSuggestions(textEditingValue.text);
                print(
                    "_suggestions list after fetching for '${textEditingValue.text}': $_suggestions");
                return _suggestions.where((name) {
                  return name
                      .toLowerCase()
                      .startsWith(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                medicationController.text = selection;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onEditingComplete) {
                return TextField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.medication,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (text) {
                    if (text.isNotEmpty) _getOfflineSuggestions(text);
                  },
                  onEditingComplete: onEditingComplete,
                );
              },
              optionsViewBuilder: (BuildContext context,
                  AutocompleteOnSelected<String> onSelected,
                  Iterable<String> options) {
                if (options.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Align(
                  alignment: Alignment.topLeft,
                  child: Material(
                    elevation: 4.0,
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 200.0,
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        itemCount: options.length,
                        itemBuilder: (BuildContext context, int index) {
                          final String option = options.elementAt(index);
                          return InkWell(
                            onTap: () {
                              onSelected(option);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16.0, vertical: 12.0),
                              child: Text(option),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 30),
             Text(
              AppLocalizations.of(context)!.selectUnit,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              value: selectedUnit,
              hint:  Text(AppLocalizations.of(context)!.selectUnit),
              items: units
                  .map((unit) =>
                      DropdownMenuItem(value: unit, child: Text(unit)))
                  .toList(),
              onChanged: (value) => setState(() => selectedUnit = value),
            ),
            const SizedBox(height: 30),
             Text(
              AppLocalizations.of(context)!.dosage,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: dosage > 1 ? () => setState(() => dosage--) : null,
                  icon: const Icon(Icons.remove_circle,
                      color: Colors.red, size: 30),
                ),
                Text(
                  "$dosage ${selectedUnit ?? ''}",
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed:
                      dosage < 10 ? () => setState(() => dosage++) : null,
                  icon: const Icon(Icons.add_circle,
                      color: Colors.green, size: 30),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: () {
            if (medicationController.text.isNotEmpty && selectedUnit != null) {
              _isLoading ? null : _saveMedicationData();
              // _navigateToTimesPage(docId)
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Please enter a medication name and select a unit'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              :  Text(
                  AppLocalizations.of(context)!.next,
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
