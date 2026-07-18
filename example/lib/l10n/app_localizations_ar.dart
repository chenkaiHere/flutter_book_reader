// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get bookshelfTitle => 'رف الكتب';

  @override
  String shelfSummary(int total, int reading) {
    return '$total كتب · $reading قيد القراءة';
  }

  @override
  String get searchHint => 'ابحث بالعنوان / المؤلف';

  @override
  String get allBooks => 'كل الكتب';

  @override
  String get localTag => 'محلي';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String readToChapter(int n) {
    return 'قرأت حتى الفصل $n';
  }

  @override
  String get notStarted => 'لم يبدأ';

  @override
  String readPercent(int pct) {
    return 'قُرئ $pct%';
  }

  @override
  String get unread => 'غير مقروء';

  @override
  String get importTooltip => 'استيراد TXT';

  @override
  String get importTitle => 'استيراد رواية محلية';

  @override
  String get importDesc =>
      'أضف روايات TXT من هاتفك إلى الرف واقرأها دون اتصال في أي وقت.';

  @override
  String get importPoint1Title => 'بنقرة واحدة';

  @override
  String get importPoint1Body => 'اختر ملف TXT محليًا فقط، دون إنترنت';

  @override
  String get importPoint2Title => 'تنسيق ذكي';

  @override
  String get importPoint2Body => 'يكتشف العنوان والمؤلف والفصول تلقائيًا';

  @override
  String get importPoint3Title => 'بدون مشاكل ترميز';

  @override
  String get importPoint3Body => 'يكتشف UTF-8 / GBK / Big5 تلقائيًا';

  @override
  String get importPoint4Title => 'حفظ وحذف';

  @override
  String get importPoint4Body => 'يُحفظ على الجهاز؛ اسحب لليسار للحذف';

  @override
  String get importLater => 'ليس الآن';

  @override
  String get importPick => 'اختر ملف TXT';

  @override
  String importedToast(String title, int count) {
    return 'تم استيراد «$title» · $count فصلًا';
  }

  @override
  String importFailed(String error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String get deleteTitle => 'حذف الكتاب';

  @override
  String deleteMessage(String title) {
    return 'حذف «$title»؟ سيؤدي هذا إلى إزالة بيانات الكتاب المستورد.';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get cannotDeleteBuiltin => 'لا يمكن حذف الكتب المدمجة';

  @override
  String deletedToast(String title) {
    return 'تم حذف «$title»';
  }

  @override
  String get tabDetail => 'التفاصيل';

  @override
  String get tabToc => 'الفهرس';

  @override
  String get tabBookmarks => 'الإشارات';

  @override
  String get statChapters => 'الفصول';

  @override
  String get statSource => 'المصدر';

  @override
  String get statProgress => 'التقدم';

  @override
  String get sourceLocal => 'محلي';

  @override
  String get sourceBuiltin => 'مدمج';

  @override
  String get statusLocalImported => 'استيراد محلي';

  @override
  String get statusBuiltin => 'كتاب مدمج';

  @override
  String get introHeading => 'الملخص';

  @override
  String get noIntro => 'لا يوجد ملخص.';

  @override
  String chapterCountLabel(int n) {
    return '$n فصلًا';
  }

  @override
  String get orderAsc => 'تصاعدي';

  @override
  String get orderDesc => 'تنازلي';

  @override
  String get startReading => 'ابدأ القراءة';

  @override
  String get noBookmarks => 'لا توجد إشارات بعد';

  @override
  String get noBookmarksHint =>
      'أثناء القراءة اضغط أعلى اليمين لإضافة إشارة،\nلتعود إليها في أي وقت.';

  @override
  String bookmarkEntry(int n, String title) {
    return 'الفصل $n · $title';
  }

  @override
  String get emptyShelf => 'لا كتب — اضغط أعلى اليمين لاستيراد ملف TXT';

  @override
  String get noMatches => 'لا كتب مطابقة';

  @override
  String loadFailed(String error) {
    return 'فشل تحميل الكتب: $error';
  }

  @override
  String get languageSheetTitle => 'اللغة';
}
