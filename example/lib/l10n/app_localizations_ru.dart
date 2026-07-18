// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get bookshelfTitle => 'Книжная полка';

  @override
  String shelfSummary(int total, int reading) {
    return '$total книг · $reading читаю';
  }

  @override
  String get searchHint => 'Поиск по названию / автору';

  @override
  String get allBooks => 'Все книги';

  @override
  String get localTag => 'Локально';

  @override
  String get continueReading => 'Продолжить чтение';

  @override
  String readToChapter(int n) {
    return 'Прочитано до главы $n';
  }

  @override
  String get notStarted => 'Не начато';

  @override
  String readPercent(int pct) {
    return 'Прочитано $pct%';
  }

  @override
  String get unread => 'Не прочитано';

  @override
  String get importTooltip => 'Импорт TXT';

  @override
  String get importTitle => 'Импорт локального романа';

  @override
  String get importDesc =>
      'Добавляйте романы TXT с телефона на полку и читайте офлайн в любое время.';

  @override
  String get importPoint1Title => 'Одно касание';

  @override
  String get importPoint1Body =>
      'Просто выберите локальный файл TXT, без интернета';

  @override
  String get importPoint2Title => 'Умная вёрстка';

  @override
  String get importPoint2Body =>
      'Автоматически определяет название, автора и главы';

  @override
  String get importPoint3Title => 'Без проблем с кодировкой';

  @override
  String get importPoint3Body => 'Автоопределение UTF-8 / GBK / Big5';

  @override
  String get importPoint4Title => 'Хранение и удаление';

  @override
  String get importPoint4Body =>
      'Хранится на устройстве; смахните влево, чтобы удалить';

  @override
  String get importLater => 'Не сейчас';

  @override
  String get importPick => 'Выбрать файл TXT';

  @override
  String importedToast(String title, int count) {
    return 'Импортировано «$title» · глав: $count';
  }

  @override
  String importFailed(String error) {
    return 'Ошибка импорта: $error';
  }

  @override
  String get deleteTitle => 'Удалить книгу';

  @override
  String deleteMessage(String title) {
    return 'Удалить «$title»? Данные импортированной книги будут удалены.';
  }

  @override
  String get cancel => 'Отмена';

  @override
  String get delete => 'Удалить';

  @override
  String get cannotDeleteBuiltin => 'Встроенные книги нельзя удалить';

  @override
  String deletedToast(String title) {
    return '«$title» удалено';
  }

  @override
  String get tabDetail => 'Детали';

  @override
  String get tabToc => 'Оглавление';

  @override
  String get tabBookmarks => 'Закладки';

  @override
  String get statChapters => 'Главы';

  @override
  String get statSource => 'Источник';

  @override
  String get statProgress => 'Прогресс';

  @override
  String get sourceLocal => 'Локально';

  @override
  String get sourceBuiltin => 'Встроено';

  @override
  String get statusLocalImported => 'Локальный импорт';

  @override
  String get statusBuiltin => 'Встроенная книга';

  @override
  String get introHeading => 'Аннотация';

  @override
  String get noIntro => 'Нет аннотации.';

  @override
  String chapterCountLabel(int n) {
    return 'Глав: $n';
  }

  @override
  String get orderAsc => 'По возрастанию';

  @override
  String get orderDesc => 'По убыванию';

  @override
  String get startReading => 'Начать чтение';

  @override
  String get noBookmarks => 'Пока нет закладок';

  @override
  String get noBookmarksHint =>
      'Во время чтения нажмите вверху справа, чтобы добавить закладку\nи вернуться в любой момент.';

  @override
  String bookmarkEntry(int n, String title) {
    return 'Глава $n · $title';
  }

  @override
  String get emptyShelf =>
      'Нет книг — нажмите вверху справа, чтобы импортировать TXT';

  @override
  String get noMatches => 'Нет подходящих книг';

  @override
  String loadFailed(String error) {
    return 'Не удалось загрузить книги: $error';
  }

  @override
  String get languageSheetTitle => 'Язык';
}
