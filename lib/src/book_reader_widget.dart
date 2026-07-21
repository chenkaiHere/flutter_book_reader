import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bookmark/reader_bookmark_store.dart';
import 'comment/reader_comment_store.dart';
import 'controller/reading_controller.dart';
import 'paginator.dart';
import 'progress/reader_progress_store.dart';
import 'reader_config.dart';
import 'reader_labels.dart';
import 'reader_theme.dart';
import 'source/book_source.dart';
import 'text_actions.dart';
import 'underline/reader_underline_store.dart';
import 'views/horizontal_reader.dart';
import 'views/simulation_reader.dart';
import 'views/vertical_reader.dart';
import 'widgets/catalog_sheet.dart';
import 'widgets/loading_page.dart';
import 'widgets/page_frame.dart';
import 'widgets/reader_menu.dart';

/// 可商用的阅读器组件（对外统一入口）。
///
/// 只依赖抽象 [BookSource] 与 [ReaderProgressStore]，业务方替换实现即可接入
/// 网络 / 数据库 / 云同步，无需改动内部。负责：加载书籍清单、恢复/保存阅读进度、
/// 按翻页方式挑选视图、叠加亮度蒙层 / 菜单 / 目录，并向外回调章节与进度事件。
class BookReader extends StatefulWidget {
  const BookReader({
    super.key,
    required this.source,
    this.config,
    this.progressStore = const NoopReaderProgressStore(),
    this.bookmarkStore = const NoopReaderBookmarkStore(),
    this.underlineStore = const NoopReaderUnderlineStore(),
    this.commentStore = const NoopReaderCommentStore(),
    this.labels = const ReaderLabels(),
    this.startChapter,
    this.onChapterChanged,
    this.onPositionChanged,
    this.onClose,
    this.onTextAction,
    this.onSegmentCommentTap,
    this.commentsRefresh,
    this.enableTextSelection = true,
  });

  /// 书籍数据源
  final BookSource source;

  /// 阅读设置；为空时使用全局单例 [ReaderConfig.instance]
  final ReaderConfig? config;

  /// 阅读进度存储；默认不持久化
  final ReaderProgressStore progressStore;

  /// 书签存储；默认不持久化（仅当前会话内有效）
  final ReaderBookmarkStore bookmarkStore;

  /// 划线存储；默认不持久化（仅当前会话内有效）
  final ReaderUnderlineStore underlineStore;

  /// 评论存储；默认不持久化（仅当前会话内有效）
  final ReaderCommentStore commentStore;

  /// 界面文案（支持本地化 / 白标）
  final ReaderLabels labels;

  /// 指定起始章；为空时优先使用 [progressStore] 中恢复的位置
  final int? startChapter;

  /// 当前阅读章节变化回调
  final ValueChanged<int>? onChapterChanged;

  /// 阅读位置变化回调（章 + 字符偏移）
  final ValueChanged<ReadingPosition>? onPositionChanged;

  /// 返回 / 关闭回调；为空时默认 pop
  final VoidCallback? onClose;

  /// 长按选中正文后，气泡工具条上「复制 / 评论 / 查询 / 分享」的点击回调。
  /// 这四个动作插件不做任何内部处理（不写剪贴板、不弹输入框），只把选中详情
  /// [ReaderSelection] 回调给业务方自行处理。「划线」由插件内部渲染/持久化，不走此回调。
  final ReaderTextActionCallback? onTextAction;

  /// 点击段落尾部「段评」数字角标的回调。插件只在段尾显示数字，点击后把段落信息
  /// [ReaderSegmentTap] 抛给业务方，由业务方自行弹出评论列表。为空时不显示角标。
  final ReaderSegmentTapCallback? onSegmentCommentTap;

  /// 评论刷新信号：业务方在外部新增/删除评论后触发它（如 `ValueNotifier<int>..value++`），
  /// 阅读器据此从 [commentStore] 重新拉取评论并刷新段尾角标 / 笔记。
  final Listenable? commentsRefresh;

  /// 是否启用「长按选中正文」功能（默认开启）。
  final bool enableTextSelection;

  @override
  State<BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> with WidgetsBindingObserver {
  ReadingController? _controller;
  Object? _error;
  int _lastChapter = -1;
  Timer? _saveTimer;

  final ValueNotifier<bool> _menuVisible = ValueNotifier<bool>(false);

  /// 当前书籍的书签（会话内的权威副本，变更后写回 [BookReader.bookmarkStore]）。
  List<Bookmark> _bookmarks = <Bookmark>[];

  /// 当前书籍的划线（会话内的权威副本，变更后写回 [BookReader.underlineStore]）。
  /// 使用不可变 [List] 引用整体替换，供 [ReaderUnderlineScope] 触发子树刷新。
  List<Underline> _underlines = const <Underline>[];

  /// 当前书籍的评论（会话内的权威副本，变更后写回 [BookReader.commentStore]）。
  List<Comment> _comments = const <Comment>[];

  ReaderConfig get _config => widget.config ?? ReaderConfig.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 全屏沉浸：进入阅读页即隐藏系统状态栏与导航栏，并在唤起菜单时保持隐藏——
    // 避免状态栏出现时把正文往下顶，正文始终铺满整屏。
    _enterImmersive();
    widget.commentsRefresh?.addListener(_reloadComments);
    _init();
  }

  @override
  void didUpdateWidget(BookReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.commentsRefresh, widget.commentsRefresh)) {
      oldWidget.commentsRefresh?.removeListener(_reloadComments);
      widget.commentsRefresh?.addListener(_reloadComments);
    }
  }

  /// 业务方在外部改动评论后触发 [BookReader.commentsRefresh]，据此重新拉取评论，
  /// 刷新段尾角标与笔记列表数据。
  Future<void> _reloadComments() async {
    final ReadingController? c = _controller;
    if (c == null) return;
    try {
      final List<Comment> latest =
          await widget.commentStore.load(c.manifest.id);
      if (mounted) {
        setState(() => _comments = List<Comment>.unmodifiable(latest));
      }
    } catch (_) {
      // 读取失败保持现有内存副本
    }
  }

  void _enterImmersive() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _init() async {
    try {
      final BookManifest manifest = await widget.source.loadManifest();
      final ReadingPosition? saved = await widget.progressStore.load(
        manifest.id,
      );
      final List<Bookmark> bookmarks =
          await widget.bookmarkStore.load(manifest.id);
      final List<Underline> underlines =
          await widget.underlineStore.load(manifest.id);
      final List<Comment> comments =
          await widget.commentStore.load(manifest.id);
      final int start = widget.startChapter ?? saved?.chapterIndex ?? 0;
      final int offset =
          widget.startChapter != null ? 0 : (saved?.charOffset ?? 0);

      if (!mounted) return;
      final ReadingController controller = ReadingController(
        source: widget.source,
        manifest: manifest,
        config: _config,
        startChapter: start,
        startCharOffset: offset,
      );
      _lastChapter = controller.chapterIndex;
      controller.addListener(_onControllerChanged);
      setState(() {
        _controller = controller;
        _bookmarks = bookmarks;
        _underlines = List<Underline>.unmodifiable(underlines);
        _comments = List<Comment>.unmodifiable(comments);
        _error = null;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  /// 仅做副作用（回调 + 防抖保存），UI 刷新交给 AnimatedBuilder，避免高频重建。
  void _onControllerChanged() {
    final ReadingController c = _controller!;
    if (c.chapterIndex != _lastChapter) {
      _lastChapter = c.chapterIndex;
      widget.onChapterChanged?.call(c.chapterIndex);
    }
    widget.onPositionChanged?.call(c.position);
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), _flushSave);
  }

  void _flushSave() {
    final ReadingController? c = _controller;
    if (c != null) widget.progressStore.save(c.manifest.id, c.position);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 进入后台前立即落盘，避免防抖窗口内丢失进度
    if (state != AppLifecycleState.resumed) {
      _saveTimer?.cancel();
      _flushSave();
    } else {
      // 从后台返回时系统可能已重置 UI 模式，重新应用沉浸式
      _enterImmersive();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.commentsRefresh?.removeListener(_reloadComments);
    _saveTimer?.cancel();
    _flushSave();
    // 离开阅读页：恢复系统栏显示，并把状态栏 / 底部导航栏重置为“白底黑字”默认样式，
    // 否则阅读页设置的纸张色会残留到退出后的页面。
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _controller?.removeListener(_onControllerChanged);
    _controller?.dispose();
    _menuVisible.dispose();
    super.dispose();
  }

  void _close() => (widget.onClose ?? () => Navigator.of(context).maybePop())();

  void _toggleMenu() => _menuVisible.value = !_menuVisible.value;

  void _handleTap(TapUpDetails d, double width) {
    if (_menuVisible.value) {
      _menuVisible.value = false;
      return;
    }
    final double x = d.localPosition.dx;
    if (x < width * 0.33) {
      _controller!.prevPage();
    } else if (x > width * 0.67) {
      _controller!.nextPage();
    } else {
      _toggleMenu();
    }
  }

  // —— 书签 ——

  /// 当前页（起始偏移落在本页区间内）已有的书签；没有则为 null。
  Bookmark? _bookmarkOnCurrentPage() {
    final ReadingController? c = _controller;
    if (c == null || c.pages.isEmpty) return null;
    final int start = c.startOffsetOfPage(c.pageIndex);
    final int end = c.pageIndex + 1 < c.pages.length
        ? c.startOffsetOfPage(c.pageIndex + 1)
        : 1 << 30;
    for (final Bookmark b in _bookmarks) {
      if (b.chapterIndex == c.chapterIndex &&
          b.charOffset >= start &&
          b.charOffset < end) {
        return b;
      }
    }
    return null;
  }

  bool get _isBookmarked => _bookmarkOnCurrentPage() != null;

  /// 加入 / 移除当前页书签（已存在则移除，否则新增），并写回存储。
  void _toggleBookmark() {
    final ReadingController c = _controller!;
    final Bookmark? existing = _bookmarkOnCurrentPage();
    final List<Bookmark> next = List<Bookmark>.of(_bookmarks);
    if (existing != null) {
      next.removeWhere((Bookmark b) => b.key == existing.key);
    } else {
      next.add(Bookmark(
        chapterIndex: c.chapterIndex,
        charOffset: c.startOffsetOfPage(c.pageIndex),
        chapterTitle: c.currentChapterTitle,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
    setState(() => _bookmarks = next);
    widget.bookmarkStore.save(c.manifest.id, next);
  }

  /// 新增一条划线（去重同区间），补全标题/时间后写回存储。
  void _addUnderline(int chapterIndex, int start, int end, String text) {
    final ReadingController c = _controller!;
    final Underline u = Underline(
      chapterIndex: chapterIndex,
      start: start,
      end: end,
      text: text,
      chapterTitle: c.chapterTitleAt(chapterIndex),
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    final List<Underline> next = List<Underline>.of(_underlines)
      ..removeWhere((Underline e) => e.key == u.key)
      ..add(u);
    setState(() => _underlines = List<Underline>.unmodifiable(next));
    widget.underlineStore.save(c.manifest.id, next);
  }

  /// 删除若干条划线，并写回存储。
  void _removeUnderlines(List<Underline> targets) {
    if (targets.isEmpty) return;
    final ReadingController c = _controller!;
    final Set<String> keys = targets.map((Underline u) => u.key).toSet();
    final List<Underline> next = List<Underline>.of(_underlines)
      ..removeWhere((Underline e) => keys.contains(e.key));
    setState(() => _underlines = List<Underline>.unmodifiable(next));
    widget.underlineStore.save(c.manifest.id, next);
  }

  /// 删除若干条评论，并写回存储。
  void _removeComments(List<Comment> targets) {
    if (targets.isEmpty) return;
    final ReadingController c = _controller!;
    final Set<String> keys = targets.map((Comment e) => e.key).toSet();
    final List<Comment> next = List<Comment>.of(_comments)
      ..removeWhere((Comment e) => keys.contains(e.key));
    setState(() => _comments = List<Comment>.unmodifiable(next));
    widget.commentStore.save(c.manifest.id, next);
  }

  Future<void> _openCatalog() async {
    final ReadingController c = _controller!;
    _menuVisible.value = false;
    // 评论由业务方在选中回调里自行写入 commentStore（插件不再内部新增），因此打开
    // 目录/笔记前从存储重新拉取，确保刚写入的评论也能出现在笔记列表。
    await _reloadComments();
    if (!mounted) return;
    final ReadingPosition? picked = await showModalBottomSheet<ReadingPosition>(
      context: context,
      isScrollControlled: true,
      // 由 DraggableScrollableSheet 自绘圆角纸张背景，因此外层透明。
      backgroundColor: Colors.transparent,
      builder: (_) => ReaderLabelsScope(
        labels: widget.labels,
        // 可拖拽面板：列表滚到顶部后继续下拉会带动整个面板下移，拖到底部即关闭。
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (BuildContext context, ScrollController scrollController) {
            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: ColoredBox(
                color: _config.theme.paperColor,
                child: CatalogSheet(
                  bookTitle: c.manifest.title,
                  author: c.manifest.author,
                  intro: c.manifest.intro,
                  coverColor: c.manifest.coverColor,
                  chapterTitles: c.manifest.chapterTitles,
                  currentIndex: c.chapterIndex,
                  bookmarks: _bookmarks,
                  underlines: _underlines,
                  comments: _comments,
                  onDeleteBookmark: (Bookmark b) {
                    final List<Bookmark> next = List<Bookmark>.of(_bookmarks)
                      ..removeWhere((Bookmark e) => e.key == b.key);
                    setState(() => _bookmarks = next);
                    widget.bookmarkStore.save(c.manifest.id, next);
                  },
                  onDeleteUnderline: (Underline u) =>
                      _removeUnderlines(<Underline>[u]),
                  onDeleteComment: (Comment cm) =>
                      _removeComments(<Comment>[cm]),
                  theme: _config.theme,
                  scrollController: scrollController,
                ),
              ),
            );
          },
        ),
      ),
    );
    if (picked != null) {
      // 章节：跳到章首（charOffset 0）；书签：跳到章内指定偏移
      if (picked.charOffset > 0 || picked.chapterIndex != c.chapterIndex) {
        c.loadChapter(picked.chapterIndex, charOffset: picked.charOffset);
      }
    }
  }

  /// 状态栏 + 底部系统导航栏都用纸张色（沉浸），图标明暗随主题。
  SystemUiOverlayStyle _overlayStyle(ReaderTheme t) {
    final Brightness icons = t.isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: t.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: t.paperColor,
      systemNavigationBarIconBrightness: icons,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ReaderSelectionScope(
      enabled: widget.enableTextSelection,
      onAction: widget.onTextAction,
      child: ReaderUnderlineScope(
        underlines: _underlines,
        onAdd: _addUnderline,
        onRemove: _removeUnderlines,
        child: ReaderSegmentScope(
          comments: _comments,
          onTap: widget.onSegmentCommentTap,
          child: ReaderLabelsScope(
            labels: widget.labels,
            child: _buildScaffold(),
          ),
        ),
      ),
    );
  }

  Widget _buildScaffold() {
    final ReadingController? c = _controller;

    // 未就绪 / 出错：静态主题 Scaffold（此阶段菜单不可用，主题不会变化）。
    if (c == null) {
      final ReaderTheme t = _config.theme;
      return AnnotatedRegion<SystemUiOverlayStyle>(
        value: _overlayStyle(t),
        child: Scaffold(
          backgroundColor: t.paperColor,
          body: _error != null
              ? ReaderStatusPage(
                  theme: t,
                  error: true,
                  onRetry: () {
                    setState(() => _error = null);
                    _init();
                  },
                )
              : ReaderStatusPage(theme: t),
        ),
      );
    }

    // 就绪：整个 Scaffold（含纸张背景色 / 状态栏样式）随控制器重建。
    // config 变化会经 ReadingController 通知，因此切主题 / 改字号会立即生效。
    // 菜单显隐用 ValueNotifier 局部刷新，与内容互不牵连。
    return AnimatedBuilder(
      animation: c,
      builder: (BuildContext context, _) {
        final ReaderTheme t = _config.theme;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _overlayStyle(t),
          child: Scaffold(
            backgroundColor: t.paperColor,
            // 不为键盘缩放正文：评论等输入弹层的键盘属于上层模态，若在此缩放会挤矮
            // 正文区触发重新分页，导致背景页“翻页”，键盘收起后又弹回。
            resizeToAvoidBottomInset: false,
            body: Stack(
              children: <Widget>[
                // 正文始终可交互。菜单唤起时由 ReaderMenu 的全屏 opaque 遮罩拦截手势：
                // 点击或滑动都只关闭菜单，不翻页；菜单关闭后再滑动才会翻页。
                Positioned.fill(child: _buildContent(t, c)),
                if (_config.dimLevel > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        color: Colors.black.withValues(alpha: _config.dimLevel),
                      ),
                    ),
                  ),
                ValueListenableBuilder<bool>(
                  valueListenable: _menuVisible,
                  builder: (BuildContext context, bool visible, _) =>
                      _buildMenu(c, visible),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildContent(ReaderTheme t, ReadingController c) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Size contentSize = Size(
            constraints.maxWidth - kReaderPagePadding.horizontal,
            constraints.maxHeight -
                kReaderPagePadding.vertical -
                kReaderHeaderHeight -
                kReaderFooterHeight -
                kReaderContentSafety,
          );

          if (_config.flipType == FlipType.scrollVertical) {
            return VerticalReader(controller: c, onTapToggleMenu: _toggleMenu);
          }

          // 传入“实际渲染解析出的样式与地区”：分页度量必须与屏幕渲染完全同源
          // （含主题字体、CJK 地区回退），否则换行行数不同会导致末行被裁切。
          final TextStyle base = DefaultTextStyle.of(context).style;
          c.updateViewport(
            contentSize,
            MediaQuery.of(context).textScaler,
            bodyStyle: base.merge(_config.textStyle),
            headingStyle: base.merge(_config.headingStyle),
            textLocale: Localizations.maybeLocaleOf(context),
          );

          // 页眉（章节/书名）与页脚（页码/进度）都在各页内，随翻页/滚动一起移动。
          return Semantics(
            container: true,
            label: c.currentChapterTitle,
            value: '${(c.globalProgress * 100).toStringAsFixed(0)}%',
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapUp: (TapUpDetails d) => _handleTap(d, constraints.maxWidth),
              child: _buildReader(t, c),
            ),
          );
        },
      ),
    );
  }

  /// 依翻页方式选视图：平滑/覆盖→横向 PageView；仿真→卷曲视图；无动画→静态页。
  Widget _buildReader(ReaderTheme t, ReadingController c) {
    switch (_config.flipType) {
      case FlipType.slideHorizontal:
      case FlipType.cover:
        return HorizontalReader(controller: c, style: _config.flipType);
      case FlipType.simulation:
        // 仿真翻页用原始手势（无滚动通知），拖动开始时主动隐藏菜单
        return SimulationReader(
          controller: c,
          onFlipStart: () => _menuVisible.value = false,
        );
      case FlipType.none:
      case FlipType.scrollVertical:
        return _buildStaticPage(t, c);
    }
  }

  Widget _buildStaticPage(ReaderTheme t, ReadingController c) {
    if (c.pages.isEmpty) {
      final int idx = c.chapterIndex;
      return ReaderStatusPage(
        theme: t,
        error: c.hasError(idx),
        onRetry: () => c.retry(idx),
      );
    }
    final int i = c.pageIndex;
    return ReaderPageContent(
      theme: t,
      config: _config,
      bookTitle: c.manifest.title,
      chapterTitle: c.currentChapterTitle,
      page: (i >= 0 && i < c.pages.length) ? c.pages[i] : const <ReaderBlock>[],
      isChapterHead: i == 0,
      chapterIndex: c.chapterIndex,
      chapterCount: c.chapterCount,
      pageIndex: i,
      pageCount: c.pages.length,
      progress: c.globalProgress,
    );
  }

  Widget _buildMenu(ReadingController c, bool visible) {
    return ReaderMenu(
      visible: visible,
      bookTitle: c.manifest.title,
      chapterTitle: c.currentChapterTitle,
      chapterIndex: c.chapterIndex,
      chapterCount: c.chapterCount,
      progress: c.globalProgress,
      config: _config,
      bookmarked: _isBookmarked,
      onToggleBookmark: _toggleBookmark,
      onBack: _close,
      onOpenCatalog: _openCatalog,
      onPrevChapter: () => c.loadChapter(c.chapterIndex - 1),
      onNextChapter: () => c.loadChapter(c.chapterIndex + 1),
      onSeekChapter: c.loadChapter,
      onRequestClose: () => _menuVisible.value = false,
    );
  }
}
