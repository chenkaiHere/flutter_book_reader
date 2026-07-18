// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get bookshelfTitle => '本棚';

  @override
  String shelfSummary(int total, int reading) {
    return '$total冊 · $reading冊 読書中';
  }

  @override
  String get searchHint => 'タイトル / 著者で検索';

  @override
  String get allBooks => 'すべての本';

  @override
  String get localTag => 'ローカル';

  @override
  String get continueReading => '続きを読む';

  @override
  String readToChapter(int n) {
    return '第$n章まで読んだ';
  }

  @override
  String get notStarted => '未開始';

  @override
  String readPercent(int pct) {
    return '$pct% 読了';
  }

  @override
  String get unread => '未読';

  @override
  String get importTooltip => 'TXTをインポート';

  @override
  String get importTitle => 'ローカル小説をインポート';

  @override
  String get importDesc => 'スマホのTXT小説を本棚に追加して、いつでもオフラインで読めます。';

  @override
  String get importPoint1Title => 'ワンタップ';

  @override
  String get importPoint1Body => 'ローカルのTXTファイルを選ぶだけ、通信不要';

  @override
  String get importPoint2Title => 'スマートな整形';

  @override
  String get importPoint2Body => 'タイトル・著者・章を自動で認識';

  @override
  String get importPoint3Title => '文字化けなし';

  @override
  String get importPoint3Body => 'UTF-8 / GBK / Big5 を自動判別';

  @override
  String get importPoint4Title => '保存と削除';

  @override
  String get importPoint4Body => '端末に保存。左スワイプで削除';

  @override
  String get importLater => '今はしない';

  @override
  String get importPick => 'TXTファイルを選択';

  @override
  String importedToast(String title, int count) {
    return '「$title」をインポート · $count章';
  }

  @override
  String importFailed(String error) {
    return 'インポート失敗：$error';
  }

  @override
  String get deleteTitle => '本を削除';

  @override
  String deleteMessage(String title) {
    return '「$title」を削除しますか？インポートした本のデータが削除されます。';
  }

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get cannotDeleteBuiltin => '内蔵の本は削除できません';

  @override
  String deletedToast(String title) {
    return '「$title」を削除しました';
  }

  @override
  String get tabDetail => '詳細';

  @override
  String get tabToc => '目次';

  @override
  String get tabBookmarks => 'しおり';

  @override
  String get statChapters => '章';

  @override
  String get statSource => '出所';

  @override
  String get statProgress => '進捗';

  @override
  String get sourceLocal => 'ローカル';

  @override
  String get sourceBuiltin => '内蔵';

  @override
  String get statusLocalImported => 'ローカルインポート';

  @override
  String get statusBuiltin => '内蔵の本';

  @override
  String get introHeading => 'あらすじ';

  @override
  String get noIntro => 'あらすじはありません。';

  @override
  String chapterCountLabel(int n) {
    return '全$n章';
  }

  @override
  String get orderAsc => '昇順';

  @override
  String get orderDesc => '降順';

  @override
  String get startReading => '読み始める';

  @override
  String get noBookmarks => 'しおりはまだありません';

  @override
  String get noBookmarksHint => '読書中に右上をタップするとしおりを追加でき、\nいつでも戻れます。';

  @override
  String bookmarkEntry(int n, String title) {
    return '第$n章 · $title';
  }

  @override
  String get emptyShelf => '本がありません — 右上をタップしてTXTをインポート';

  @override
  String get noMatches => '一致する本がありません';

  @override
  String loadFailed(String error) {
    return '本の読み込みに失敗：$error';
  }

  @override
  String get languageSheetTitle => '言語';
}
