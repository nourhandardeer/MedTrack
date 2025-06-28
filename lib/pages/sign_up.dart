import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medtrack/auth.dart';
import 'package:medtrack/home.dart';
import 'package:medtrack/pages/loggin.dart';
import 'package:medtrack/pages/profile_setup.dart';
import 'package:medtrack/services/firestore_service.dart';
import 'package:medtrack/services/verifyEmail.dart';
import '../services/PhoneValidator.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../services/checkPhoneNumberUniqueness.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  FirestoreService firestore = FirestoreService();

  String? errorMessage = '';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool isEmergency = false;

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,10}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      errorMessage = '';
    });

    try {
      String firstName = firstNameController.text.trim();
      String lastName = lastNameController.text.trim();
      String email = emailController.text.trim();
      String password = passwordController.text.trim();
      String rawPhone = phoneController.text.trim();


      final validationError = PhoneValidator.validatePhoneNumber(rawPhone);
      if (validationError != null) {
        errorMessage = validationError;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
        setState(() => _isLoading = false);
        return;
      }

      final cleaned = PhoneValidator.normalizePhone(rawPhone);

      final isEgyptian = RegExp(r'^01[0-9]{9}$').hasMatch(cleaned);
      final phone = isEgyptian ? cleaned : rawPhone.replaceAll(' ', '');
      final phoneIsInEmergency = await firestore.isEmergencyContactByPhone(phone);


      isEmergency = phoneIsInEmergency;

      if (phoneIsInEmergency) {
        print("Phone is in emergencyContacts — allowing emergency signup only");
      }

      final uniquenessError = await checkPhoneNumberUniqueness(phone);
      if (uniquenessError != null) {
        errorMessage = uniquenessError;
        setState(() => _isLoading = false);
        return;
      }


      // Create the user
      String? errorMsg = await Auth().createUserWithEmailAndPassword(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
        phone: phone,
      );

      if (errorMsg == null) {
        User? user = FirebaseAuth.instance.currentUser;

        if (user != null) {

          if (!user.emailVerified) {
            await user.sendEmailVerification();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => VerifyEmailPage(
                  user: user,
                  firstName: firstName,
                  lastName: lastName,
                  phone: phone,
                  email: email,
                ),
              ),
            );
          } else {
            bool isEmergency = await firestore.checkAndLinkEmergencyContact(user, user.uid, phone);
            _onSignupSuccess(user.uid, firstName, lastName, phone, email, isEmergency);
          }

        }
      } else {
        errorMessage = errorMsg;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
      }

    } on FirebaseAuthException catch (e) {
      print("Registration error: ${e.code} - ${e.message}");
      setState(() {
        errorMessage = e.message ?? "An unexpected error occurred.";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
    } catch (e) {
      print("Unexpected registration error: $e");
      setState(() {
        errorMessage = "An unexpected error occurred.";
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage!)));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _onSignupSuccess(String userId, String firstName, String lastName,
      String phone, String email, bool isEmergency) async {
    final normalizedPhone = PhoneValidator.normalizePhone(phone);

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

      // Update user document and preserve `isEmergency` passed in
      await userRef.set({
        'firstName': firstName,
        'lastName': lastName,
        'phone': normalizedPhone,
        'email': email,
        'isEmergency': isEmergency,
      }, SetOptions(merge: true));

      if (isEmergency) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileSetupPage(
              userId: userId,
              firstName: firstName,
              lastName: lastName,
              phone: normalizedPhone,
              isEmergency: isEmergency,
            ),
          ),
        );
      }
    } catch (e) {
      print("Error during post-signup navigation: $e");

      // Fallback navigation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileSetupPage(
            userId: userId,
            firstName: firstName,
            lastName: lastName,
            phone: normalizedPhone,
            isEmergency: isEmergency,
          ),
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Text(AppLocalizations.of(context)!.createAccount,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Image.asset('images/MedTrack -logo.png',
                      width: 150, height: 150),
                  const SizedBox(height: 20),
                  _buildTextFormField(
                    firstNameController,
                    AppLocalizations.of(context)!.firstName,
                    'Enter your first name',
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  _buildTextFormField(
                    lastNameController,
                    AppLocalizations.of(context)!.lastName,
                    'Enter your last name',
                    validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  _buildTextFormField(
                    emailController,
                    AppLocalizations.of(context)!.email,
                    'Enter your email',
                    validator: _validateEmail,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  _buildTextFormField(
                    passwordController,
                    AppLocalizations.of(context)!.password,
                    'Enter your password',
                    validator: _validatePassword,
                    obscureText: _obscurePassword,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  _buildTextFormField(
                    phoneController,
                    AppLocalizations.of(context)!.phone,
                    'Enter your phone number',
                    validator: PhoneValidator.validatePhoneNumber,
                    keyboardType: TextInputType.phone,
                  ),
                  if (errorMessage != null && errorMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade900,
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
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          :  Text(
                        AppLocalizations.of(context)!.signUp,
                        style:
                        TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      // Navigate to Login Page
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => LoginScreen()),
                      );
                    },
                    child:  Text(
                      AppLocalizations.of(context)!.haveAccount,
                      style: TextStyle(
                          fontSize: 13,
                          color: Color.fromARGB(255, 13, 71, 161)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField(
      TextEditingController controller,
      String label,
      String hint, {
        String? Function(String?)? validator,
        TextInputType? keyboardType,
        bool obscureText = false,
        Widget? suffixIcon,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: suffixIcon,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}