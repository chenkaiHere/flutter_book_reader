import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controller/reading_controller.dart';
import 'paginator.dart';
import 'progress/reader_progress_store.dart';
import 'reader_config.dart';
import 'reader_labels.dart';
import 'reader_theme.dart';
import 'source/book_source.dart';
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
    this.labels = const ReaderLabels(),
    this.startChapter,
    this.onChapterChanged,
    this.onPositionChanged,
    this.onClose,
  });

  /// 书籍数据源
  final BookSource source;

  /// 阅读设置；为空时使用全局单例 [ReaderConfig.instance]
  final ReaderConfig? config;

  /// 阅读进度存储；默认不持久化
  final ReaderProgressStore progressStore;

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

  @override
  State<BookReader> createState() => _BookReaderState();
}

class _BookReaderState extends State<BookReader> with WidgetsBindingObserver {
  ReadingController? _controller;
  Object? _error;
  int _lastChapter = -1;
  Timer? _saveTimer;

  final ValueNotifier<bool> _menuVisible = ValueNotifier<bool>(false);

  ReaderConfig get _config => widget.config ?? ReaderConfig.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // 全屏沉浸：进入阅读页即隐藏系统状态栏与导航栏，并在唤起菜单时保持隐藏——
    // 避免状态栏出现时把正文往下顶，正文始终铺满整屏。
    _enterImmersive();
    _init();
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

  Future<void> _openCatalog() async {
    final ReadingController c = _controller!;
    _menuVisible.value = false;
    final int? picked = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _config.theme.paperColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ReaderLabelsScope(
        labels: widget.labels,
        child: FractionallySizedBox(
          heightFactor: 0.85,
          child: CatalogSheet(
            bookTitle: c.manifest.title,
            chapterTitles: c.manifest.chapterTitles,
            currentIndex: c.chapterIndex,
            theme: _config.theme,
          ),
        ),
      ),
    );
    if (picked != null && picked != c.chapterIndex) {
      c.loadChapter(picked);
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
    return ReaderLabelsScope(
      labels: widget.labels,
      child: _buildScaffold(),
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
            body: Stack(
              children: <Widget>[
                // 正文始终可交互；菜单唤起时一旦开始滑动（用户拖动），立即隐藏菜单，
                // 让翻页/滚动照常进行。菜单自身的章节滑杆不属于此监听，不受影响。
                Positioned.fill(
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (ScrollNotification n) {
                      if (_menuVisible.value &&
                          n is ScrollStartNotification &&
                          n.dragDetails != null) {
                        _menuVisible.value = false;
                      }
                      return false;
                    },
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

          c.updateViewport(contentSize, MediaQuery.of(context).textScaler);

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
      onBack: _close,
      onOpenCatalog: _openCatalog,
      onPrevChapter: () => c.loadChapter(c.chapterIndex - 1),
      onNextChapter: () => c.loadChapter(c.chapterIndex + 1),
      onSeekChapter: c.loadChapter,
      onRequestClose: () => _menuVisible.value = false,
    );
  }
}
