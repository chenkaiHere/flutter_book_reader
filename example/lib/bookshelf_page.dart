import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/db/app_database.dart';
import 'data/db/book_db.dart';
import 'data/db/db_book_source.dart';
import 'data/shared_prefs_bookmark_store.dart';
import 'data/shared_prefs_comment_store.dart';
import 'data/shared_prefs_progress_store.dart';
import 'data/shared_prefs_underline_store.dart';
import 'import/txt_parser.dart';
import 'l10n/app_localizations.dart';
import 'theme/warm_theme.dart';
import 'widgets/book_card.dart';
import 'widgets/book_cover.dart';
import 'widgets/book_detail_sheet.dart';
import 'widgets/comment_input_sheet.dart';
import 'widgets/paragraph_comments_sheet.dart';
import 'widgets/share_card_sheet.dart';
import 'widgets/language_sheet.dart';
import 'widgets/warm_widgets.dart';

/// 全局 ScaffoldMessenger key：用于在阅读页（独立路由）上层弹出 SnackBar，
/// 例如长按选中文字后的操作提示。挂在 [MaterialApp.scaffoldMessengerKey] 上。
final GlobalKey<ScaffoldMessengerState> rootMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

/// 书架及 App 主界面的系统栏样式：状态栏透明 + 深色图标，底部导航栏白底黑字。
/// 与阅读页退出时恢复的样式一致，避免进入 App 时出现灰色遮罩 / 黑色导航栏。
const SystemUiOverlayStyle kAppSystemUi = SystemUiOverlayStyle(
  statusBarColor: Colors.transparent,
  statusBarIconBrightness: Brightness.dark,
  statusBarBrightness: Brightness.light,
  systemNavigationBarColor: Colors.white,
  systemNavigationBarIconBrightness: Brightness.dark,
  systemNavigationBarContrastEnforced: false,
);

/// 书架 / 书城入口页。数据全部来自 drift 数据库（内置书首次播种、导入书落库），
/// 列表只读书籍信息不含正文；阅读时正文按章懒读。视觉遵循「暖纸」设计（见 [Warm]）。
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key, this.database});

  /// 可注入数据库（测试用）；为空时自行创建并负责关闭。
  final AppDatabase? database;

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

enum _Layout { list, grid }

class _BookshelfPageState extends State<BookshelfPage> {
  late final AppDatabase _db = widget.database ?? AppDatabase();
  late final bool _ownsDb = widget.database == null;

  final SharedPrefsProgressStore _progressStore = SharedPrefsProgressStore();
  final ReaderBookmarkStore _bookmarkStore = SharedPrefsBookmarkStore();
  final ReaderUnderlineStore _underlineStore = SharedPrefsUnderlineStore();
  final ReaderCommentStore _commentStore = SharedPrefsCommentStore();

  /// 评论刷新信号：外部新增评论后自增，通知阅读器重新拉取评论、刷新段尾角标。
  final ValueNotifier<int> _commentsRev = ValueNotifier<int>(0);

  static const String _kImportIntroShownKey = 'import_intro_shown';

  List<BookRow> _books = const <BookRow>[];
  final Map<int, ReadingPosition> _progress = <int, ReadingPosition>{};
  int? _lastReadId;

  bool _loading = true;
  Object? _error;
  bool _importing = false;
  String _query = '';
  _Layout _layout = _Layout.list;

  AppLocalizations get _l => AppLocalizations.of(context);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _commentsRev.dispose();
    if (_ownsDb) _db.close();
    super.dispose();
  }

  // ————————————————————— 数据加载 —————————————————————

  Future<void> _load() async {
    try {
      await BookDb.seedBuiltIns(_db); // 首次把内置书播种进库
      final List<BookRow> books = await _db.listBooks();
      if (!mounted) return;
      setState(() {
        _books = books;
        _loading = false;
      });
      await _refreshProgress();
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _reloadBooks() async {
    final List<BookRow> books = await _db.listBooks();
    if (!mounted) return;
    setState(() => _books = books);
  }

  Future<void> _refreshProgress() async {
    final Map<int, ReadingPosition> p = await _progressStore.loadAll(
      _books.map((BookRow e) => e.id),
    );
    final int? last = await _progressStore.lastReadBookId();
    if (!mounted) return;
    setState(() {
      _progress
        ..clear()
        ..addAll(p);
      _lastReadId = last;
    });
  }

  double _progressOf(BookRow b) {
    final ReadingPosition? pos = _progress[b.id];
    if (pos == null || b.chapterCount == 0) return 0;
    return ((pos.chapterIndex + 1) / b.chapterCount).clamp(0.0, 1.0);
  }

  List<BookRow> get _filtered {
    final String q = _query.trim();
    if (q.isEmpty) return _books;
    return _books
        .where((BookRow e) => e.title.contains(q) || e.author.contains(q))
        .toList();
  }

  BookRow? get _continue {
    if (_lastReadId == null) return null;
    for (final BookRow b in _books) {
      if (b.id == _lastReadId && _progressOf(b) > 0) return b;
    }
    return null;
  }

  int get _readingCount =>
      _books.where((BookRow e) => _progressOf(e) > 0).length;

  // ————————————————————— 打开 / 阅读 —————————————————————

  Future<void> _openDetail(BookRow book) async {
    final ReadIntent? intent = await BookDetailSheet.show(
      context,
      book: book,
      source: DbBookSource(_db, book.id),
      progress: _progressOf(book),
      position: _progress[book.id],
      bookmarkStore: _bookmarkStore,
      underlineStore: _underlineStore,
      commentStore: _commentStore,
    );
    if (intent != null) {
      await _openReader(book, startChapter: intent.startChapter);
    }
    await _refreshProgress();
  }

  Future<void> _openReader(BookRow book, {int? startChapter}) async {
    await _progressStore.markLastRead(book.id);
    if (!mounted) return;
    // 把当前 App 语言传给插件：插件按语言码取内置文案，未命中回退英文。
    final ReaderLabels labels = ReaderLabels.forLanguageCode(
      Localizations.localeOf(context).languageCode,
    );
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BookReader(
          source: DbBookSource(_db, book.id),
          labels: labels,
          progressStore: _progressStore,
          bookmarkStore: _bookmarkStore,
          underlineStore: _underlineStore,
          commentStore: _commentStore,
          commentsRefresh: _commentsRev,
          startChapter: startChapter,
          // 气泡菜单「复制 / 评论 / 查询 / 分享」全部回调到 App 侧自行处理。
          onTextAction: (ReaderTextAction action, ReaderSelection sel) =>
              _onReaderTextAction(book, labels, action, sel),
          // 段尾「段评」角标点击：插件只抛段落信息，这里弹出该段评论列表。
          onSegmentCommentTap: (ReaderSegmentTap seg) =>
              _onSegmentTap(book, labels, seg),
        ),
      ),
    );
    await _refreshProgress();
  }

  /// 气泡工具条动作全部由 App 处理：复制→写剪贴板；查询/分享→示意提示；
  /// 评论→弹 App 自己的输入弹层并写入 [_commentStore]（阅读器打开笔记时会重新读取）。
  Future<void> _onReaderTextAction(
    BookRow book,
    ReaderLabels labels,
    ReaderTextAction action,
    ReaderSelection sel,
  ) async {
    void toast(String msg) => rootMessengerKey.currentState
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));

    switch (action) {
      case ReaderTextAction.copy:
        await Clipboard.setData(ClipboardData(text: sel.text));
        toast('已复制');
      case ReaderTextAction.query:
        toast('查询：${sel.text}');
      case ReaderTextAction.share:
        if (!mounted) return;
        await ShareCardSheet.show(
          context,
          bookTitle: book.title,
          author: book.author,
          coverColor: Color(book.coverColor),
          chapterTitle: sel.chapterTitle,
          quote: sel.text,
        );
      case ReaderTextAction.comment:
        if (!mounted) return;
        final String? body = await CommentInputSheet.show(
          context,
          labels: labels,
          quote: sel.text,
        );
        if (body == null || body.trim().isEmpty) return;
        // 兜底：区间未解析时钳到 0，保证评论仍会保存、出现在笔记里（不静默丢弃）。
        final Comment comment = Comment(
          chapterIndex: sel.chapterIndex,
          start: sel.start < 0 ? 0 : sel.start,
          end: sel.end < 0 ? 0 : sel.end,
          quote: sel.text,
          text: body.trim(),
          chapterTitle: sel.chapterTitle,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        );
        // 必须先拷成可变列表：store 在无评论时可能返回 const [] （不可变），
        // 直接 ..add 会抛 Cannot add to an unmodifiable list，导致首条评论存不进。
        final List<Comment> list = List<Comment>.of(
          await _commentStore.load(book.id),
        )..add(comment);
        await _commentStore.save(book.id, list);
        // 通知阅读器刷新：段尾角标、笔记数据立即反映这条新评论。
        _commentsRev.value++;
        toast('已评论');
      case ReaderTextAction.highlight:
        // 划线由插件内部处理，正常不会回调到这里。
        break;
    }
  }

  /// 段尾角标点击：从 store 取该书评论，筛出落在该段区间内的，弹出段评列表。
  Future<void> _onSegmentTap(
    BookRow book,
    ReaderLabels labels,
    ReaderSegmentTap seg,
  ) async {
    final List<Comment> all = await _commentStore.load(book.id);
    final List<Comment> inSegment = all
        .where((Comment c) => seg.contains(c))
        .toList();
    if (!mounted || inSegment.isEmpty) return;
    await ParagraphCommentsSheet.show(
      context,
      comments: inSegment,
      labels: labels,
    );
  }

  // ————————————————————— 删除 —————————————————————

  Future<void> _onDelete(BookRow book) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppLocalizations l = _l;
    if (!book.imported) {
      messenger.showSnackBar(SnackBar(content: Text(l.cannotDeleteBuiltin)));
      return;
    }
    final bool confirmed =
        await showDialog<bool>(
          context: context,
          builder: (BuildContext ctx) => AlertDialog(
            backgroundColor: Warm.sheet,
            title: Text(l.deleteTitle, style: Warm.serif(size: 19)),
            content: Text(
              l.deleteMessage(book.title),
              style: Warm.sans(size: 14, height: 1.5, color: Warm.ink2),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.cancel, style: Warm.sans(color: Warm.muted2)),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  l.delete,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _db.deleteBook(book.id); // 从库中删除书 + 章节
      await _progressStore.clear(book.id);
      if (!mounted) return;
      setState(() {
        _books = _books.where((BookRow e) => e.id != book.id).toList();
        _progress.remove(book.id);
      });
      messenger.showSnackBar(
        SnackBar(content: Text(l.deletedToast(book.title))),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('删除失败：$e')));
    }
  }

  // ————————————————————— 导入 —————————————————————

  Future<void> _onImportPressed() async {
    if (_importing) return;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final bool shown = prefs.getBool(_kImportIntroShownKey) ?? false;
    if (!shown) {
      if (!mounted) return;
      final bool proceed = await _showImportIntro();
      await prefs.setBool(_kImportIntroShownKey, true);
      if (!proceed) return;
    }
    await _importTxt();
  }

  Future<bool> _showImportIntro() async {
    final AppLocalizations l = _l;
    Widget point(String bold, String rest) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2, right: 11),
            child: Text('✦', style: Warm.sans(color: Warm.accent)),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: <InlineSpan>[
                  TextSpan(
                    text: '$bold　',
                    style: Warm.sans(size: 13.5, weight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: rest,
                    style: Warm.sans(
                      size: 13.5,
                      height: 1.55,
                      color: Warm.ink2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    final bool? r = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => Dialog(
        backgroundColor: Warm.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 26, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.menu_book_outlined,
                    color: Warm.accent,
                    size: 30,
                  ),
                  const SizedBox(width: 12),
                  Text(l.importTitle, style: Warm.serif(size: 22)),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                l.importDesc,
                style: Warm.sans(size: 14.5, height: 1.7, color: Warm.ink2),
              ),
              const SizedBox(height: 16),
              point(l.importPoint1Title, l.importPoint1Body),
              point(l.importPoint2Title, l.importPoint2Body),
              point(l.importPoint3Title, l.importPoint3Body),
              point(l.importPoint4Title, l.importPoint4Body),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text(
                      l.importLater,
                      style: Warm.sans(
                        size: 15,
                        weight: FontWeight.w600,
                        color: Warm.accent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _GradientButton(
                      icon: Icons.file_upload_outlined,
                      label: l.importPick,
                      onTap: () => Navigator.of(ctx).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return r ?? false;
  }

  Future<void> _importTxt() async {
    if (_importing) return;
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final FilePickerResult? res = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['txt'],
      withData: kIsWeb,
    );
    if (res == null || res.files.isEmpty) return;
    final PlatformFile f = res.files.single;

    setState(() => _importing = true);
    try {
      final Map<String, dynamic> json;
      // Web 一律走字节路径（无文件系统 / isolate）；原生优先用文件路径。
      if (!kIsWeb && f.path != null) {
        json = await TxtBookParser.parseFile(f.path!);
      } else if (f.bytes != null) {
        json = await TxtBookParser.parseBytes(f.bytes!, fileName: f.name);
      } else {
        throw StateError('无法读取所选文件');
      }
      final int id = await BookDb.importParsed(
        _db,
        json,
        nowMs: DateTime.now().millisecondsSinceEpoch,
      );
      await _reloadBooks(); // 重新拉列表（含新书 + 正确排序）
      if (!mounted) return;
      final BookRow? added = _books
          .where((BookRow e) => e.id == id)
          .firstOrNull;
      setState(() => _importing = false);
      if (added != null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(_l.importedToast(added.title, added.chapterCount)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      messenger.showSnackBar(SnackBar(content: Text(_l.importFailed('$e'))));
    }
  }

  // ————————————————————— 视图 —————————————————————

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: kAppSystemUi,
      child: Scaffold(
        backgroundColor: Warm.bg,
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(child: _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Text(
          _l.loadFailed('$_error'),
          style: Warm.sans(color: Warm.ink2),
        ),
      );
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: Warm.accent));
    }

    final List<BookRow> list = _filtered;
    final bool searching = _query.trim().isNotEmpty;
    final BookRow? cont = _continue;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              _header(),
              const SizedBox(height: 14),
              _searchBar(),
              if (!searching && cont != null) ...<Widget>[
                const SizedBox(height: 18),
                _continueCard(cont),
              ],
              const SizedBox(height: 22),
              _sectionHeader(list.length),
              const SizedBox(height: 14),
            ]),
          ),
        ),
        if (list.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _empty())
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
            sliver: _layout == _Layout.list
                ? _listSliver(list)
                : _gridSliver(list),
          ),
      ],
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _l.bookshelfTitle,
                style: Warm.serif(
                  size: 31,
                  weight: FontWeight.w800,
                  height: 1,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _l.shelfSummary(_books.length, _readingCount),
                style: Warm.sans(size: 12.5, color: Warm.muted),
              ),
            ],
          ),
        ),
        _iconBox(
          icon: Icons.language,
          onTap: () => LanguageSheet.show(context),
        ),
        const SizedBox(width: 10),
        _importButton(),
      ],
    );
  }

  /// 圆角描边图标按钮（语言 / 与导入按钮同款外观）。
  Widget _iconBox({required IconData icon, required VoidCallback onTap}) {
    return Material(
      color: Warm.card,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: onTap,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Warm.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Warm.hairline),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF5A3C1E).withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(child: Icon(icon, size: 21, color: Warm.accent)),
        ),
      ),
    );
  }

  Widget _importButton() {
    return Material(
      color: Warm.card,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        borderRadius: BorderRadius.circular(13),
        onTap: _importing ? null : _onImportPressed,
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Warm.card,
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Warm.hairline),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF5A3C1E).withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Center(
            child: _importing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Warm.accent,
                    ),
                  )
                : const Icon(
                    Icons.file_upload_outlined,
                    size: 21,
                    color: Warm.accent,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: Warm.card,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Warm.hairline),
      ),
      child: Row(
        children: <Widget>[
          const Icon(Icons.search, size: 18, color: Color(0xFFB39A80)),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              onChanged: (String v) => setState(() => _query = v),
              style: Warm.sans(size: 14.5),
              cursorColor: Warm.accent,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: _l.searchHint,
                hintStyle: Warm.sans(size: 14.5, color: Warm.muted),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _continueCard(BookRow b) {
    final double pct = _progressOf(b);
    final ReadingPosition? pos = _progress[b.id];
    final String curLabel = pos == null
        ? _l.notStarted
        : _l.readToChapter(pos.chapterIndex + 1);
    return Container(
      decoration: BoxDecoration(
        gradient: Warm.contCardGradient,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Warm.accent.withValues(alpha: 0.16)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF965A28).withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          BookCover(
            title: b.title,
            color: Color(b.coverColor),
            width: 60,
            height: 84,
            fontSize: 13,
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Warm.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _l.continueReading,
                      style: Warm.sans(
                        size: 11.5,
                        weight: FontWeight.w700,
                        color: Warm.accent,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  b.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Warm.serif(size: 19, weight: FontWeight.w700),
                ),
                const SizedBox(height: 3),
                Text(
                  curLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Warm.sans(size: 12.5, color: Warm.muted2),
                ),
                const SizedBox(height: 9),
                Row(
                  children: <Widget>[
                    Expanded(child: WarmProgressBar(value: pct)),
                    const SizedBox(width: 9),
                    Text(
                      '${(pct * 100).round()}%',
                      style: Warm.sans(
                        size: 12,
                        weight: FontWeight.w700,
                        color: Warm.accent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _PlayButton(onTap: () => _openReader(b)),
        ],
      ),
    );
  }

  Widget _sectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text.rich(
          TextSpan(
            children: <InlineSpan>[
              TextSpan(
                text: '${_l.allBooks} ',
                style: Warm.serif(size: 16, weight: FontWeight.w700),
              ),
              TextSpan(
                text: '$count',
                style: Warm.serif(
                  size: 16,
                  weight: FontWeight.w600,
                  color: Warm.muted,
                ),
              ),
            ],
          ),
        ),
        _layoutToggle(),
      ],
    );
  }

  Widget _layoutToggle() {
    Widget seg(_Layout layout, IconData icon) {
      final bool on = _layout == layout;
      return GestureDetector(
        onTap: () => setState(() => _layout = layout),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? Warm.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            boxShadow: on
                ? <BoxShadow>[
                    BoxShadow(
                      color: Warm.accent.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Icon(icon, size: 17, color: on ? Colors.white : Warm.muted2),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Warm.track,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          seg(_Layout.list, Icons.view_list_rounded),
          const SizedBox(width: 3),
          seg(_Layout.grid, Icons.grid_view_rounded),
        ],
      ),
    );
  }

  Widget _listSliver(List<BookRow> list) {
    return SliverList(
      delegate: SliverChildBuilderDelegate((BuildContext _, int i) {
        final BookRow book = list[i];
        return Padding(
          padding: EdgeInsets.only(bottom: i == list.length - 1 ? 0 : 14),
          child: Slidable(
            key: ValueKey<int>(book.id),
            endActionPane: ActionPane(
              motion: const DrawerMotion(),
              extentRatio: 0.28,
              children: <Widget>[
                SlidableAction(
                  onPressed: (_) => _onDelete(book),
                  backgroundColor: book.imported
                      ? Colors.red
                      : Colors.grey.shade500,
                  foregroundColor: Colors.white,
                  icon: book.imported ? Icons.delete : Icons.lock_outline,
                  label: book.imported ? '删除' : '内置',
                  borderRadius: BorderRadius.circular(18),
                ),
              ],
            ),
            child: BookCard(
              book: book,
              progress: _progressOf(book),
              onTap: () => _openDetail(book),
            ),
          ),
        );
      }, childCount: list.length),
    );
  }

  Widget _gridSliver(List<BookRow> list) {
    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.54,
      ),
      delegate: SliverChildBuilderDelegate((BuildContext _, int i) {
        final BookRow book = list[i];
        final double pct = _progressOf(book);
        return GestureDetector(
          onTap: () => _openDetail(book),
          onLongPress: book.imported ? () => _onDelete(book) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: BookCover(
                  title: book.title,
                  color: Color(book.coverColor),
                  radius: 8,
                  fontSize: 15,
                  badge: pct > 0 ? CoverBadge('${(pct * 100).round()}%') : null,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Warm.sans(size: 13, weight: FontWeight.w600),
              ),
              Text(
                book.author,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Warm.sans(size: 11, color: Warm.muted),
              ),
            ],
          ),
        );
      }, childCount: list.length),
    );
  }

  Widget _empty() {
    return Center(
      child: Text(
        _query.trim().isNotEmpty ? _l.noMatches : _l.emptyShelf,
        style: Warm.sans(color: Warm.muted2),
      ),
    );
  }
}

/// 继续阅读的圆形播放按钮。
class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: Warm.btnGradient,
          shape: BoxShape.circle,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFA94E26).withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}

/// 通用赤陶渐变按钮（弹窗用）。
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.label, required this.onTap, this.icon});
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          gradient: Warm.btnGradient,
          borderRadius: BorderRadius.circular(15),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFFA94E26).withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: Warm.sans(
                size: 15,
                weight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
