import 'package:flutter/foundation.dart';

import 'controller/reading_controller.dart';
import 'paginator.dart';
import 'progress/reader_progress_store.dart';

/// 对外阅读控制器：宿主用它命令式驱动翻页 / 切章，并读取当前页文本 / 位置状态。
///
/// 典型用途是「听书」——逐页取 [currentPageText] 交给 TTS 朗读，读完调用 [nextPage]，
/// 到 [isAtBookEnd] 即停止（章末会自动进入下一章）。
///
/// 用法：创建一个实例传给 `BookReader(controller: ...)`，阅读器就绪后（[isReady]）即可调用。
/// 它是一个 [ChangeNotifier]，翻页 / 切章时会通知监听者，便于同步外部 UI（如播放条）。
class BookReaderController extends ChangeNotifier {
  ReadingController? _rc;
  VoidCallback? _hideMenu;
  void Function(int chapterIndex, String sentence)? _markReading;
  VoidCallback? _clearReading;
  VoidCallback? _toggleBookmarkFn;
  bool Function()? _isBookmarkedFn;
  bool _menuVisible = false;
  bool _menuPanelExpanded = false;
  bool _disposed = false;

  /// 阅读器是否已就绪（正文已分页，可安全导航 / 读取文本）。
  bool get isReady => _rc != null && _rc!.pages.isNotEmpty;

  /// 阅读器菜单（顶/底栏）当前是否可见。宿主可据此让自己的浮层（如听书入口）
  /// 跟随菜单显隐。
  bool get isMenuVisible => _menuVisible;

  /// 底部设置面板当前是否展开（点「设置」后弹出的较高面板）。宿主可据此在其展开时
  /// 让自己的浮层让位 / 隐藏，避免被更高的面板遮挡区冲突。
  bool get isMenuPanelExpanded => _menuPanelExpanded;

  /// 当前章序号（从 0 起）。
  int get chapterIndex => _rc?.chapterIndex ?? 0;

  /// 全书章节数。
  int get chapterCount => _rc?.chapterCount ?? 0;

  /// 当前章标题。
  String get currentChapterTitle => _rc?.currentChapterTitle ?? '';

  /// 当前页序号（章内，从 0 起）。
  int get pageIndex => _rc?.pageIndex ?? 0;

  /// 当前章总页数。
  int get pageCount => _rc?.pages.length ?? 0;

  /// 当前页纯文本（各文本块以换行拼接），供 TTS 朗读等使用；未就绪时为空串。
  String get currentPageText {
    final ReadingController? rc = _rc;
    if (rc == null || rc.pages.isEmpty) return '';
    final int i = rc.pageIndex.clamp(0, rc.pages.length - 1);
    return rc.pages[i].map((ReaderBlock b) => b.text).join('\n');
  }

  /// 是否已到全书最后一页（听书循环据此停止）。
  bool get isAtBookEnd {
    final ReadingController? rc = _rc;
    if (rc == null) return false;
    return !rc.hasNext &&
        (rc.pages.isEmpty || rc.pageIndex >= rc.pages.length - 1);
  }

  /// 翻到下一页；已在章末则自动进入下一章（到全书末尾则不动）。
  void nextPage() => _rc?.nextPage();

  /// 翻到上一页；已在章首则自动进入上一章末页。
  void previousPage() => _rc?.prevPage();

  /// 当前阅读位置（章 + 章内字符偏移）；未就绪为 null。
  ReadingPosition? get position => _rc?.position;

  /// 跳转到某章（章首）。
  void goToChapter(int index) => _rc?.loadChapter(index);

  /// 跳转到指定位置（章 + 章内偏移），如跳到某条书签 / 划线处。
  void goToPosition(ReadingPosition pos) =>
      _rc?.loadChapter(pos.chapterIndex, charOffset: pos.charOffset);

  /// 收起阅读器菜单（顶/底栏）。宿主进入听书等沉浸态时可调用。
  void closeMenu() => _hideMenu?.call();

  /// 跟读高亮：在指定章的正文里定位 [sentence] 并高亮，同时自动翻到它所在页。
  /// 听书时逐句调用即可实现「读到哪高亮到哪、跨页自动翻」。
  void markReading(int chapterIndex, String sentence) =>
      _markReading?.call(chapterIndex, sentence);

  /// 清除跟读高亮。
  void clearReading() => _clearReading?.call();

  /// 当前页是否已加书签。翻页 / 切章或书签变化时本控制器会通知，宿主可据此刷新自定义 UI。
  bool get isCurrentPageBookmarked => _isBookmarkedFn?.call() ?? false;

  /// 编程式加 / 删当前页书签（等价于点顶栏书签按钮）。切换后会通知监听者。
  void toggleBookmark() => _toggleBookmarkFn?.call();

  // —————— 以下由 BookReader 内部调用（@internal），业务方请勿使用 ——————

  /// 绑定 / 解绑内部控制器（阅读器就绪或销毁时由 BookReader 调用）。
  ///
  /// 宿主可能在 BookReader 卸载前后释放本控制器，两者先后有竞态；已释放则安全忽略。
  @internal
  void attach(ReadingController? rc) {
    if (_disposed) return;
    _rc = rc;
    notifyListeners();
  }

  /// 由 BookReader 注入「收起菜单」的具体实现。
  @internal
  void bindMenuHider(VoidCallback? hide) => _hideMenu = hide;

  /// 由 BookReader 注入跟读高亮的具体实现。
  @internal
  void bindReadingMarker(
    void Function(int chapterIndex, String sentence)? mark,
    VoidCallback? clear,
  ) {
    _markReading = mark;
    _clearReading = clear;
  }

  /// 由 BookReader 注入书签切换 / 状态查询的具体实现。
  @internal
  void bindBookmark(VoidCallback? toggle, bool Function()? isBookmarked) {
    _toggleBookmarkFn = toggle;
    _isBookmarkedFn = isBookmarked;
  }

  /// 阅读器位置（翻页 / 切章）变化时转发一次通知，便于外部 UI 同步（BookReader 调用）。
  @internal
  void notifyPositionChanged() {
    if (_disposed) return;
    notifyListeners();
  }

  /// 菜单显隐变化时由 BookReader 调用。
  @internal
  void setMenuVisible(bool visible) {
    if (_disposed || _menuVisible == visible) return;
    _menuVisible = visible;
    notifyListeners();
  }

  /// 设置面板展开 / 收起时由 BookReader 调用。
  @internal
  void setMenuPanelExpanded(bool expanded) {
    if (_disposed || _menuPanelExpanded == expanded) return;
    _menuPanelExpanded = expanded;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _rc = null;
    _hideMenu = null;
    _markReading = null;
    _clearReading = null;
    _toggleBookmarkFn = null;
    _isBookmarkedFn = null;
    super.dispose();
  }
}
