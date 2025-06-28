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
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:medtrack/main.dart';

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
        title: Text(AppLocalizations.of(context)!.settings),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Section
          ListTile(
            leading: Icon(Icons.person, color: Colors.blue),
            title: Text(AppLocalizations.of(context)!.editProfile),
            subtitle: Text(AppLocalizations.of(context)!.editProfileSub),
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
            title: Text(AppLocalizations.of(context)!.notifications),
            subtitle: Text(AppLocalizations.of(context)!.notificationsSub),
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
              title: Text(AppLocalizations.of(context)!.emergencyContacts),
              subtitle: Text(AppLocalizations.of(context)!.emergencyContactsSub),
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
            title: Text(AppLocalizations.of(context)!.security),
            subtitle: Text(AppLocalizations.of(context)!.securitySub),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ChangePasswordPage()),
                );
              },
          ),
          Divider(),

          // Dark Mode Toggle
          ListTile(
            leading: Icon(Icons.dark_mode, color: Colors.black),
            title: Text(AppLocalizations.of(context)!.darkMode),
            trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme(value);
                }),
          ),
          Divider(),

          ListTile(
            leading: Icon(Icons.delete_forever, color: Colors.red),
            title: Text(AppLocalizations.of(context)!.deleteAccount),
            onTap: () async {
              final passwordController = TextEditingController();

              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title:  Text(AppLocalizations.of(context)!.confirmDeletion),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(AppLocalizations.of(context)!.enterPasswordToDelete),
                      TextField(
                        controller: passwordController,
                        obscureText: true,
                        decoration:
                             InputDecoration(labelText:(AppLocalizations.of(context)!.password),),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(AppLocalizations.of(context)!.cancel),),
                    TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(AppLocalizations.of(context)!.delete),),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await deleteAccountAndData(passwordController.text.trim());
                  ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(
                        content:Text(AppLocalizations.of(context)!.accountDeleted),),
                  );
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const SplashScreen()),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppLocalizations.of(context)!.incorrectPassword)),
                  );
                }
              }
            },
          ),
          Divider(),

          // Logout Button
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text(AppLocalizations.of(context)!.logout),
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
            title: Text(AppLocalizations.of(context)!.help),
            subtitle: Text(AppLocalizations.of(context)!.helpSub),
            trailing: Icon(Icons.arrow_forward_ios),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => HelpPage()),
              );
            },
          ),
          Divider(),

          ListTile(
  leading: Icon(Icons.language, color: Colors.indigo),
  title: Text(AppLocalizations.of(context)!.language),
  subtitle: Text(AppLocalizations.of(context)!.changeLanguage),
  trailing: Icon(Icons.arrow_forward_ios),
  onTap: () {
    _showLanguageSelectionDialog(context);
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
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);

      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final userDoc = await userDocRef.get();
      final userData = userDoc.data();
      final phone = userData?['phone'];

      if (phone != null && phone.toString().isNotEmpty) {
        final contactsQuery = await userDocRef
            .collection('emergencyContacts')
            .where('phone', isEqualTo: phone)
            .get();

        for (final doc in contactsQuery.docs) {
          await doc.reference.delete();
        }
      }

      final medsTakenDocs = await userDocRef.collection('medsTaken').get();
      for (final doc in medsTakenDocs.docs) {
        final data = doc.data();
        final List<dynamic>? linkedUserIds = data['linkedUserIds'];

        if (linkedUserIds != null && linkedUserIds.contains(userId)) {
          await doc.reference.update({
            'linkedUserIds': FieldValue.arrayRemove([userId]),
          });

          final updatedDoc = await doc.reference.get();
          final updatedLinkedUserIds = updatedDoc.data()?['linkedUserIds'];
          if (updatedLinkedUserIds == null || updatedLinkedUserIds.isEmpty) {
            await doc.reference.delete();
          }
        } else {
          await doc.reference.delete();
        }
      }

      await userDocRef.delete();

      if (phone != null && phone.toString().isNotEmpty) {
        final emergencyRef = FirebaseFirestore.instance
            .collection('emergencyContacts')
            .doc(phone.toString());
        final emergencyDoc = await emergencyRef.get();
        if (emergencyDoc.exists) {
          await emergencyRef.delete();
        }
      }

      final topLevelCollections = ['meds', 'doctors', 'appointments'];
      for (final collectionName in topLevelCollections) {
        final querySnapshot =
            await FirebaseFirestore.instance.collection(collectionName).get();
        for (final doc in querySnapshot.docs) {
          final data = doc.data();
          final List<dynamic>? linkedUserIds = data['linkedUserIds'];

          if (linkedUserIds != null && linkedUserIds.contains(userId)) {
            await doc.reference.update({
              'linkedUserIds': FieldValue.arrayRemove([userId]),
            });

            final updatedDoc = await doc.reference.get();
            final updatedLinkedUserIds = updatedDoc.data()?['linkedUserIds'];
            if (updatedLinkedUserIds == null || updatedLinkedUserIds.isEmpty) {
              await doc.reference.delete();
            }
          }
        }
      }

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

  void _showLanguageSelectionDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(AppLocalizations.of(context)!.language),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text('English'),
            onTap: () {
              MyApp.setLocale(context, const Locale('en'));
              Navigator.pop(context);
            },
          ),
          ListTile(
            title: Text('العربية'),
            onTap: () {
              MyApp.setLocale(context, const Locale('ar'));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ),
  );
}


  // Function to show the Security options dialog
 /* void _showSecurityOptions(BuildContext context) {
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
  }*/
}
