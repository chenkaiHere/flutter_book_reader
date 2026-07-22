// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get listeningNow => 'सुन रहे हैं';

  @override
  String get bookshelfTitle => 'बुकशेल्फ़';

  @override
  String shelfSummary(int total, int reading) {
    return '$total किताबें · $reading पढ़ रहे हैं';
  }

  @override
  String get searchHint => 'शीर्षक / लेखक खोजें';

  @override
  String get allBooks => 'सभी किताबें';

  @override
  String get localTag => 'लोकल';

  @override
  String get continueReading => 'पढ़ना जारी रखें';

  @override
  String readToChapter(int n) {
    return 'अध्याय $n तक पढ़ा';
  }

  @override
  String get notStarted => 'शुरू नहीं हुआ';

  @override
  String readPercent(int pct) {
    return '$pct% पढ़ा';
  }

  @override
  String get unread => 'अपठित';

  @override
  String get importTooltip => 'TXT आयात करें';

  @override
  String get importTitle => 'लोकल उपन्यास आयात करें';

  @override
  String get importDesc =>
      'अपने फ़ोन की TXT किताबें बुकशेल्फ़ में जोड़ें और कभी भी ऑफ़लाइन पढ़ें।';

  @override
  String get importPoint1Title => 'एक टैप';

  @override
  String get importPoint1Body =>
      'बस एक लोकल TXT फ़ाइल चुनें, इंटरनेट की ज़रूरत नहीं';

  @override
  String get importPoint2Title => 'स्मार्ट लेआउट';

  @override
  String get importPoint2Body => 'शीर्षक, लेखक और अध्याय अपने आप पहचानता है';

  @override
  String get importPoint3Title => 'एन्कोडिंग की चिंता नहीं';

  @override
  String get importPoint3Body => 'UTF-8 / GBK / Big5 अपने आप पहचानता है';

  @override
  String get importPoint4Title => 'सहेजें और हटाएँ';

  @override
  String get importPoint4Body =>
      'डिवाइस पर सहेजा जाता है; हटाने के लिए बाएँ स्वाइप करें';

  @override
  String get importLater => 'अभी नहीं';

  @override
  String get importPick => 'TXT फ़ाइल चुनें';

  @override
  String importedToast(String title, int count) {
    return '«$title» आयात किया · $count अध्याय';
  }

  @override
  String importFailed(String error) {
    return 'आयात विफल: $error';
  }

  @override
  String get deleteTitle => 'किताब हटाएँ';

  @override
  String deleteMessage(String title) {
    return '«$title» हटाएँ? इससे आयातित किताब का डेटा हट जाएगा।';
  }

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएँ';

  @override
  String get cannotDeleteBuiltin => 'बिल्ट-इन किताबें हटाई नहीं जा सकतीं';

  @override
  String deletedToast(String title) {
    return '«$title» हटा दिया गया';
  }

  @override
  String get tabDetail => 'विवरण';

  @override
  String get tabToc => 'अनुक्रम';

  @override
  String get tabBookmarks => 'बुकमार्क';

  @override
  String get statChapters => 'अध्याय';

  @override
  String get statSource => 'स्रोत';

  @override
  String get statProgress => 'प्रगति';

  @override
  String get sourceLocal => 'लोकल';

  @override
  String get sourceBuiltin => 'बिल्ट-इन';

  @override
  String get statusLocalImported => 'लोकल आयात';

  @override
  String get statusBuiltin => 'बिल्ट-इन किताब';

  @override
  String get introHeading => 'सारांश';

  @override
  String get noIntro => 'कोई सारांश नहीं।';

  @override
  String chapterCountLabel(int n) {
    return '$n अध्याय';
  }

  @override
  String get orderAsc => 'आरोही';

  @override
  String get orderDesc => 'अवरोही';

  @override
  String get startReading => 'पढ़ना शुरू करें';

  @override
  String get noBookmarks => 'अभी कोई बुकमार्क नहीं';

  @override
  String get noBookmarksHint =>
      'पढ़ते समय बुकमार्क जोड़ने के लिए ऊपर दाईं ओर टैप करें,\nताकि कभी भी वापस आ सकें।';

  @override
  String bookmarkEntry(int n, String title) {
    return 'अध्याय $n · $title';
  }

  @override
  String get emptyShelf =>
      'कोई किताब नहीं — TXT आयात करने के लिए ऊपर दाईं ओर टैप करें';

  @override
  String get noMatches => 'कोई मेल खाती किताब नहीं';

  @override
  String loadFailed(String error) {
    return 'किताबें लोड करने में विफल: $error';
  }

  @override
  String get languageSheetTitle => 'भाषा';
}
