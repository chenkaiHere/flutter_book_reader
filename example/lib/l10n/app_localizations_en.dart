// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get listeningNow => 'Listening';

  @override
  String get bookshelfTitle => 'Bookshelf';

  @override
  String shelfSummary(int total, int reading) {
    return '$total books · $reading reading';
  }

  @override
  String get searchHint => 'Search title / author';

  @override
  String get allBooks => 'All books';

  @override
  String get localTag => 'Local';

  @override
  String get continueReading => 'Continue reading';

  @override
  String readToChapter(int n) {
    return 'Read to Chapter $n';
  }

  @override
  String get notStarted => 'Not started';

  @override
  String readPercent(int pct) {
    return '$pct% read';
  }

  @override
  String get unread => 'Unread';

  @override
  String get importTooltip => 'Import TXT';

  @override
  String get importTitle => 'Import a local novel';

  @override
  String get importDesc =>
      'Add TXT novels from your phone to the bookshelf and read offline anytime.';

  @override
  String get importPoint1Title => 'One tap';

  @override
  String get importPoint1Body =>
      'Just pick a local TXT file — no network needed';

  @override
  String get importPoint2Title => 'Smart layout';

  @override
  String get importPoint2Body => 'Auto-detects title, author and chapters';

  @override
  String get importPoint3Title => 'Encoding-safe';

  @override
  String get importPoint3Body =>
      'Auto-detects UTF-8 / GBK / Big5 — no garbled text';

  @override
  String get importPoint4Title => 'Save & delete';

  @override
  String get importPoint4Body => 'Stored on device; swipe left to delete';

  @override
  String get importLater => 'Not now';

  @override
  String get importPick => 'Choose TXT file';

  @override
  String importedToast(String title, int count) {
    return 'Imported \"$title\" · $count chapters';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String get deleteTitle => 'Delete book';

  @override
  String deleteMessage(String title) {
    return 'Delete \"$title\"? This removes the imported book data.';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get cannotDeleteBuiltin => 'Built-in books can\'t be deleted';

  @override
  String deletedToast(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String get tabDetail => 'Detail';

  @override
  String get tabToc => 'Contents';

  @override
  String get tabBookmarks => 'Bookmarks';

  @override
  String get statChapters => 'Chapters';

  @override
  String get statSource => 'Source';

  @override
  String get statProgress => 'Progress';

  @override
  String get sourceLocal => 'Local';

  @override
  String get sourceBuiltin => 'Built-in';

  @override
  String get statusLocalImported => 'Local import';

  @override
  String get statusBuiltin => 'Built-in book';

  @override
  String get introHeading => 'Synopsis';

  @override
  String get noIntro => 'No synopsis.';

  @override
  String chapterCountLabel(int n) {
    return '$n chapters';
  }

  @override
  String get orderAsc => 'Ascending';

  @override
  String get orderDesc => 'Descending';

  @override
  String get startReading => 'Start reading';

  @override
  String get noBookmarks => 'No bookmarks yet';

  @override
  String get noBookmarksHint =>
      'Tap the top-right while reading to add a bookmark,\nso you can jump back anytime.';

  @override
  String bookmarkEntry(int n, String title) {
    return 'Chapter $n · $title';
  }

  @override
  String get emptyShelf => 'No books yet — tap the top-right to import a TXT';

  @override
  String get noMatches => 'No matching books';

  @override
  String loadFailed(String error) {
    return 'Failed to load books: $error';
  }

  @override
  String get languageSheetTitle => 'Language';
}
