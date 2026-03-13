import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar')
  ];

  /// No description provided for @title.
  ///
  /// In en, this message translates to:
  /// **'My App'**
  String get title;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to the app!'**
  String get welcome;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Tap to change language'**
  String get changeLanguage;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @editProfileSub.
  ///
  /// In en, this message translates to:
  /// **'Change name, email, and photo'**
  String get editProfileSub;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notificationsSub.
  ///
  /// In en, this message translates to:
  /// **'Manage alerts and reminders'**
  String get notificationsSub;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @securitySub.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get securitySub;

  /// No description provided for @emergencyContacts.
  ///
  /// In en, this message translates to:
  /// **'Emergency Contacts'**
  String get emergencyContacts;

  /// No description provided for @emergencyContactsSub.
  ///
  /// In en, this message translates to:
  /// **'Manage emergency numbers'**
  String get emergencyContactsSub;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteAccount;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @helpSub.
  ///
  /// In en, this message translates to:
  /// **'Watch tutorial videos'**
  String get helpSub;

  /// No description provided for @profileImageUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile image updated successfully!'**
  String get profileImageUpdatedSuccess;

  /// No description provided for @profileImageUpdatedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to upload image'**
  String get profileImageUpdatedFailed;

  /// No description provided for @profileupdated.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get profileupdated;

  /// No description provided for @eeditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get eeditProfile;

  /// No description provided for @imageChange.
  ///
  /// In en, this message translates to:
  /// **'Tap image to change'**
  String get imageChange;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get lastName;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @age.
  ///
  /// In en, this message translates to:
  /// **'Age'**
  String get age;

  /// No description provided for @illnesses.
  ///
  /// In en, this message translates to:
  /// **'Illnesses'**
  String get illnesses;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @addContact.
  ///
  /// In en, this message translates to:
  /// **'Add New Contact'**
  String get addContact;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @addAppointment.
  ///
  /// In en, this message translates to:
  /// **'Add Appointment'**
  String get addAppointment;

  /// No description provided for @addDoctor.
  ///
  /// In en, this message translates to:
  /// **'Add Doctor'**
  String get addDoctor;

  /// No description provided for @addMedicine.
  ///
  /// In en, this message translates to:
  /// **'Add Medicine'**
  String get addMedicine;

  /// No description provided for @findPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Find A Nearby Pharmacy'**
  String get findPharmacy;

  /// No description provided for @addEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'Add Emergency Contact'**
  String get addEmergencyContact;

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Account Deletion'**
  String get confirmDeletion;

  /// No description provided for @enterPasswordToDelete.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password to delete your account.'**
  String get enterPasswordToDelete;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Account deleted successfully'**
  String get accountDeleted;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password'**
  String get incorrectPassword;

  /// No description provided for @medications.
  ///
  /// In en, this message translates to:
  /// **'Medications'**
  String get medications;

  /// No description provided for @appointments.
  ///
  /// In en, this message translates to:
  /// **'Appointments'**
  String get appointments;

  /// No description provided for @appointmentTomorrow.
  ///
  /// In en, this message translates to:
  /// **'You have an appointment tomorrow with Dr. {doctor} at {time}'**
  String appointmentTomorrow(Object doctor, Object time);

  /// No description provided for @noAppointments.
  ///
  /// In en, this message translates to:
  /// **'No appointments for this day'**
  String get noAppointments;

  /// No description provided for @profile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// No description provided for @ageAndIllnesses.
  ///
  /// In en, this message translates to:
  /// **'Age: {age} | {illnesses}'**
  String ageAndIllnesses(Object age, Object illnesses);

  /// No description provided for @linkedAsEmergencyContact.
  ///
  /// In en, this message translates to:
  /// **'You are an emergency contact for {name}.'**
  String linkedAsEmergencyContact(Object name);

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @refills.
  ///
  /// In en, this message translates to:
  /// **'Refills'**
  String get refills;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @currentInventory.
  ///
  /// In en, this message translates to:
  /// **'Current Inventory: {amount} {unit}'**
  String currentInventory(Object amount, Object unit);

  /// No description provided for @reminderTimes.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time: {time}'**
  String reminderTimes(Object time);

  /// No description provided for @medication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medication;

  /// No description provided for @dosage.
  ///
  /// In en, this message translates to:
  /// **'Dosage'**
  String get dosage;

  /// No description provided for @currentInventoryy.
  ///
  /// In en, this message translates to:
  /// **'Current Inventory'**
  String get currentInventoryy;

  /// No description provided for @reminderTime.
  ///
  /// In en, this message translates to:
  /// **'Reminder Time'**
  String get reminderTime;

  /// No description provided for @refillThreshold.
  ///
  /// In en, this message translates to:
  /// **'Refill when inventory is less than'**
  String get refillThreshold;

  /// No description provided for @medicationDetails.
  ///
  /// In en, this message translates to:
  /// **'Medication Details'**
  String get medicationDetails;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @intakeAdvice.
  ///
  /// In en, this message translates to:
  /// **'Intake Advice'**
  String get intakeAdvice;

  /// No description provided for @deleteMedication.
  ///
  /// In en, this message translates to:
  /// **'Delete Medication'**
  String get deleteMedication;

  /// No description provided for @updatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Updated successfully!'**
  String get updatedSuccess;

  /// No description provided for @updatedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update.'**
  String get updatedFailed;

  /// No description provided for @reminderUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Reminder time updated successfully!'**
  String get reminderUpdatedSuccess;

  /// No description provided for @reminderUpdatedFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update reminder time.'**
  String get reminderUpdatedFailed;

  /// No description provided for @confirmDeleteMedication.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this medication?'**
  String get confirmDeleteMedication;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @beforeMeal.
  ///
  /// In en, this message translates to:
  /// **'Before meal'**
  String get beforeMeal;

  /// No description provided for @withMeal.
  ///
  /// In en, this message translates to:
  /// **'With meal'**
  String get withMeal;

  /// No description provided for @afterMeal.
  ///
  /// In en, this message translates to:
  /// **'After meal'**
  String get afterMeal;

  /// No description provided for @customEntry.
  ///
  /// In en, this message translates to:
  /// **'Custom entry'**
  String get customEntry;

  /// No description provided for @doctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctors;

  /// No description provided for @noDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No doctors found.'**
  String get noDoctorsFound;

  /// No description provided for @specialty.
  ///
  /// In en, this message translates to:
  /// **'Specialty'**
  String get specialty;

  /// No description provided for @editDoctor.
  ///
  /// In en, this message translates to:
  /// **'Edit Doctor'**
  String get editDoctor;

  /// No description provided for @doctorName.
  ///
  /// In en, this message translates to:
  /// **'Doctor Name'**
  String get doctorName;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @doctorUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Doctor updated successfully.'**
  String get doctorUpdatedSuccess;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// No description provided for @dateWithValue.
  ///
  /// In en, this message translates to:
  /// **'Date: {date}'**
  String dateWithValue(Object date);

  /// No description provided for @timeWithValue.
  ///
  /// In en, this message translates to:
  /// **'Time: {time}'**
  String timeWithValue(Object time);

  /// No description provided for @appointmentUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Appointment updated successfully.'**
  String get appointmentUpdatedSuccess;

  /// No description provided for @editAppointment.
  ///
  /// In en, this message translates to:
  /// **'Edit Appointment'**
  String get editAppointment;

  /// No description provided for @chooseOption.
  ///
  /// In en, this message translates to:
  /// **'Choose an Option'**
  String get chooseOption;

  /// No description provided for @newAppointment.
  ///
  /// In en, this message translates to:
  /// **'New Appointment'**
  String get newAppointment;

  /// No description provided for @newDoctor.
  ///
  /// In en, this message translates to:
  /// **'New Doctor'**
  String get newDoctor;

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select a time'**
  String get selectTime;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get selectDate;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @selectMedicationForReminder.
  ///
  /// In en, this message translates to:
  /// **'Which medication would you like to set the reminder for?'**
  String get selectMedicationForReminder;

  /// No description provided for @selectUnit.
  ///
  /// In en, this message translates to:
  /// **'Select Unit'**
  String get selectUnit;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @medicationFrequencyQuestion.
  ///
  /// In en, this message translates to:
  /// **'How often do you take this medication?'**
  String get medicationFrequencyQuestion;

  /// No description provided for @onceADay.
  ///
  /// In en, this message translates to:
  /// **'Once a day'**
  String get onceADay;

  /// No description provided for @twiceADay.
  ///
  /// In en, this message translates to:
  /// **'Twice a day'**
  String get twiceADay;

  /// No description provided for @threeTimesADay.
  ///
  /// In en, this message translates to:
  /// **'3 times a day'**
  String get threeTimesADay;

  /// No description provided for @onceAWeek.
  ///
  /// In en, this message translates to:
  /// **'Once a week'**
  String get onceAWeek;

  /// No description provided for @specificDays.
  ///
  /// In en, this message translates to:
  /// **'Specific days of the week'**
  String get specificDays;

  /// No description provided for @asNeeded.
  ///
  /// In en, this message translates to:
  /// **'Only as needed'**
  String get asNeeded;

  /// No description provided for @selectFrequency.
  ///
  /// In en, this message translates to:
  /// **'Select Frequency'**
  String get selectFrequency;

  /// No description provided for @dateAndTime.
  ///
  /// In en, this message translates to:
  /// **'Date & Time'**
  String get dateAndTime;

  /// No description provided for @refillReminder.
  ///
  /// In en, this message translates to:
  /// **'Refill Reminder'**
  String get refillReminder;

  /// No description provided for @refillReminderQuestion.
  ///
  /// In en, this message translates to:
  /// **'Do you want to get reminders to refill your medications?'**
  String get refillReminderQuestion;

  /// No description provided for @remindMe.
  ///
  /// In en, this message translates to:
  /// **'Remind me'**
  String get remindMe;

  /// No description provided for @remindWhenRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remind me when remaining'**
  String get remindWhenRemaining;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// No description provided for @logIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get logIn;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @forgetPassword.
  ///
  /// In en, this message translates to:
  /// **'Forget Password'**
  String get forgetPassword;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign Up'**
  String get noAccount;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log In'**
  String get haveAccount;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create an Account'**
  String get createAccount;

  /// No description provided for @welcomeBack.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// No description provided for @verifyYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// No description provided for @verificationEmailSentTo.
  ///
  /// In en, this message translates to:
  /// **'A verification email was sent to'**
  String get verificationEmailSentTo;

  /// No description provided for @resendEmail.
  ///
  /// In en, this message translates to:
  /// **'Resend Email'**
  String get resendEmail;

  /// No description provided for @waitingForVerification.
  ///
  /// In en, this message translates to:
  /// **'Waiting for verification...'**
  String get waitingForVerification;

  /// No description provided for @profileSetup.
  ///
  /// In en, this message translates to:
  /// **'Profile Setup'**
  String get profileSetup;

  /// No description provided for @addProfilePhoto.
  ///
  /// In en, this message translates to:
  /// **'Add Profile Photo'**
  String get addProfilePhoto;

  /// No description provided for @saveProfile.
  ///
  /// In en, this message translates to:
  /// **'Save Profile'**
  String get saveProfile;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
