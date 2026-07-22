// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get listeningNow => '听书中';

  @override
  String get bookshelfTitle => '书架';

  @override
  String shelfSummary(int total, int reading) {
    return '共 $total 本 · 在读 $reading 本';
  }

  @override
  String get searchHint => '搜索书名 / 作者';

  @override
  String get allBooks => '全部书籍';

  @override
  String get localTag => '本地';

  @override
  String get continueReading => '继续阅读';

  @override
  String readToChapter(int n) {
    return '读到 第 $n 章';
  }

  @override
  String get notStarted => '未开始';

  @override
  String readPercent(int pct) {
    return '已读 $pct%';
  }

  @override
  String get unread => '未读';

  @override
  String get importTooltip => '导入 TXT';

  @override
  String get importTitle => '导入本地小说';

  @override
  String get importDesc => '把手机里的 TXT 小说加入书架，随时离线畅读。';

  @override
  String get importPoint1Title => '一键导入';

  @override
  String get importPoint1Body => '选择本地 TXT 文件即可，无需联网';

  @override
  String get importPoint2Title => '智能排版';

  @override
  String get importPoint2Body => '自动识别书名、作者与章节';

  @override
  String get importPoint3Title => '编码无忧';

  @override
  String get importPoint3Body => '自动检测 UTF-8 / GBK / Big5，中文不乱码';

  @override
  String get importPoint4Title => '随存随删';

  @override
  String get importPoint4Body => '保存在本机，左滑即可删除';

  @override
  String get importLater => '暂不导入';

  @override
  String get importPick => '选择 TXT 文件';

  @override
  String importedToast(String title, int count) {
    return '已导入《$title》，共 $count 章';
  }

  @override
  String importFailed(String error) {
    return '导入失败：$error';
  }

  @override
  String get deleteTitle => '删除书籍';

  @override
  String deleteMessage(String title) {
    return '确定删除《$title》吗？此操作将移除已导入的书籍数据。';
  }

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get cannotDeleteBuiltin => '内置书籍无法删除';

  @override
  String deletedToast(String title) {
    return '已删除《$title》';
  }

  @override
  String get tabDetail => '详情';

  @override
  String get tabToc => '目录';

  @override
  String get tabBookmarks => '书签';

  @override
  String get statChapters => '章节';

  @override
  String get statSource => '来源';

  @override
  String get statProgress => '进度';

  @override
  String get sourceLocal => '本地';

  @override
  String get sourceBuiltin => '内置';

  @override
  String get statusLocalImported => '本地导入';

  @override
  String get statusBuiltin => '内置书籍';

  @override
  String get introHeading => '内容简介';

  @override
  String get noIntro => '暂无简介。';

  @override
  String chapterCountLabel(int n) {
    return '共 $n 章';
  }

  @override
  String get orderAsc => '正序';

  @override
  String get orderDesc => '倒序';

  @override
  String get startReading => '开始阅读';

  @override
  String get noBookmarks => '还没有书签';

  @override
  String get noBookmarksHint => '阅读时点击右上角即可添加书签，\n方便随时回到精彩之处。';

  @override
  String bookmarkEntry(int n, String title) {
    return '第 $n 章 · $title';
  }

  @override
  String get emptyShelf => '暂无书籍，点击右上角导入 TXT';

  @override
  String get noMatches => '没有匹配的书籍';

  @override
  String loadFailed(String error) {
    return '书籍加载失败：$error';
  }

  @override
  String get languageSheetTitle => '语言';
}
