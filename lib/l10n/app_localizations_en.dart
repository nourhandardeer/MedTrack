// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'My App';

  @override
  String get welcome => 'Welcome to the app!';

  @override
  String get language => 'Language';

  @override
  String get changeLanguage => 'Tap to change language';

  @override
  String get settings => 'Settings';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get editProfileSub => 'Change name, email, and photo';

  @override
  String get notifications => 'Notifications';

  @override
  String get notificationsSub => 'Manage alerts and reminders';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get security => 'Security';

  @override
  String get securitySub => 'Change password';

  @override
  String get emergencyContacts => 'Emergency Contacts';

  @override
  String get emergencyContactsSub => 'Manage emergency numbers';

  @override
  String get deleteAccount => 'Delete my account';

  @override
  String get logout => 'Logout';

  @override
  String get help => 'Help';

  @override
  String get helpSub => 'Watch tutorial videos';

  @override
  String get profileImageUpdatedSuccess =>
      'Profile image updated successfully!';

  @override
  String get profileImageUpdatedFailed => 'Failed to upload image';

  @override
  String get profileupdated => 'Profile updated successfully!';

  @override
  String get eeditProfile => 'Edit Profile';

  @override
  String get imageChange => 'Tap image to change';

  @override
  String get firstName => 'First Name';

  @override
  String get lastName => 'Last Name';

  @override
  String get phone => 'Phone';

  @override
  String get age => 'Age';

  @override
  String get illnesses => 'Illnesses';

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get addContact => 'Add New Contact';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get addAppointment => 'Add Appointment';

  @override
  String get addDoctor => 'Add Doctor';

  @override
  String get addMedicine => 'Add Medicine';

  @override
  String get findPharmacy => 'Find A Nearby Pharmacy';

  @override
  String get addEmergencyContact => 'Add Emergency Contact';

  @override
  String get confirmDeletion => 'Confirm Account Deletion';

  @override
  String get enterPasswordToDelete =>
      'Please enter your password to delete your account.';

  @override
  String get password => 'Password';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get accountDeleted => 'Account deleted successfully';

  @override
  String get incorrectPassword => 'Incorrect password';

  @override
  String get medications => 'Medications';

  @override
  String get appointments => 'Appointments';

  @override
  String appointmentTomorrow(Object doctor, Object time) {
    return 'You have an appointment tomorrow with Dr. $doctor at $time';
  }

  @override
  String get noAppointments => 'No appointments for this day';

  @override
  String get profile => 'Profile';

  @override
  String ageAndIllnesses(Object age, Object illnesses) {
    return 'Age: $age | $illnesses';
  }

  @override
  String linkedAsEmergencyContact(Object name) {
    return 'You are an emergency contact for $name.';
  }

  @override
  String get home => 'Home';

  @override
  String get refills => 'Refills';

  @override
  String get manage => 'Manage';

  @override
  String currentInventory(Object amount, Object unit) {
    return 'Current Inventory: $amount $unit';
  }

  @override
  String reminderTimes(Object time) {
    return 'Reminder Time: $time';
  }

  @override
  String get medication => 'Medication';

  @override
  String get dosage => 'Dosage';

  @override
  String get currentInventoryy => 'Current Inventory';

  @override
  String get reminderTime => 'Reminder Time';

  @override
  String get refillThreshold => 'Refill when inventory is less than';

  @override
  String get medicationDetails => 'Medication Details';

  @override
  String get frequency => 'Frequency';

  @override
  String get intakeAdvice => 'Intake Advice';

  @override
  String get deleteMedication => 'Delete Medication';

  @override
  String get updatedSuccess => 'Updated successfully!';

  @override
  String get updatedFailed => 'Failed to update.';

  @override
  String get reminderUpdatedSuccess => 'Reminder time updated successfully!';

  @override
  String get reminderUpdatedFailed => 'Failed to update reminder time.';

  @override
  String get confirmDeleteMedication =>
      'Are you sure you want to delete this medication?';

  @override
  String get none => 'None';

  @override
  String get beforeMeal => 'Before meal';

  @override
  String get withMeal => 'With meal';

  @override
  String get afterMeal => 'After meal';

  @override
  String get customEntry => 'Custom entry';

  @override
  String get doctors => 'Doctors';

  @override
  String get noDoctorsFound => 'No doctors found.';

  @override
  String get specialty => 'Specialty';

  @override
  String get editDoctor => 'Edit Doctor';

  @override
  String get doctorName => 'Doctor Name';

  @override
  String get location => 'Location';

  @override
  String get notes => 'Notes';

  @override
  String get doctorUpdatedSuccess => 'Doctor updated successfully.';

  @override
  String get date => 'Date';

  @override
  String get time => 'Time';

  @override
  String dateWithValue(Object date) {
    return 'Date: $date';
  }

  @override
  String timeWithValue(Object time) {
    return 'Time: $time';
  }

  @override
  String get appointmentUpdatedSuccess => 'Appointment updated successfully.';

  @override
  String get editAppointment => 'Edit Appointment';

  @override
  String get chooseOption => 'Choose an Option';

  @override
  String get newAppointment => 'New Appointment';

  @override
  String get newDoctor => 'New Doctor';

  @override
  String get selectTime => 'Select a time';

  @override
  String get selectDate => 'Select a date';

  @override
  String get save => 'Save';

  @override
  String get selectMedicationForReminder =>
      'Which medication would you like to set the reminder for?';

  @override
  String get selectUnit => 'Select Unit';

  @override
  String get next => 'Next';

  @override
  String get medicationFrequencyQuestion =>
      'How often do you take this medication?';

  @override
  String get onceADay => 'Once a day';

  @override
  String get twiceADay => 'Twice a day';

  @override
  String get threeTimesADay => '3 times a day';

  @override
  String get onceAWeek => 'Once a week';

  @override
  String get specificDays => 'Specific days of the week';

  @override
  String get asNeeded => 'Only as needed';

  @override
  String get selectFrequency => 'Select Frequency';

  @override
  String get dateAndTime => 'Date & Time';

  @override
  String get refillReminder => 'Refill Reminder';

  @override
  String get refillReminderQuestion =>
      'Do you want to get reminders to refill your medications?';

  @override
  String get remindMe => 'Remind me';

  @override
  String get remindWhenRemaining => 'Remind me when remaining';

  @override
  String get signUp => 'Sign Up';

  @override
  String get logIn => 'Log In';

  @override
  String get email => 'Email';

  @override
  String get forgetPassword => 'Forget Password';

  @override
  String get noAccount => 'Don\'t have an account? Sign Up';

  @override
  String get haveAccount => 'Already have an account? Log In';

  @override
  String get createAccount => 'Create an Account';

  @override
  String get welcomeBack => 'Welcome back';

  @override
  String get verifyYourEmail => 'Verify Your Email';

  @override
  String get verificationEmailSentTo => 'A verification email was sent to';

  @override
  String get resendEmail => 'Resend Email';

  @override
  String get waitingForVerification => 'Waiting for verification...';

  @override
  String get profileSetup => 'Profile Setup';

  @override
  String get addProfilePhoto => 'Add Profile Photo';

  @override
  String get saveProfile => 'Save Profile';
}
