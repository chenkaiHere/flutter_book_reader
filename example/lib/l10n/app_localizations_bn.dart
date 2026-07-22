// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get listeningNow => 'শোনা হচ্ছে';

  @override
  String get bookshelfTitle => 'বইয়ের তাক';

  @override
  String shelfSummary(int total, int reading) {
    return '$totalটি বই · $readingটি পড়ছেন';
  }

  @override
  String get searchHint => 'শিরোনাম / লেখক খুঁজুন';

  @override
  String get allBooks => 'সব বই';

  @override
  String get localTag => 'লোকাল';

  @override
  String get continueReading => 'পড়া চালিয়ে যান';

  @override
  String readToChapter(int n) {
    return 'অধ্যায় $n পর্যন্ত পড়া হয়েছে';
  }

  @override
  String get notStarted => 'শুরু হয়নি';

  @override
  String readPercent(int pct) {
    return '$pct% পড়া হয়েছে';
  }

  @override
  String get unread => 'অপঠিত';

  @override
  String get importTooltip => 'TXT ইমপোর্ট';

  @override
  String get importTitle => 'লোকাল উপন্যাস ইমপোর্ট করুন';

  @override
  String get importDesc =>
      'আপনার ফোনের TXT বই তাকে যোগ করুন এবং যেকোনো সময় অফলাইনে পড়ুন।';

  @override
  String get importPoint1Title => 'এক ট্যাপে';

  @override
  String get importPoint1Body =>
      'শুধু একটি লোকাল TXT ফাইল বাছুন, ইন্টারনেট লাগবে না';

  @override
  String get importPoint2Title => 'স্মার্ট লেআউট';

  @override
  String get importPoint2Body =>
      'শিরোনাম, লেখক ও অধ্যায় স্বয়ংক্রিয়ভাবে শনাক্ত করে';

  @override
  String get importPoint3Title => 'এনকোডিং নিয়ে চিন্তা নেই';

  @override
  String get importPoint3Body =>
      'UTF-8 / GBK / Big5 স্বয়ংক্রিয়ভাবে শনাক্ত করে';

  @override
  String get importPoint4Title => 'সংরক্ষণ ও মুছুন';

  @override
  String get importPoint4Body =>
      'ডিভাইসে সংরক্ষিত; মুছতে বাঁ দিকে সোয়াইপ করুন';

  @override
  String get importLater => 'এখন নয়';

  @override
  String get importPick => 'TXT ফাইল বাছুন';

  @override
  String importedToast(String title, int count) {
    return '«$title» ইমপোর্ট হয়েছে · $countটি অধ্যায়';
  }

  @override
  String importFailed(String error) {
    return 'ইমপোর্ট ব্যর্থ: $error';
  }

  @override
  String get deleteTitle => 'বই মুছুন';

  @override
  String deleteMessage(String title) {
    return '«$title» মুছবেন? এতে ইমপোর্ট করা বইয়ের ডেটা মুছে যাবে।';
  }

  @override
  String get cancel => 'বাতিল';

  @override
  String get delete => 'মুছুন';

  @override
  String get cannotDeleteBuiltin => 'বিল্ট-ইন বই মোছা যায় না';

  @override
  String deletedToast(String title) {
    return '«$title» মুছে ফেলা হয়েছে';
  }

  @override
  String get tabDetail => 'বিবরণ';

  @override
  String get tabToc => 'সূচিপত্র';

  @override
  String get tabBookmarks => 'বুকমার্ক';

  @override
  String get statChapters => 'অধ্যায়';

  @override
  String get statSource => 'উৎস';

  @override
  String get statProgress => 'অগ্রগতি';

  @override
  String get sourceLocal => 'লোকাল';

  @override
  String get sourceBuiltin => 'বিল্ট-ইন';

  @override
  String get statusLocalImported => 'লোকাল ইমপোর্ট';

  @override
  String get statusBuiltin => 'বিল্ট-ইন বই';

  @override
  String get introHeading => 'সারসংক্ষেপ';

  @override
  String get noIntro => 'কোনো সারসংক্ষেপ নেই।';

  @override
  String chapterCountLabel(int n) {
    return '$nটি অধ্যায়';
  }

  @override
  String get orderAsc => 'ঊর্ধ্বক্রম';

  @override
  String get orderDesc => 'অধোক্রম';

  @override
  String get startReading => 'পড়া শুরু করুন';

  @override
  String get noBookmarks => 'এখনও কোনো বুকমার্ক নেই';

  @override
  String get noBookmarksHint =>
      'পড়ার সময় বুকমার্ক যোগ করতে উপরের ডানদিকে ট্যাপ করুন,\nযাতে যেকোনো সময় ফিরে আসতে পারেন।';

  @override
  String bookmarkEntry(int n, String title) {
    return 'অধ্যায় $n · $title';
  }

  @override
  String get emptyShelf =>
      'কোনো বই নেই — TXT ইমপোর্ট করতে উপরের ডানদিকে ট্যাপ করুন';

  @override
  String get noMatches => 'মিলে যাওয়া কোনো বই নেই';

  @override
  String loadFailed(String error) {
    return 'বই লোড করা যায়নি: $error';
  }

  @override
  String get languageSheetTitle => 'ভাষা';
}
