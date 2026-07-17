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

  int startOffsetOfPage(int index) {
    int sum = 0;
    for (int i = 0; i < index && i < pages.length; i++) {
      sum += _pageLength(pages[i]);
    }
    return sum;
  }

  int pageIndexForOffset(int offset) {
    int sum = 0;
    for (int i = 0; i < pages.length; i++) {
      final int next = sum + _pageLength(pages[i]);
      if (offset < next) return i;
      sum = next;
    }
    return pages.isEmpty ? 0 : pages.length - 1;
  }

  /// 全书进度：章序 + 章内页占比。
  double progressFor(int chapterIdx, List<ReaderPage> pgs, int pageIdx) {
    final double p = pgs.isEmpty
        ? chapterIdx / chapterCount
        : (chapterIdx + (pageIdx + 1) / pgs.length) / chapterCount;
    return p.clamp(0, 1);
  }
}
