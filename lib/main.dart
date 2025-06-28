import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:device_preview/device_preview.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:medtrack/services/MedicineDatabaseHelper.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:medtrack/pages/splash_screen.dart';
import 'package:medtrack/home.dart';
import 'package:medtrack/services/notification_service.dart';
import 'package:medtrack/services/theme_provider.dart';
import 'package:medtrack/pages/setting/PinVerificationPage.dart'; // Import the PIN verification page
import 'package:cloudinary_url_gen/cloudinary.dart';
import 'package:cloudinary_flutter/cloudinary_context.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();

  try {
    await Firebase.initializeApp(
      options: kIsWeb
          ? const FirebaseOptions(
              apiKey: "AIzaSyBXfH6mUgdeFBSy3qlPHoSAA2eJGv3sELo",
              authDomain: "graduationproject-c5dba.firebaseapp.com",
              projectId: "graduationproject-c5dba",
              storageBucket: "graduationproject-c5dba.firebasestorage.app",
              messagingSenderId: "132666813360",
              appId: "1:132666813360:web:00b2bbc028c381d9360475",
              measurementId: "G-BBCMQ12SM8",
            )
          : null,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization error: $e');
  }

  await NotificationService.initialize();
  final databaseHelper = MedicineDatabaseHelper.instance;
  await databaseHelper.database; // Wait for the database to be initialized
  await databaseHelper.debugDatabase();
  CloudinaryContext.cloudinary =
      Cloudinary.fromCloudName(cloudName: 'defwfev8k');
 runApp(
  ChangeNotifierProvider(
    create: (context) => ThemeProvider(),
    child:
        /* DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => */ const MyApp(), // ),
  ),
);

}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();

  // طريقة لتغيير اللغة من أي مكان
  static void setLocale(BuildContext context, Locale newLocale) {
    final _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('en'); // اللغة الافتراضية

  void changeLocale(Locale newLocale) {
    setState(() {
      _locale = newLocale;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        brightness: Brightness.light,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black),
          bodyMedium: TextStyle(color: Colors.black87),
          titleLarge: TextStyle(color: Colors.black),
        ),
        colorScheme: const ColorScheme.light(
          background: Colors.white,
          onBackground: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.white),
          bodyMedium: TextStyle(color: Colors.white70),
          titleLarge: TextStyle(color: Colors.white),
        ),
        colorScheme: const ColorScheme.dark(
          background: Colors.black,
          onBackground: Colors.white,
        ),
      ),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      locale: _locale,
      home: const AuthCheck(),
    );
  }
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // Check if the PIN is set before navigating to HomeScreen
        return FutureBuilder<bool>(
          future: _checkIfPinSet(),
          builder: (context, pinSnapshot) {
            if (pinSnapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator();
            }

            if (pinSnapshot.hasData && pinSnapshot.data == true) {
              // Show PIN verification page if the PIN is set
              return PinVerificationPage();
            }

            // If no PIN is set, navigate directly to the home screen
            return snapshot.hasData ? const HomeScreen() : const SplashScreen();
          },
        );
      },
    );
  }

  Future<bool> _checkIfPinSet() async {
    final FlutterSecureStorage _secureStorage = FlutterSecureStorage();
    String? storedPin = await _secureStorage.read(key: 'pin');
    return storedPin != null;
  }
}
