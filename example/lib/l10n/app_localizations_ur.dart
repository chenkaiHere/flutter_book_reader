// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Urdu (`ur`).
class AppLocalizationsUr extends AppLocalizations {
  AppLocalizationsUr([String locale = 'ur']) : super(locale);

  @override
  String get listeningNow => 'سن رہے ہیں';

  @override
  String get bookshelfTitle => 'کتابوں کی الماری';

  @override
  String shelfSummary(int total, int reading) {
    return '$total کتابیں · $reading زیرِ مطالعہ';
  }

  @override
  String get searchHint => 'عنوان / مصنف تلاش کریں';

  @override
  String get allBooks => 'تمام کتابیں';

  @override
  String get localTag => 'مقامی';

  @override
  String get continueReading => 'پڑھنا جاری رکھیں';

  @override
  String readToChapter(int n) {
    return 'باب $n تک پڑھا';
  }

  @override
  String get notStarted => 'شروع نہیں ہوا';

  @override
  String readPercent(int pct) {
    return '$pct% پڑھا';
  }

  @override
  String get unread => 'غیر مطالعہ شدہ';

  @override
  String get importTooltip => 'TXT درآمد کریں';

  @override
  String get importTitle => 'مقامی ناول درآمد کریں';

  @override
  String get importDesc =>
      'اپنے فون کی TXT کتابیں الماری میں شامل کریں اور کسی بھی وقت آف لائن پڑھیں۔';

  @override
  String get importPoint1Title => 'ایک ٹیپ';

  @override
  String get importPoint1Body =>
      'بس ایک مقامی TXT فائل منتخب کریں، انٹرنیٹ کی ضرورت نہیں';

  @override
  String get importPoint2Title => 'ذہین ترتیب';

  @override
  String get importPoint2Body => 'عنوان، مصنف اور ابواب خودکار پہچانتا ہے';

  @override
  String get importPoint3Title => 'انکوڈنگ کی فکر نہیں';

  @override
  String get importPoint3Body => 'UTF-8 / GBK / Big5 خودکار پہچانتا ہے';

  @override
  String get importPoint4Title => 'محفوظ اور حذف کریں';

  @override
  String get importPoint4Body =>
      'آلے پر محفوظ؛ حذف کرنے کے لیے بائیں سوائپ کریں';

  @override
  String get importLater => 'ابھی نہیں';

  @override
  String get importPick => 'TXT فائل منتخب کریں';

  @override
  String importedToast(String title, int count) {
    return '«$title» درآمد ہو گئی · $count ابواب';
  }

  @override
  String importFailed(String error) {
    return 'درآمد ناکام: $error';
  }

  @override
  String get deleteTitle => 'کتاب حذف کریں';

  @override
  String deleteMessage(String title) {
    return '«$title» حذف کریں؟ اس سے درآمد شدہ کتاب کا ڈیٹا ہٹ جائے گا۔';
  }

  @override
  String get cancel => 'منسوخ';

  @override
  String get delete => 'حذف';

  @override
  String get cannotDeleteBuiltin => 'بلٹ اِن کتابیں حذف نہیں ہو سکتیں';

  @override
  String deletedToast(String title) {
    return '«$title» حذف ہو گئی';
  }

  @override
  String get tabDetail => 'تفصیل';

  @override
  String get tabToc => 'فہرست';

  @override
  String get tabBookmarks => 'بُک مارکس';

  @override
  String get statChapters => 'ابواب';

  @override
  String get statSource => 'ماخذ';

  @override
  String get statProgress => 'پیش رفت';

  @override
  String get sourceLocal => 'مقامی';

  @override
  String get sourceBuiltin => 'بلٹ اِن';

  @override
  String get statusLocalImported => 'مقامی درآمد';

  @override
  String get statusBuiltin => 'بلٹ اِن کتاب';

  @override
  String get introHeading => 'خلاصہ';

  @override
  String get noIntro => 'کوئی خلاصہ نہیں۔';

  @override
  String chapterCountLabel(int n) {
    return '$n ابواب';
  }

  @override
  String get orderAsc => 'صعودی';

  @override
  String get orderDesc => 'نزولی';

  @override
  String get startReading => 'پڑھنا شروع کریں';

  @override
  String get noBookmarks => 'ابھی کوئی بُک مارک نہیں';

  @override
  String get noBookmarksHint =>
      'پڑھتے وقت بُک مارک شامل کرنے کے لیے اوپر دائیں طرف ٹیپ کریں،\nتاکہ کسی بھی وقت واپس آ سکیں۔';

  @override
  String bookmarkEntry(int n, String title) {
    return 'باب $n · $title';
  }

  @override
  String get emptyShelf =>
      'کوئی کتاب نہیں — TXT درآمد کرنے کے لیے اوپر دائیں طرف ٹیپ کریں';

  @override
  String get noMatches => 'کوئی مماثل کتاب نہیں';

  @override
  String loadFailed(String error) {
    return 'کتابیں لوڈ نہیں ہو سکیں: $error';
  }

  @override
  String get languageSheetTitle => 'زبان';
}
