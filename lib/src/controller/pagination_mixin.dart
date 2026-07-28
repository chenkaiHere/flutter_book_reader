import 'package:flutter/widgets.dart';

import '../paginator.dart';
import '../reader_config.dart';
import 'chapter_content_mixin.dart';
import 'reader_controller_base.dart';

/// 分页能力：把整章正文按当前排版切分为页，并在布局阶段维护当前章分页。
mixin PaginationMixin on ReaderControllerBase, ChapterContentMixin {
  static final RegExp _leadingIndent = RegExp(r'^[　\s]+');

  /// 分页与渲染共用的正文样式（优先用实际渲染解析出的样式，回退到 config）。
  TextStyle get _bodyStyle => paintTextStyle ?? config.textStyle;
  TextStyle get _headingStyle => paintHeadingStyle ?? config.headingStyle;

  String _sizeSig(Size s) =>
      '${s.width.toInt()}x${s.height.toInt()}|${config.fontSize}|${config.lineHeight}'
      // 纳入系统字体缩放、字体与排版参数，任一变化才会失效重排
      '|${textScaler.scale(100).round()}|${config.fontFamily}'
      '|${config.firstLineIndent}|${config.paragraphSpacing}|${config.justify}'
      // 纳入实际渲染字体与地区：主题字体 / CJK 回退不同会改变换行行数
      '|${_bodyStyle.fontFamily}|${_bodyStyle.fontFamilyFallback}|$locale';

  /// 把整章正文拆成「干净」的段落：按换行切分、去掉数据自带的行首缩进、丢弃空行。
  /// 缩进与段距一律由阅读器统一施加，避免排版耦合到数据。
  List<String> _paragraphsOf(String body) => body
      .split('\n')
      .map((String l) => l.replaceFirst(_leadingIndent, '').trimRight())
      .where((String l) => l.isNotEmpty)
      .toList(growable: false);

  /// 整章按段落转成文本块（不分页，供纵向连续滚动模式渲染），排版与分页一致。
  ReaderPage chapterBlocks(String body) => <ReaderBlock>[
        for (final String p in _paragraphsOf(body))
          ReaderBlock(text: config.indent + p, isParagraphStart: true),
      ];

  /// 取某章分页结果；正文未加载时返回 null 并触发加载。
  List<ReaderPage>? pagesFor(int index) {
    final String? body = bodyOf(index);
    if (body == null) {
      ensureLoaded(index);
      return null;
    }
    final String key = '${_sizeSig(contentSize)}|$index';
    return pageCache.putIfAbsent(
      key,
      () => Paginator.paginate(
        paragraphs: _paragraphsOf(body),
        style: _bodyStyle,
        size: contentSize,
        textScaler: textScaler,
        locale: locale,
        indent: config.indent,
        paragraphSpacing: config.paragraphSpacing,
        textAlign: config.textAlign,
        strutStyle: config.strut,
        // 首页为章首大标题预留高度（与 ReaderPageFrame 的渲染保持一致）
        firstPageReserve: headingReserveFor(index),
      ),
    );
  }

  /// 章首大标题在首页占用的高度（含上下间距），供分页预留与视图渲染共用基准。
  double headingReserveFor(int index) {
    if (contentSize.width <= 0) return 0;
    final double h = Paginator.measureHeight(
      chapterTitleAt(index),
      _headingStyle,
      contentSize.width,
      textScaler: textScaler,
      locale: locale,
    );
    return kReaderHeadingGapTop + h + kReaderHeadingGapBottom;
  }

  /// 布局阶段调用：更新可用区域并按需重排当前章（在 build 期间调用，不通知）。
  ///
  /// [bodyStyle]/[headingStyle]/[textLocale] 为实际渲染解析出的样式与地区，
  /// 传入后分页度量与屏幕渲染口径完全一致，杜绝换行行数不符导致的末行裁切。
  void updateViewport(
    Size size,
    TextScaler ts, {
    TextStyle? bodyStyle,
    TextStyle? headingStyle,
    Locale? textLocale,
  }) {
    contentSize = size;
    textScaler = ts;
    paintTextStyle = bodyStyle;
    paintHeadingStyle = headingStyle;
    locale = textLocale;
    prefetchAround(chapterIndex);

    final List<ReaderPage>? current = pagesFor(chapterIndex);
    if (current == null) {
      pages = const <ReaderPage>[];
      signature = '';
      return;
    }
    final String sig = '${_sizeSig(size)}|$chapterIndex';
    if (sig == signature) return;

    pages = current;
    signature = sig;
    if (pendingAtEnd) {
      pageIndex = pages.isEmpty ? 0 : pages.length - 1;
      pendingAtEnd = false;
    } else {
      pageIndex = pageIndexForOffset(charOffset).clamp(0, pages.length - 1);
    }
    // 未解锁付费章只放行首页：兜底钳到 0，避免 pageIndex 落在被隐藏的后续页。
    if (currentChapterLocked) pageIndex = 0;
    charOffset = startOffsetOfPage(pageIndex);
  }

  /// 一页的字符长度（各块文本长度之和，含缩进，仅用于内部定位）。
  int _pageLength(ReaderPage page) {
    int sum = 0;
    for (final ReaderBlock b in page) {
      sum += b.length;
    }
    return sum;
  }

  /// 每份分页结果的「页起始偏移前缀和」缓存，按 [pgs] 列表标识缓存。
  ///
  /// `offs[i]` = 第 i 页首字符的章内偏移，`offs[pgs.length]` = 全章总长。分页结果一旦
  /// 产生便不可变、且在 [pageCache] 中稳定复用，故用 [Expando] 挂在其上——列表被
  /// 淘汰时缓存随之回收，无需手动清理。把逐页 O(页数×块) 累加摊平为 O(1) 查表。
  final Expando<List<int>> _pageOffsets = Expando<List<int>>();

  List<int> _offsetsOf(List<ReaderPage> pgs) {
    final List<int>? cached = _pageOffsets[pgs];
    if (cached != null) return cached;
    final List<int> offs = List<int>.filled(pgs.length + 1, 0);
    int sum = 0;
    for (int i = 0; i < pgs.length; i++) {
      offs[i] = sum;
      sum += _pageLength(pgs[i]);
    }
    offs[pgs.length] = sum;
    _pageOffsets[pgs] = offs;
    return offs;
  }

  /// 当前章可导航的页数：未解锁付费章只放行首页（1），其余为实际页数。
  int get visiblePageCount => currentChapterLocked ? 1 : pages.length;

  int startOffsetOfPage(int index) => startOffsetOfPageIn(pages, index);

  /// 给定任意章节的 [pgs]，计算第 [index] 页首字符的章内偏移（划线/书签锚点用）。
  int startOffsetOfPageIn(List<ReaderPage> pgs, int index) {
    if (index <= 0 || pgs.isEmpty) return 0;
    final List<int> offs = _offsetsOf(pgs);
    return index < offs.length ? offs[index] : offs[offs.length - 1];
  }

  /// 若第 [index] 页以「某段的延续块」开头（该段起始落在更早的页），回溯计算该段
  /// 真实起始的章内偏移；否则即本页起始偏移。段评角标跨页时据此统计整段评论数。
  int leadingParagraphStartIn(List<ReaderPage> pgs, int index) {
    if (index < 0 || index >= pgs.length) return 0;
    final ReaderPage page = pgs[index];
    int start = startOffsetOfPageIn(pgs, index);
    if (page.isEmpty || page.first.isParagraphStart) return start;
    for (int p = index - 1; p >= 0; p--) {
      final ReaderPage prev = pgs[p];
      for (int j = prev.length - 1; j >= 0; j--) {
        start -= prev[j].length;
        if (prev[j].isParagraphStart) return start;
      }
    }
    return start;
  }

  int pageIndexForOffset(int offset) {
    if (pages.isEmpty) return 0;
    final List<int> offs = _offsetsOf(pages);
    for (int i = 0; i < pages.length; i++) {
      if (offset < offs[i + 1]) return i;
    }
    return pages.length - 1;
  }

  /// 全书进度：章序 + 章内页占比。
  double progressFor(int chapterIdx, List<ReaderPage> pgs, int pageIdx) {
    final double p = pgs.isEmpty
        ? chapterIdx / chapterCount
        : (chapterIdx + (pageIdx + 1) / pgs.length) / chapterCount;
    return p.clamp(0, 1);
  }
}
