import 'package:flutter/material.dart';

/// 页内文本块：一个段落，或一个段落被跨页拆开后的一部分。
class ReaderBlock {
  const ReaderBlock({required this.text, required this.isParagraphStart});

  /// 用于测量与渲染的文本（段落起始块已含首行缩进）。
  final String text;

  /// 是否为某段的起始块（渲染时其上方需要加段间距）。
  final bool isParagraphStart;

  int get length => text.length;
}

/// 一页 = 若干文本块（跨页的段落会被拆成多块）。
typedef ReaderPage = List<ReaderBlock>;

/// 段落感知的分页引擎。
///
/// 排版由阅读器掌控（首行缩进、段间距、两端对齐），而非依赖数据预格式化：
/// 逐段用 [TextPainter] 测量、按可用高度贪心填充、必要时按行把段落拆到下一页。
class Paginator {
  const Paginator._();

  static List<ReaderPage> paginate({
    required List<String> paragraphs,
    required TextStyle style,
    required Size size,
    TextScaler textScaler = TextScaler.noScaling,
    String indent = '　　',
    double paragraphSpacing = 0,
    TextAlign textAlign = TextAlign.start,
    double firstPageReserve = 0,
  }) {
    final double pageHeight = size.height;
    if (size.width <= 0 || pageHeight <= 0 || paragraphs.isEmpty) {
      return <ReaderPage>[
        <ReaderBlock>[
          for (final String p in paragraphs)
            ReaderBlock(text: indent + p, isParagraphStart: true),
        ],
      ];
    }

    final List<ReaderPage> pages = <ReaderPage>[];
    ReaderPage current = <ReaderBlock>[];
    // 首页预留章首大标题的高度（仅第一页；flushPage 后归零，故只影响首页）。
    double used = firstPageReserve.clamp(0, pageHeight * 0.6);

    void flushPage() {
      if (current.isNotEmpty) {
        pages.add(current);
        current = <ReaderBlock>[];
        used = 0;
      }
    }

    for (final String para in paragraphs) {
      final String text = indent + para;
      final TextPainter painter = _painter(text, style, textScaler, textAlign)
        ..layout(maxWidth: size.width);
      final List<LineMetrics> lines = painter.computeLineMetrics();
      if (lines.isEmpty) {
        painter.dispose();
        continue;
      }

      // 快路径：整段能放进本页剩余空间就整段放入（高度即实际渲染高度，精确）。
      final double wholeGap = current.isNotEmpty ? paragraphSpacing : 0;
      if (used + wholeGap + painter.height <= pageHeight) {
        current.add(ReaderBlock(text: text, isParagraphStart: true));
        used += wholeGap + painter.height;
        painter.dispose();
        continue;
      }

      // 慢路径：段落跨页，按行拆分。每个候选片段用其子串实测高度，
      // 与 Text 组件的实际排布一致，避免累积误差导致溢出。
      int line = 0;
      bool paragraphStart = true;
      while (line < lines.length) {
        final double gap =
            (paragraphStart && current.isNotEmpty) ? paragraphSpacing : 0;
        final int startOffset = _offsetAtLineTop(
          painter,
          lines[line].baseline - lines[line].ascent,
        );

        int lastFit = -1;
        int lastEnd = startOffset;
        double lastHeight = 0;
        for (int j = line; j < lines.length; j++) {
          final int end = (j + 1 < lines.length)
              ? _offsetAtLineTop(
                  painter,
                  lines[j + 1].baseline - lines[j + 1].ascent,
                )
              : text.length;
          final double h = _measureHeight(
            text.substring(startOffset, end),
            style,
            size.width,
            textScaler,
            textAlign,
          );
          if (used + gap + h <= pageHeight) {
            lastFit = j;
            lastEnd = end;
            lastHeight = h;
          } else {
            break;
          }
        }

        if (lastFit < line) {
          if (current.isNotEmpty) {
            flushPage();
            continue; // 换页后重试
          }
          // 空页仍放不下单行：强制放一行避免死循环
          lastFit = line;
          lastEnd = (line + 1 < lines.length)
              ? _offsetAtLineTop(
                  painter,
                  lines[line + 1].baseline - lines[line + 1].ascent,
                )
              : text.length;
          lastHeight = _measureHeight(
            text.substring(startOffset, lastEnd),
            style,
            size.width,
            textScaler,
            textAlign,
          );
        }

        final int safeEnd = _avoidSurrogateSplit(text, lastEnd);
        current.add(
          ReaderBlock(
            text: text.substring(startOffset, safeEnd),
            isParagraphStart: paragraphStart,
          ),
        );
        used += gap + lastHeight;
        line = lastFit + 1;
        paragraphStart = false;
        if (line < lines.length) flushPage();
      }

      painter.dispose();
    }

    flushPage();
    if (pages.isEmpty) pages.add(<ReaderBlock>[]);
    return pages;
  }

  static TextPainter _painter(
    String text,
    TextStyle style,
    TextScaler ts,
    TextAlign align,
  ) =>
      TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: align,
        textScaler: ts,
        maxLines: null,
      );

  /// 子串在给定宽度下的实际渲染高度（与 Text 组件排布一致）。
  static double _measureHeight(
    String text,
    TextStyle style,
    double width,
    TextScaler ts,
    TextAlign align,
  ) {
    final TextPainter p = _painter(text, style, ts, align)
      ..layout(maxWidth: width);
    final double h = p.height;
    p.dispose();
    return h;
  }

  /// 文本在给定宽度下的渲染高度（对外，用于度量章首标题等预留高度）。
  static double measureHeight(
    String text,
    TextStyle style,
    double width, {
    TextScaler textScaler = TextScaler.noScaling,
    TextAlign textAlign = TextAlign.start,
  }) =>
      _measureHeight(text, style, width, textScaler, textAlign);

  static int _offsetAtLineTop(TextPainter painter, double lineTop) =>
      painter.getPositionForOffset(Offset(0, lineTop + 1)).offset;

  /// 避免在 UTF-16 代理对中间切开（否则 emoji/增补平面字符会变成乱码）。
  static int _avoidSurrogateSplit(String text, int end) {
    if (end > 0 && end < text.length) {
      final int unit = text.codeUnitAt(end);
      if (unit >= 0xDC00 && unit <= 0xDFFF) return end - 1;
    }
    return end;
  }
}
