// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get title => 'تطبيقي';

  @override
  String get welcome => 'أهلاً بيك في التطبيق!';

  @override
  String get language => 'اللغة';

  @override
  String get changeLanguage => 'اضغط لتغيير اللغة';

  @override
  String get settings => 'الإعدادات';

  @override
  String get editProfile => 'تعديل الملف الشخصي';

  @override
  String get editProfileSub => ' تغيير الاسم, الايميل, و الصورة';

  @override
  String get notifications => 'الإشعارات';

  @override
  String get notificationsSub => 'تنظيم التنبيهات و التذكيرات';

  @override
  String get darkMode => 'الوضع الداكن';

  @override
  String get security => 'الأمان';

  @override
  String get securitySub => 'تغيير كلمة السر';

  @override
  String get emergencyContacts => 'جهات الطوارئ';

  @override
  String get emergencyContactsSub => 'تنظيم ارقام الطوارئ';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get help => 'المساعدة';

  @override
  String get helpSub => 'شاهد مقاطع تعريفيه';

  @override
  String get profileImageUpdatedSuccess => 'تم تحديث الصورة الشخصية بنجاح!';

  @override
  String get profileImageUpdatedFailed => 'فشل تحديث الصورة الشخصية ';

  @override
  String get profileupdated => 'تم تحديث الملف الشخصى بنجاح!';

  @override
  String get eeditProfile => 'تعديل الملف الشخصى';

  @override
  String get imageChange => 'اضغط على الصوة للتغيير';

  @override
  String get firstName => 'الاسم الاول';

  @override
  String get lastName => 'الاسم الاخير';

  @override
  String get phone => 'رقم الهاتف';

  @override
  String get age => 'العمر';

  @override
  String get illnesses => 'الأمراض';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get addContact => 'اضافة جهة جديده';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmNewPassword => 'تأكيد كلمة المرور الجديدة';

  @override
  String get addAppointment => 'إضافة موعد';

  @override
  String get addDoctor => 'إضافة طبيب';

  @override
  String get addMedicine => 'إضافة دواء';

  @override
  String get findPharmacy => 'البحث عن صيدلية قريبة';

  @override
  String get addEmergencyContact => 'اضافة جهة طوارئ';

  @override
  String get confirmDeletion => 'تأكيد حذف الحساب';

  @override
  String get enterPasswordToDelete => 'من فضلك أدخل كلمة المرور لحذف حسابك.';

  @override
  String get password => 'كلمة المرور';

  @override
  String get delete => 'حذف';

  @override
  String get cancel => 'اغلاق';

  @override
  String get accountDeleted => 'تم حذف الحساب بنجاح';

  @override
  String get incorrectPassword => 'كلمة المرور غير صحيحة';

  @override
  String get medications => 'الأدويه';

  @override
  String get appointments => 'المواعيد';

  @override
  String appointmentTomorrow(Object doctor, Object time) {
    return 'لديك موعد غدًا مع الدكتور $doctor في تمام الساعة $time';
  }

  @override
  String get noAppointments => 'لا توجد مواعيد في هذا اليوم';

  @override
  String get profile => 'الملف الشخصى';

  @override
  String ageAndIllnesses(Object age, Object illnesses) {
    return 'العمر: $age | $illnesses';
  }

  @override
  String linkedAsEmergencyContact(Object name) {
    return 'أنت جهة اتصال طارئة لـ$name.';
  }

  @override
  String get home => 'الرئيسية';

  @override
  String get refills => 'إعادة التعبئة';

  @override
  String get manage => 'إدارة';

  @override
  String currentInventory(Object amount, Object unit) {
    return 'المخزون الحالي: $amount $unit';
  }

  @override
  String reminderTimes(Object time) {
    return 'وقت التذكير: $time';
  }

  @override
  String get medication => 'الدواء';

  @override
  String get dosage => 'الجرعه';

  @override
  String get currentInventoryy => 'المخزون الحالي';

  @override
  String get reminderTime => 'وقت التذكير';

  @override
  String get refillThreshold => 'أعد التعبئة عندما يكون المخزون أقل من ';

  @override
  String get medicationDetails => 'تفاصيل الدواء';

  @override
  String get frequency => 'عدد مرات الاستخدام';

  @override
  String get intakeAdvice => 'نصيحة الاستخدام';

  @override
  String get deleteMedication => 'حذف الدواء';

  @override
  String get updatedSuccess => 'تم التحديث بنجاح!';

  @override
  String get updatedFailed => 'فشل في التحديث .';

  @override
  String get reminderUpdatedSuccess => 'تم تحديث وقت التذكير بنجاح!';

  @override
  String get reminderUpdatedFailed => 'فشل في تحديث وقت التذكير.';

  @override
  String get confirmDeleteMedication => 'هل أنت متأكد أنك تريد حذف هذا الدواء؟';

  @override
  String get none => 'بدون';

  @override
  String get beforeMeal => 'قبل الأكل';

  @override
  String get withMeal => 'مع الأكل';

  @override
  String get afterMeal => 'بعد الأكل';

  @override
  String get customEntry => 'إدخال مخصص';

  @override
  String get doctors => 'الأطباء';

  @override
  String get noDoctorsFound => 'لم يتم العثور على أطباء.';

  @override
  String get specialty => 'التخصص';

  @override
  String get editDoctor => 'تعديل بيانات الطبيب';

  @override
  String get doctorName => 'اسم الطبيب';

  @override
  String get location => 'العنوان';

  @override
  String get notes => 'ملاحظات';

  @override
  String get doctorUpdatedSuccess => 'تم تحديث بيانات الطبيب بنجاح.';

  @override
  String get date => 'التاريخ';

  @override
  String get time => 'الوقت';

  @override
  String dateWithValue(Object date) {
    return 'التاريخ: $date';
  }

  @override
  String timeWithValue(Object time) {
    return 'الوقت: $time';
  }

  @override
  String get appointmentUpdatedSuccess => 'تم تحديث الموعد بنجاح.';

  @override
  String get editAppointment => 'تعديل الموعد';

  @override
  String get chooseOption => 'اختر خيارًا';

  @override
  String get newAppointment => 'موعد جديد';

  @override
  String get newDoctor => 'طبيب جديد';

  @override
  String get selectTime => 'اختر وقتًا';

  @override
  String get selectDate => 'اختر تاريخًا';

  @override
  String get save => 'حفظ';

  @override
  String get selectMedicationForReminder => 'أي دواء تود ضبط التذكير له؟';

  @override
  String get selectUnit => 'اختر الوحدة';

  @override
  String get next => 'التالى';

  @override
  String get medicationFrequencyQuestion => 'كم مرة تتناول هذا الدواء؟';

  @override
  String get onceADay => 'مرة يوميًا';

  @override
  String get twiceADay => 'مرتين يوميًا';

  @override
  String get threeTimesADay => '3 مرات يوميًا';

  @override
  String get onceAWeek => 'مرة أسبوعيًا';

  @override
  String get specificDays => 'أيام محددة من الأسبوع';

  @override
  String get asNeeded => 'عند الحاجة فقط';

  @override
  String get selectFrequency => 'اختر التكرار';

  @override
  String get dateAndTime => 'التاريخ والوقت';

  @override
  String get refillReminder => 'تذكير بإعادة التعبئة';

  @override
  String get refillReminderQuestion =>
      'هل تريد الحصول على تذكيرات لإعادة تعبئة أدويتك؟';

  @override
  String get remindMe => 'ذكرني';

  @override
  String get remindWhenRemaining => 'ذكرني عندما يتبقى';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get logIn => 'تسجيل الدخول';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get forgetPassword => 'نسيت كلمة المرور؟';

  @override
  String get noAccount => 'ليس لديك حساب؟ أنشئ حساب';

  @override
  String get haveAccount => 'عندك حساب بالفعل؟ سجل الدخول';

  @override
  String get createAccount => 'إنشاء حساب جديد';

  @override
  String get welcomeBack => 'أهلاً بعودتك';

  @override
  String get verifyYourEmail => 'تحقق من بريدك الإلكتروني';

  @override
  String get verificationEmailSentTo => 'تم إرسال رسالة تحقق إلى';

  @override
  String get resendEmail => 'إعادة إرسال البريد الإلكتروني';

  @override
  String get waitingForVerification => 'في انتظار التحقق...';

  @override
  String get profileSetup => 'إعداد الملف الشخصي';

  @override
  String get addProfilePhoto => 'إضافة صورة شخصية';

  @override
  String get saveProfile => 'حفظ الملف الشخصي';
}
