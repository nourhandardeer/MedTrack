import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medtrack/pages/add_appointment.dart';
import 'package:medtrack/pages/add_doctor.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../pages/EditAppointmentPage.dart';
import '../pages/EditDoctorPage.dart';
import '../services/firestore_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ManagePage extends StatefulWidget {
  ManagePage({super.key});
  @override
  State<ManagePage> createState() => _ManagePageState();
}

class _ManagePageState extends State<ManagePage> {
  final FirestoreService _firestoreService = FirestoreService();
  Future<List<QueryDocumentSnapshot>>? _appointmentsFuture;
  Future<List<QueryDocumentSnapshot>>? _doctorsFuture;
  Future<List<String>>? _linkedUsersFuture;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final linkedUserIds = await _firestoreService.getLinkedUserIds();
    print("Linked user IDs: $linkedUserIds");

    final appointments = await _firestoreService.getAppointments(linkedUserIds);
    final doctors = await _firestoreService.getDoctors(linkedUserIds);

    setState(() {
      _linkedUsersFuture = Future.value(linkedUserIds);
      _appointmentsFuture = Future.value(appointments);
      _doctorsFuture = Future.value(doctors);
    });
  }

  Future<List<QueryDocumentSnapshot>> _getAppointments() async {
    final linkedUserIds = await _linkedUsersFuture!;
    return _firestoreService.getAppointments(linkedUserIds);
  }

  Future<List<QueryDocumentSnapshot>> _getDoctors() async {
    final linkedUserIds = await _linkedUsersFuture!;
    return _firestoreService.getDoctors(linkedUserIds);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Please log in to see your data."));
    }

    return FutureBuilder<List<String>>(
      future: _linkedUsersFuture,
      builder: (context, linkedUsersSnapshot) {
        if (linkedUsersSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (linkedUsersSnapshot.hasError || !linkedUsersSnapshot.hasData) {
          return const Center(
            child: Text("Error loading user data.",
                style: TextStyle(color: Colors.red)),
          );
        }

        final linkedUserIds = linkedUsersSnapshot.data!;

        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              toolbarHeight: 0,
              bottom: TabBar(
                indicatorColor: Colors.blue,
                labelColor: Colors.blue,
                tabs: [
                  Tab(text: AppLocalizations.of(context)!.appointments, icon: const Icon(Icons.event)),
                  Tab(text:  AppLocalizations.of(context)!.doctors, icon: Icon(FontAwesomeIcons.userDoctor)),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                _buildAppointmentsTab(context),
                _buildDoctorsTab(),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () => _showBottomSheet(context),
              heroTag: 'manage-fab',
              child: const Icon(Icons.add, color: Colors.white),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppointmentsTab(BuildContext context) {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return _buildEmptyState(context);
        }

        final appointments = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: appointments.length,
          separatorBuilder: (_, __) =>
              const Divider(thickness: 1, color: Colors.grey),
          itemBuilder: (context, index) {
            var appointment = appointments[index];
            return _buildAppointmentCard(appointment, appointment.id, context);
          },
        );
      },
    );
  }

  Widget _buildDoctorsTab() {
    return FutureBuilder<List<QueryDocumentSnapshot>>(
      future: _doctorsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return  Center(child: Text(AppLocalizations.of(context)!.noDoctorsFound));
        }

        final doctors = snapshot.data!;
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: doctors.length,
          separatorBuilder: (_, __) =>
              const Divider(thickness: 1, color: Colors.grey),
          itemBuilder: (context, index) {
            final doctor = doctors[index];
            return Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color.fromARGB(255, 220, 232, 242),
                    Color(0xFFFFFFFF)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
                ],
              ),
              child: Card(
                color: Colors.transparent,
                elevation: 0,
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.blue),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteDoctor(doctor.id, context),
                  ),
                  title: Text(
                    "Dr. ${doctor['doctorName']}",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!
      .specialty
      .replaceAll('{specialty}', doctor['specialty'] ?? ''),
                          style: const TextStyle(
                              fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditDoctorPage(
                          doctorId: doctor.id,
                          initialData: doctor.data() as Map<String, dynamic>,
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

  Future<void> _deleteDoctor(String doctorId, BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc = await firestore.collection('doctors').doc(doctorId).get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Doctor not found')));
        return;
      }

      await firestore.collection('doctors').doc(doctorId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Doctor deleted successfully!'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Widget _buildAppointmentCard(
      QueryDocumentSnapshot appointment, String id, BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color.fromARGB(255, 220, 232, 242), Color(0xFFFFFFFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 8),
        child: ListTile(
          leading: const Icon(Icons.event, color: Colors.blue),
          trailing: IconButton(
            onPressed: () => deleteAppointment(id, context),
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
          title: Text("Dr. ${appointment['doctorName']}",
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!
      .dateWithValue(appointment['appointmentDate'] ?? ''),
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
              Text(AppLocalizations.of(context)!
      .timeWithValue(appointment['appointmentTime'] ?? ''),
                  style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => EditAppointmentPage(
                  appointmentId: id,
                  initialData: appointment.data() as Map<String, dynamic>,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> deleteAppointment(
      String appointmentId, BuildContext context) async {
    try {
      final firestore = FirebaseFirestore.instance;
      final doc =
          await firestore.collection('appointments').doc(appointmentId).get();

      if (!doc.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment not found')));
        return;
      }

      await firestore.collection('appointments').doc(appointmentId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Appointment deleted successfully!'),
            backgroundColor: Colors.red),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('images/photo2.png',
              width: 200, height: 200, fit: BoxFit.cover),
          const SizedBox(height: 16),
          const Text(
            'Manage your healthcare easily! Add your preferred doctor or appointment.',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => _showBottomSheet(context),
            child: const Text('Get Started',
                style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Text(AppLocalizations.of(context)!.chooseOption,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ListTile(
              leading: const Icon(Icons.event, color: Colors.blue),
              title: Text(AppLocalizations.of(context)!.addAppointment),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AddAppointment()));
              },
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.userDoctor),
              title: Text(AppLocalizations.of(context)!.addDoctor),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AddDoctor()));
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              style: TextButton.styleFrom(
                backgroundColor: Colors.grey[300],
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: () => Navigator.pop(context),
              child:  Text(AppLocalizations.of(context)!.cancel,
                  style: TextStyle(color: Colors.black, fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
