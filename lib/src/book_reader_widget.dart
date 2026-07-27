import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'battery.dart';
import 'book_reader_controller.dart';
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
import 'title_page.dart';
import 'underline/reader_underline_store.dart';
import 'views/horizontal_reader.dart';
import 'views/simulation_reader.dart';
import 'views/vertical_reader.dart';
import 'widgets/battery_indicator.dart';
import 'widgets/catalog_sheet.dart';
import 'widgets/loading_page.dart';
import 'widgets/page_frame.dart';
import 'widgets/reader_menu.dart';

part 'book_reader/immersive_system_ui.dart';
part 'book_reader/read_along_highlight.dart';
part 'book_reader/notes_manager.dart';

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
    this.controller,
    this.titlePageBuilder,
    this.battery,
    this.showSystemBarsWithMenu = true,
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

  /// 对外阅读控制器：命令式驱动翻页 / 切章、读取当前页文本（听书等场景）。
  final BookReaderController? controller;

  /// 扉页构建器（第一章正文之前的宣传页）。为 null（默认）则不显示扉页。
  /// **样式完全由业务方定义**：回调返回整页 Widget，并带上当前 [ReaderTheme]
  /// 便于贴合日/夜主题，见 [ReaderTitlePageBuilder]。
  final ReaderTitlePageBuilder? titlePageBuilder;

  /// 右下角电量：由业务方注入（如用 `battery_plus` 采集）。为 null（默认）或其值为 null
  /// 时不显示电量。用 [ValueListenable] 便于电量变化只重绘页脚、不触发正文重排。
  final ValueListenable<ReaderBatteryInfo?>? battery;

  /// 唤起菜单时是否显示系统状态栏 / 底部导航栏（默认开启）。
  ///
  /// true：菜单出现时系统栏一并出现（与多数阅读 App 一致），收起菜单后回到全屏沉浸。
  /// false：始终全屏沉浸，唤起菜单也不显示系统栏（正文永远铺满整屏）。
  final bool showSystemBarsWithMenu;

  /// 是否启用「长按选中正文」功能（默认开启）。
  final bool enableTextSelection;

  @override
  State<BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader>
    with
        WidgetsBindingObserver,
        _ImmersiveSystemUi,
        _ReadAlongHighlight,
        _ReaderNotesManager {
  @override
  ReadingController? _controller;
  Object? _error;
  int _lastChapter = -1;
  Timer? _saveTimer;

  @override
  final ValueNotifier<bool> _menuVisible = ValueNotifier<bool>(false);

  ReaderConfig get _config => widget.config ?? ReaderConfig.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 全屏沉浸：进入阅读页即隐藏系统状态栏与导航栏，并在唤起菜单时保持隐藏——
    // 避免状态栏出现时把正文往下顶，正文始终铺满整屏。
    _enterImmersive();
    widget.commentsRefresh?.addListener(_reloadComments);
    _menuVisible.addListener(_syncMenuToController);
    _init();
  }

  void _syncMenuToController() {
    widget.controller?.setMenuVisible(_menuVisible.value);
    // 菜单显隐时切换系统栏：菜单出现→显示状态栏/导航栏，收起→回到沉浸。
    _enterImmersive();
  }

  @override
  void didUpdateWidget(BookReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.commentsRefresh, widget.commentsRefresh)) {
      oldWidget.commentsRefresh?.removeListener(_reloadComments);
      widget.commentsRefresh?.addListener(_reloadComments);
    }
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller?.attach(null);
      oldWidget.controller?.bindMenuHider(null);
      oldWidget.controller?.bindReadingMarker(null, null);
      oldWidget.controller?.bindBookmark(null, null);
      widget.controller?.attach(_controller);
      widget.controller?.bindMenuHider(() => _menuVisible.value = false);
      widget.controller?.bindReadingMarker(_markReading, _clearReadingMark);
      widget.controller?.bindBookmark(_toggleBookmark, () => _isBookmarked);
      widget.controller?.setMenuVisible(_menuVisible.value);
    }
    if (!identical(oldWidget.titlePageBuilder, widget.titlePageBuilder)) {
      final ReadingController? c = _controller;
      if (c != null) {
        c.titlePageBuilder = widget.titlePageBuilder;
        if (widget.titlePageBuilder == null) c.onTitlePage = false;
      }
    }
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
      controller.titlePageBuilder = widget.titlePageBuilder;
      // 从全书开头（第 0 章、偏移 0）打开时先展示扉页；从书中续读则直接进正文。
      controller.onTitlePage =
          widget.titlePageBuilder != null && start == 0 && offset == 0;
      _lastChapter = controller.chapterIndex;
      controller.addListener(_onControllerChanged);
      widget.controller?.attach(controller);
      widget.controller?.bindMenuHider(() => _menuVisible.value = false);
      widget.controller?.bindReadingMarker(_markReading, _clearReadingMark);
      widget.controller?.bindBookmark(_toggleBookmark, () => _isBookmarked);
      widget.controller?.setMenuVisible(_menuVisible.value);
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
    widget.controller?.notifyPositionChanged();
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
    _menuVisible.removeListener(_syncMenuToController);
    widget.controller?.bindMenuHider(null);
    widget.controller?.bindReadingMarker(null, null);
    widget.controller?.bindBookmark(null, null);
    widget.controller?.attach(null);
    _saveTimer?.cancel();
    _flushSave();
    _restoreSystemUiOnExit();
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
                  onDeleteBookmark: _deleteBookmark,
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
          child: ReaderReadingScope(
            chapterIndex: _readCh,
            start: _readStart,
            end: _readEnd,
            child: ReaderLabelsScope(
              labels: widget.labels,
              child: ReaderBatteryScope(
                battery: widget.battery,
                child: _buildScaffold(),
              ),
            ),
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
                // 菜单唤起时用 AbsorbPointer 吸收正文的所有指针：正文彻底收不到手势，
                // 因此点击 / 滑动都不会翻页；关闭菜单由上层 ReaderMenu 的遮罩负责
                // （点击或拖动都只“先关闭菜单”）。菜单关闭后正文才恢复可交互。
                Positioned.fill(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: _menuVisible,
                    builder: (BuildContext context, bool visible, Widget? child) =>
                        AbsorbPointer(absorbing: visible, child: child),
                    child: _buildContent(t, c),
                  ),
                ),
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
    // 正文高度不吃上/下系统栏内边距：否则菜单唤起时系统状态栏/导航栏出现会缩小正文区
    // 触发重新分页，关闭菜单又变回 —— 令第 2 页及以后的位置在重排后落到相邻页，看起来
    // 像“翻了一页”。系统栏出现时本就被菜单顶/底栏盖住，正文保持整屏高度即可。
    return SafeArea(
      top: false,
      bottom: false,
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
    if (c.onTitlePage && c.titlePageBuilder != null) {
      return c.titlePageBuilder!(context, t);
    }
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
      pageStartOffset: c.startOffsetOfPage(i),
      leadingParagraphStart: c.leadingParagraphStartIn(c.pages, i),
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
      onSettingsPanelChanged: (bool open) =>
          widget.controller?.setMenuPanelExpanded(open),
    );
  }
}
