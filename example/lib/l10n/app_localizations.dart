import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_ur.dart';
import 'app_localizations_zh.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('ar'),
    Locale('bn'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('ja'),
    Locale('ko'),
    Locale('pt'),
    Locale('ru'),
    Locale('ur'),
    Locale('zh'),
  ];

  /// No description provided for @listeningNow.
  ///
  /// In en, this message translates to:
  /// **'Listening'**
  String get listeningNow;

  /// No description provided for @bookshelfTitle.
  ///
  /// In en, this message translates to:
  /// **'Bookshelf'**
  String get bookshelfTitle;

  /// No description provided for @shelfSummary.
  ///
  /// In en, this message translates to:
  /// **'{total} books · {reading} reading'**
  String shelfSummary(int total, int reading);

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search title / author'**
  String get searchHint;

  /// No description provided for @allBooks.
  ///
  /// In en, this message translates to:
  /// **'All books'**
  String get allBooks;

  /// No description provided for @localTag.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get localTag;

  /// No description provided for @continueReading.
  ///
  /// In en, this message translates to:
  /// **'Continue reading'**
  String get continueReading;

  /// No description provided for @readToChapter.
  ///
  /// In en, this message translates to:
  /// **'Read to Chapter {n}'**
  String readToChapter(int n);

  /// No description provided for @notStarted.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get notStarted;

  /// No description provided for @readPercent.
  ///
  /// In en, this message translates to:
  /// **'{pct}% read'**
  String readPercent(int pct);

  /// No description provided for @unread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get unread;

  /// No description provided for @importTooltip.
  ///
  /// In en, this message translates to:
  /// **'Import TXT'**
  String get importTooltip;

  /// No description provided for @importTitle.
  ///
  /// In en, this message translates to:
  /// **'Import a local novel'**
  String get importTitle;

  /// No description provided for @importDesc.
  ///
  /// In en, this message translates to:
  /// **'Add TXT novels from your phone to the bookshelf and read offline anytime.'**
  String get importDesc;

  /// No description provided for @importPoint1Title.
  ///
  /// In en, this message translates to:
  /// **'One tap'**
  String get importPoint1Title;

  /// No description provided for @importPoint1Body.
  ///
  /// In en, this message translates to:
  /// **'Just pick a local TXT file — no network needed'**
  String get importPoint1Body;

  /// No description provided for @importPoint2Title.
  ///
  /// In en, this message translates to:
  /// **'Smart layout'**
  String get importPoint2Title;

  /// No description provided for @importPoint2Body.
  ///
  /// In en, this message translates to:
  /// **'Auto-detects title, author and chapters'**
  String get importPoint2Body;

  /// No description provided for @importPoint3Title.
  ///
  /// In en, this message translates to:
  /// **'Encoding-safe'**
  String get importPoint3Title;

  /// No description provided for @importPoint3Body.
  ///
  /// In en, this message translates to:
  /// **'Auto-detects UTF-8 / GBK / Big5 — no garbled text'**
  String get importPoint3Body;

  /// No description provided for @importPoint4Title.
  ///
  /// In en, this message translates to:
  /// **'Save & delete'**
  String get importPoint4Title;

  /// No description provided for @importPoint4Body.
  ///
  /// In en, this message translates to:
  /// **'Stored on device; swipe left to delete'**
  String get importPoint4Body;

  /// No description provided for @importLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get importLater;

  /// No description provided for @importPick.
  ///
  /// In en, this message translates to:
  /// **'Choose TXT file'**
  String get importPick;

  /// No description provided for @importedToast.
  ///
  /// In en, this message translates to:
  /// **'Imported \"{title}\" · {count} chapters'**
  String importedToast(String title, int count);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete book'**
  String get deleteTitle;

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{title}\"? This removes the imported book data.'**
  String deleteMessage(String title);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cannotDeleteBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Built-in books can\'t be deleted'**
  String get cannotDeleteBuiltin;

  /// No description provided for @deletedToast.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String deletedToast(String title);

  /// No description provided for @tabDetail.
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get tabDetail;

  /// No description provided for @tabToc.
  ///
  /// In en, this message translates to:
  /// **'Contents'**
  String get tabToc;

  /// No description provided for @tabBookmarks.
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get tabBookmarks;

  /// No description provided for @statChapters.
  ///
  /// In en, this message translates to:
  /// **'Chapters'**
  String get statChapters;

  /// No description provided for @statSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get statSource;

  /// No description provided for @statProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get statProgress;

  /// No description provided for @sourceLocal.
  ///
  /// In en, this message translates to:
  /// **'Local'**
  String get sourceLocal;

  /// No description provided for @sourceBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Built-in'**
  String get sourceBuiltin;

  /// No description provided for @statusLocalImported.
  ///
  /// In en, this message translates to:
  /// **'Local import'**
  String get statusLocalImported;

  /// No description provided for @statusBuiltin.
  ///
  /// In en, this message translates to:
  /// **'Built-in book'**
  String get statusBuiltin;

  /// No description provided for @introHeading.
  ///
  /// In en, this message translates to:
  /// **'Synopsis'**
  String get introHeading;

  /// No description provided for @noIntro.
  ///
  /// In en, this message translates to:
  /// **'No synopsis.'**
  String get noIntro;

  /// No description provided for @chapterCountLabel.
  ///
  /// In en, this message translates to:
  /// **'{n} chapters'**
  String chapterCountLabel(int n);

  /// No description provided for @orderAsc.
  ///
  /// In en, this message translates to:
  /// **'Ascending'**
  String get orderAsc;

  /// No description provided for @orderDesc.
  ///
  /// In en, this message translates to:
  /// **'Descending'**
  String get orderDesc;

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// No description provided for @noBookmarks.
  ///
  /// In en, this message translates to:
  /// **'No bookmarks yet'**
  String get noBookmarks;

  /// No description provided for @noBookmarksHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the top-right while reading to add a bookmark,\nso you can jump back anytime.'**
  String get noBookmarksHint;

  /// No description provided for @bookmarkEntry.
  ///
  /// In en, this message translates to:
  /// **'Chapter {n} · {title}'**
  String bookmarkEntry(int n, String title);

  /// No description provided for @emptyShelf.
  ///
  /// In en, this message translates to:
  /// **'No books yet — tap the top-right to import a TXT'**
  String get emptyShelf;

  /// No description provided for @noMatches.
  ///
  /// In en, this message translates to:
  /// **'No matching books'**
  String get noMatches;

  /// No description provided for @loadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to load books: {error}'**
  String loadFailed(String error);

  /// No description provided for @languageSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSheetTitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'bn',
    'en',
    'es',
    'fr',
    'hi',
    'ja',
    'ko',
    'pt',
    'ru',
    'ur',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
    case 'pt':
      return AppLocalizationsPt();
    case 'ru':
      return AppLocalizationsRu();
    case 'ur':
      return AppLocalizationsUr();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
