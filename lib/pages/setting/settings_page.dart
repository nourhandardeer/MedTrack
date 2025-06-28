import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medtrack/pages/EditProfilePage.dart';
import 'package:medtrack/pages/loggin.dart';
import 'package:medtrack/pages/splash_screen.dart';
import 'package:medtrack/pages/EmergencyContactPage.dart';
import 'package:medtrack/services/theme_provider.dart';
import 'package:provider/provider.dart';
import '../../services/firestore_service.dart';
import 'ChangePasswordPage.dart';
import 'SetPinPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medtrack/auth.dart';
import 'package:medtrack/pages/HelpPage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _notificationsEnabled = true;
  bool _isEmergency = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
    _checkIfEmergencyContact();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _checkIfEmergencyContact() async {
    bool isEmergency = await FirestoreService().isEmergencyContact();
    setState(() {
      _isEmergency = isEmergency;
    });
  }

  Future<void> _toggleNotifications(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = value;
    });
    await prefs.setBool('notifications_enabled', value);
  }

  final Auth auth = Auth();

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    TextEditingController passwordController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Section
          ListTile(
            leading: Icon(Icons.person, color: Colors.blue),
            title: Text('Edit Profile'),
            subtitle: Text('Change name, email, and photo'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => EditProfilePage()));
            },
          ),
          Divider(),

          // Notification Settings
          ListTile(
            leading: Icon(Icons.notifications, color: Colors.orange),
            title: Text('Notifications'),
            subtitle: Text('Manage alerts and reminders'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: (bool value) {
                _toggleNotifications(value);
              },
            ),
          ),
          Divider(),

          // Emergency Contacts
          ListTile(
              leading: Icon(Icons.phone, color: Colors.red),
              title: Text('Emergency Contacts'),
              subtitle: Text('Manage emergency numbers'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                if (_isEmergency) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Action not allowed'),
                      content: Text(
                          'You cannot add emergency contacts because you are already an emergency contact.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text('OK'),
                        ),
                      ],
                    ),
                  );
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => EmergencyContactPage()));
                }
                ;
              }),
          Divider(),

          // Security Settings (Change Password or Set PIN)
          ListTile(
            leading: Icon(Icons.lock, color: Colors.purple),
            title: Text('Security'),
            subtitle: Text('Change password or set PIN'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              _showSecurityOptions(context);
            },
          ),
          Divider(),

          // Dark Mode Toggle
          ListTile(
            leading: Icon(Icons.dark_mode, color: Colors.black),
            title: Text('Dark Mode'),
            trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme(value);
                }),
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text('Delete my account'),
            onTap: () async {
              final passwordController = TextEditingController();

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Confirm Account Deletion'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                          'Please enter your password to delete your account.'),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration:
                            const InputDecoration(labelText: 'Password'),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel')),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete')),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await deleteAccountAndData(passwordController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Account deleted successfully')),
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Incorrect password')),
                  );
                }
              }
            },
          ),
          Divider(),

          // Logout Button
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout'),
            onTap: () async {
              await auth.signOut(); // call your custom function here

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SplashScreen()),
              );
            },
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.help_outline, color: Colors.teal),
            title: Text('Help'),
            subtitle: Text('Watch tutorial videos'),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpPage()),
              );
            },
          ),
        ],
      ),
    );
  }
  Future<void> deleteAccountAndData(String password) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userId = user.uid;

    try {
      // --- Re-authenticate
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final userDocRef = FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userDocRef.get();
      final userData = userDoc.data();

      final isEmergency = userData?['isEmergency'] == true;
      final phone = userData?['phone'];

      if (isEmergency) {
        if (phone != null && phone.toString().isNotEmpty) {
          final phoneStr = phone.toString();

          // --- Delete from emergency_contacts/{phone}
          final emergencyTopDocRef = FirebaseFirestore.instance
              .collection('emergencyContacts')
              .doc(phoneStr);

          final emergencyTopDoc = await emergencyTopDocRef.get();
          if (emergencyTopDoc.exists) {
            await emergencyTopDocRef.delete();
          }

          // --- Also delete from all users' subcollection emergencyContacts/{phone}
          final allUsers = await FirebaseFirestore.instance.collection('users').get();
          for (final patient in allUsers.docs) {
            final subContactRef = FirebaseFirestore.instance
                .collection('users')
                .doc(patient.id)
                .collection('emergencyContacts')
                .doc(phoneStr);

            final subContactDoc = await subContactRef.get();
            if (subContactDoc.exists) {
              await subContactRef.delete();
            }
          }
        }

        // Delete user document
        await userDocRef.delete();

        // Delete Firebase Auth account
        await user.delete();

        return;
      }

      // --- If not emergency, delete subcollections
      final subcollections = ['medsTaken', 'emergencyContacts'];
      for (final sub in subcollections) {
        final subDocs = await userDocRef.collection(sub).get();
        for (final doc in subDocs.docs) {
          await doc.reference.delete();
        }
      }

      // --- Delete from top-level meds, doctors, appointments
      final topCollections = ['meds', 'doctors', 'appointments'];
      for (final col in topCollections) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection(col)
            .where('linkedUserIds', arrayContains: userId)
            .get();

        for (final doc in querySnapshot.docs) {
          await doc.reference.delete();
        }
      }

      // Delete user doc and account
      await userDocRef.delete();
      await user.delete();

    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception('Please log in again to delete your account.');
      } else {
        throw Exception('Failed to delete account: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
  void _showSecurityOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.lock_open, color: Colors.blue),
              title: Text('Change Password'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                );
              },
            ),
            Divider(),
            ListTile(
              leading: Icon(Icons.pin, color: Colors.green),
              title: Text('Set PIN'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SetPinPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
