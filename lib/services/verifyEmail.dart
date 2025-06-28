import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:medtrack/home.dart';
import 'package:medtrack/pages/profile_setup.dart';
class VerifyEmailPage extends StatefulWidget {
  final User user;
  final String firstName, lastName, phone, email;

  const VerifyEmailPage({
    required this.user,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
  });

  @override
  _VerifyEmailPageState createState() => _VerifyEmailPageState();
}

class _VerifyEmailPageState extends State<VerifyEmailPage> {
  Timer? _timer;
  bool canResend = true;

  @override
  void initState() {
    super.initState();
    _startEmailCheckTimer();
  }

  void _startEmailCheckTimer() {
    _timer = Timer.periodic(Duration(seconds: 5), (_) async {
      await widget.user.reload();
      var refreshedUser = FirebaseAuth.instance.currentUser;

      if (refreshedUser != null && refreshedUser.emailVerified) {
        _timer?.cancel();

        // Save to Firestore ONLY after verification
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.user.uid)
            .set({
          'firstName': widget.firstName,
          'lastName': widget.lastName,
          'email': widget.email,
          'phone': widget.phone,
          'isEmergency': false,
        });

        // Navigate to Profile Setup page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupPage(
              userId: widget.user.uid,
              firstName: widget.firstName,
              lastName: widget.lastName,
              phone: widget.phone,
            ),
          ),
        );
      }
    });
  }

  void _resendVerificationEmail() async {
    if (!canResend) return;

    try {
      await widget.user.sendEmailVerification();
      setState(() => canResend = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification email resent')),
      );

      await Future.delayed(Duration(seconds: 30));
      setState(() => canResend = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not resend verification email')),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify Your Email")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('A verification email was sent to ${widget.email}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: canResend ? _resendVerificationEmail : null,
              child: Text('Resend Email'),
            ),
            const SizedBox(height: 10),
            Text('Waiting for verification...'),
          ],
        ),
      ),
    );
  }
}