import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../paginator.dart';
import '../reader_config.dart';
import '../reader_labels.dart';
import '../reader_theme.dart';
import '../text_actions.dart';
import '../underline/reader_underline_store.dart';

/// 顶部小标题栏：章首显示书名、非章首显示章节标题；横向 / 纵向模式共用。
class ReaderHeaderBar extends StatelessWidget {
  const ReaderHeaderBar({super.key, required this.title, required this.theme});

  final String title;
  final ReaderTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kReaderHeaderHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: theme.subTextColor),
        ),
      ),
    );
  }
}

/// 底部信息栏：章号 / 页码 / 进度。作为固定 chrome，不随翻页滑动。
class ReaderFooterBar extends StatelessWidget {
  const ReaderFooterBar({
    super.key,
    required this.theme,
    required this.chapterIndex,
    required this.chapterCount,
    required this.pageIndex,
    required this.pageCount,
    required this.progress,
  });

  final ReaderTheme theme;
  final int chapterIndex;
  final int chapterCount;
  final int pageIndex;
  final int pageCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ReaderLabels labels = ReaderLabels.of(context);
    final TextStyle style = TextStyle(fontSize: 11, color: theme.subTextColor);
    return SizedBox(
      height: kReaderFooterHeight,
      child: Row(
        children: <Widget>[
          Text(labels.chapterProgress(chapterIndex, chapterCount),
              style: style),
          const Spacer(),
          if (pageCount > 0) Text('${pageIndex + 1}/$pageCount', style: style),
          const SizedBox(width: 12),
          Text('${(progress * 100).toStringAsFixed(1)}%', style: style),
        ],
      ),
    );
  }
}

/// 单页完整内容：顶部小标题 +（章首）大标题 + 正文 + 底部信息栏。
class ReaderPageContent extends StatelessWidget {
  const ReaderPageContent({
    super.key,
    required this.theme,
    required this.config,
    required this.bookTitle,
    required this.chapterTitle,
    required this.page,
    required this.isChapterHead,
    required this.chapterIndex,
    required this.chapterCount,
    required this.pageIndex,
    required this.pageCount,
    required this.progress,
    this.pageStartOffset = 0,
    this.padding = kReaderPagePadding,
  });

  final ReaderTheme theme;
  final ReaderConfig config;
  final String bookTitle;
  final String chapterTitle;
  final ReaderPage page;
  final bool isChapterHead;
  final int chapterIndex;
  final int chapterCount;
  final int pageIndex;
  final int pageCount;
  final double progress;

  /// 本页首字符在本章「块长度空间」中的起始偏移（划线锚定用）。
  final int pageStartOffset;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReaderHeaderBar(
            title: isChapterHead ? bookTitle : chapterTitle,
            theme: theme,
          ),
          if (isChapterHead) ...<Widget>[
            const SizedBox(height: kReaderHeadingGapTop),
            Text(chapterTitle, style: config.headingStyle),
            const SizedBox(height: kReaderHeadingGapBottom),
          ],
          Expanded(
            child: ReaderProse(
              page: page,
              config: config,
              bounded: true,
              chapterIndex: chapterIndex,
              chapterTitle: chapterTitle,
              pageStartOffset: pageStartOffset,
            ),
          ),
          ReaderFooterBar(
            theme: theme,
            chapterIndex: chapterIndex,
            chapterCount: chapterCount,
            pageIndex: pageIndex,
            pageCount: pageCount,
            progress: progress,
          ),
        ],
      ),
    );
  }
}

/// 按文本块渲染一页正文；支持长按选中（见 [ReaderSelectionScope]）。
///
/// 选中规则：长按某段落 —— 若该段 ≤ 2 行，选中整段；若 ≥ 3 行，选中手指所在行
/// 及其上下各一行（共 3 行）。选中后在其上方弹出「复制 / 划线 / 查询 / 分享」工具条。
class ReaderProse extends StatefulWidget {
  const ReaderProse({
    super.key,
    required this.page,
    required this.config,
    this.bounded = false,
    this.chapterIndex = 0,
    this.chapterTitle = '',
    this.pageStartOffset = 0,
  });

  final ReaderPage page;
  final ReaderConfig config;
  final bool bounded;

  /// 本页所属章节下标（划线锚定用）。
  final int chapterIndex;

  /// 本页所属章节标题（随选中回调传给业务方，便于据此构造 Comment 等）。
  final String chapterTitle;

  /// 本页首字符在本章「块长度空间」中的起始偏移（与书签同一套坐标）。
  final int pageStartOffset;

  @override
  State<ReaderProse> createState() => _ReaderProseState();
}

class _ReaderProseState extends State<ReaderProse> {
  static final RegExp _leadingIndent = RegExp(r'^[　\s]+');

  ReaderConfig get _config => widget.config;

  /// 选区端点：起点 / 终点各为「块下标 + 块内偏移」，可跨段落。
  /// 恒满足 (startBlock,startOff) ≤ (endBlock,endOff)；null 表示无选中。
  int? _startBlock;
  int _startOff = 0;
  int? _endBlock;
  int _endOff = 0;
  String _selText = '';

  /// 选中时缓存的缩进宽度（整页统一），供跨块纯文本换算。
  double _selIndentWidth = 0;

  /// 是否正在拖动手柄：拖动时隐藏气泡菜单，松手后再显示。
  bool _draggingHandle = false;

  /// 每个段落块的 key（用于取渲染盒做命中测试与工具条定位）。
  final Map<int, GlobalKey> _keys = <int, GlobalKey>{};

  OverlayEntry? _toolbar;

  @override
  void didUpdateWidget(ReaderProse old) {
    super.didUpdateWidget(old);
    // 页内容 / 排版变化（翻页、改字号、旋转、缩放重排）时，原选区锚定的渲染盒已失效，
    // 立即清除选中态，避免浮层读取「待布局」的 RenderParagraph 触发断言 / 错位。
    if (!identical(widget.page, old.page) ||
        widget.pageStartOffset != old.pageStartOffset ||
        widget.chapterIndex != old.chapterIndex) {
      if (_hasSel || _toolbar != null) {
        _removeToolbar();
        _draggingHandle = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() {
              _startBlock = null;
              _endBlock = null;
              _selText = '';
            });
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _removeToolbar();
    super.dispose();
  }

  void _removeToolbar() {
    _toolbar?.remove();
    _toolbar = null;
  }

  void _clearSelection() {
    _removeToolbar();
    _draggingHandle = false;
    if (mounted) {
      setState(() {
        _startBlock = null;
        _endBlock = null;
        _selText = '';
      });
    }
  }

  /// 结束手柄拖动：恢复气泡菜单显示。
  void _endHandleDrag() {
    if (!_draggingHandle) return;
    _draggingHandle = false;
    _toolbar?.markNeedsBuild();
  }

  bool get _hasSel => _startBlock != null && _endBlock != null;

  /// 块 i 内可选起点（段首块跳过缩进占位符 offset 0）。
  int _minBase(int i) => widget.page[i].isParagraphStart ? 1 : 0;

  /// 块 i 的选区在其内部的 [lo, hi)（不在选区内返回 null）。
  TextSelection? _localSel(int i) {
    if (!_hasSel || i < _startBlock! || i > _endBlock!) return null;
    final String plain = _plainForSpan(widget.page[i], _selIndentWidth);
    final int lo = i == _startBlock! ? _startOff : _minBase(i);
    final int hi = i == _endBlock! ? _endOff : plain.length;
    if (hi <= lo) return null;
    return TextSelection(baseOffset: lo, extentOffset: hi);
  }

  /// 汇总跨块选中文字（段落间以换行分隔、剔除缩进占位符）。
  String _computeSelText() {
    if (!_hasSel) return '';
    final StringBuffer sb = StringBuffer();
    for (int i = _startBlock!; i <= _endBlock!; i++) {
      final TextSelection? ls = _localSel(i);
      if (ls == null) continue;
      final String plain = _plainForSpan(widget.page[i], _selIndentWidth);
      final String part = plain.substring(ls.start, ls.end).replaceAll('￼', '');
      if (sb.isNotEmpty && widget.page[i].isParagraphStart) sb.write('\n');
      sb.write(part);
    }
    return sb.toString().trim();
  }

  /// 块 i 实际渲染的段落 RenderObject。用它（而非另建 [TextPainter]）做选区盒 /
  /// 光标 / 命中测算，保证与屏幕上真实排版（含 Web 字体回退、locale 影响）完全一致。
  RenderParagraph? _para(int i) {
    final RenderObject? ro = _keys[i]?.currentContext?.findRenderObject();
    return (ro is RenderParagraph && ro.hasSize) ? ro : null;
  }

  // ——————————— 章内偏移映射（划线用；与书签同一套「块长度空间」）———————————

  int get _indentLen => _config.indent.length;

  /// 块 i 首字符在本章的起始偏移（各块 text 长度含缩进，逐块累加）。
  int _blockChapterStart(int i) {
    int sum = widget.pageStartOffset;
    for (int j = 0; j < i && j < widget.page.length; j++) {
      sum += widget.page[j].length;
    }
    return sum;
  }

  /// 块 i 内「占位符空间」偏移 → 本章偏移。
  int _plainToChapter(int i, int plainOffset) {
    final ReaderBlock b = widget.page[i];
    final int bc = _blockChapterStart(i);
    if (b.isParagraphStart) {
      if (plainOffset <= 0) return bc;
      return bc + _indentLen + (plainOffset - 1);
    }
    return bc + plainOffset;
  }

  /// 本章偏移 → 块 i 内「占位符空间」偏移（clamp 到本块可视范围）。
  int _chapterToPlain(int i, int chapterOffset) {
    final ReaderBlock b = widget.page[i];
    final int bc = _blockChapterStart(i);
    final int t = chapterOffset - bc; // 块 text 空间偏移
    if (b.isParagraphStart) {
      final int bodyLen = b.length - _indentLen;
      final int plainLen = 1 + (bodyLen < 0 ? 0 : bodyLen);
      return (t - _indentLen + 1).clamp(1, plainLen);
    }
    return t.clamp(0, b.length);
  }

  /// 当前选区对应的本章 [start, end)；无选中返回 null。
  (int, int)? _selChapterRange() {
    if (!_hasSel) return null;
    final int s = _plainToChapter(_startBlock!, _startOff);
    final int e = _plainToChapter(_endBlock!, _endOff);
    return e > s ? (s, e) : null;
  }

  /// 与当前选区在本章相交的已有划线。
  List<Underline> _overlappingUnderlines() {
    final ReaderUnderlineScope? scope = ReaderUnderlineScope.of(context);
    final (int, int)? range = _selChapterRange();
    if (scope == null || range == null) return const <Underline>[];
    return scope.underlines
        .where((Underline u) =>
            u.overlaps(widget.chapterIndex, range.$1, range.$2))
        .toList();
  }

  /// 块 i 内需要绘制的划线区间（占位符空间），由本章划线与本块范围求交得到。
  List<TextSelection> _underlineRangesFor(int i) {
    final ReaderUnderlineScope? scope = ReaderUnderlineScope.of(context);
    if (scope == null || scope.underlines.isEmpty) {
      return const <TextSelection>[];
    }
    final int bc = _blockChapterStart(i);
    final int be = bc + widget.page[i].length;
    final List<TextSelection> res = <TextSelection>[];
    for (final Underline u in scope.underlines) {
      if (u.chapterIndex != widget.chapterIndex) continue;
      final int s = u.start.clamp(bc, be);
      final int e = u.end.clamp(bc, be);
      if (e <= s) continue;
      final int ps = _chapterToPlain(i, s);
      final int pe = _chapterToPlain(i, e);
      if (pe > ps) res.add(TextSelection(baseOffset: ps, extentOffset: pe));
    }
    if (res.length < 2) return res;
    // 合并重叠 / 相邻区间，避免多条划线在同一处叠画导致波浪线变粗。
    res.sort((TextSelection a, TextSelection b) => a.start.compareTo(b.start));
    final List<TextSelection> merged = <TextSelection>[res.first];
    for (int k = 1; k < res.length; k++) {
      final TextSelection cur = res[k];
      final TextSelection last = merged.last;
      if (cur.start <= last.end) {
        merged[merged.length - 1] = TextSelection(
          baseOffset: last.start,
          extentOffset: cur.end > last.end ? cur.end : last.end,
        );
      } else {
        merged.add(cur);
      }
    }
    return merged;
  }

  /// 划线颜色：与选中高亮同色系但更深（暗色主题下相应提亮以保证可见）。
  Color get _underlineColor {
    final ReaderTheme t = _config.theme;
    final HSLColor h = HSLColor.fromColor(t.selectionColor);
    final double sat = (h.saturation + 0.12).clamp(0.0, 1.0);
    final double light = t.isDark
        ? (h.lightness + 0.16).clamp(0.0, 1.0)
        : (h.lightness - 0.24).clamp(0.0, 1.0);
    return h.withSaturation(sat).withLightness(light).toColor();
  }

  double _measureIndent(String indent, TextStyle style, TextScaler scaler) {
    if (indent.isEmpty) return 0;
    final TextPainter tp = TextPainter(
      text: TextSpan(text: indent, style: style),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    final double w = tp.width;
    tp.dispose();
    return w;
  }

  /// 与渲染完全一致的 [InlineSpan]：段首用等宽占位块承载缩进。
  InlineSpan _spanFor(ReaderBlock block, double indentWidth) {
    if (!block.isParagraphStart) {
      return TextSpan(text: block.text, style: _config.textStyle);
    }
    final String body = block.text.replaceFirst(_leadingIndent, '');
    return TextSpan(
      style: _config.textStyle,
      children: <InlineSpan>[
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SizedBox(width: indentWidth),
        ),
        TextSpan(text: body),
      ],
    );
  }

  void _onLongPress(
    int blockIndex,
    ReaderBlock block,
    Offset globalPos,
    double indentWidth,
  ) {
    final RenderParagraph? rp = _para(blockIndex);
    if (rp == null) return;
    final Offset local = rp.globalToLocal(globalPos);
    final double width = rp.size.width;

    // 用真实渲染段落重建行度量（RenderParagraph 无 computeLineMetrics）：
    // 取整段选区盒、按 top 归并成行，保证与屏幕排版一致（Web 字体回退 / locale）。
    final int fullLen = _plainForSpan(block, indentWidth).length;
    final List<TextBox> allBoxes = rp.getBoxesForSelection(
        TextSelection(baseOffset: 0, extentOffset: fullLen));
    if (allBoxes.isEmpty) return;
    final List<double> tops = <double>[];
    final List<double> heights = <double>[];
    for (final TextBox b in allBoxes) {
      int line = -1;
      for (int k = 0; k < tops.length; k++) {
        if ((tops[k] - b.top).abs() < 1.0) {
          line = k;
          break;
        }
      }
      final double h = b.bottom - b.top;
      if (line < 0) {
        tops.add(b.top);
        heights.add(h);
      } else if (h > heights[line]) {
        heights[line] = h;
      }
    }
    final List<int> order = List<int>.generate(tops.length, (int x) => x)
      ..sort((int a, int b) => tops[a].compareTo(tops[b]));
    final List<double> lineTop = <double>[for (final int j in order) tops[j]];
    final List<double> lineH = <double>[for (final int j in order) heights[j]];
    final int n = lineTop.length;
    // 手指所在行。
    int finger = n - 1;
    for (int i = 0; i < n; i++) {
      final double bottom =
          (i + 1 < n) ? lineTop[i + 1] : (lineTop[i] + lineH[i]);
      if (local.dy < bottom) {
        finger = i;
        break;
      }
    }
    // 目标行范围：≤2 行选整段；≥3 行选手指行 ± 1（共 3 行）。
    final int startLine;
    final int endLine;
    if (n <= 2) {
      startLine = 0;
      endLine = n - 1;
    } else {
      startLine = (finger - 1).clamp(0, n - 3);
      endLine = startLine + 2;
    }
    final double midStart = lineTop[startLine] + lineH[startLine] / 2;
    final double midEnd = lineTop[endLine] + lineH[endLine] / 2;
    int startOff = rp.getPositionForOffset(Offset(-1, midStart)).offset;
    final int endOff =
        rp.getPositionForOffset(Offset(width + 4000, midEnd)).offset;
    // 段首的缩进占位符（偏移 0）不应被选中/高亮——从第一个真实字符开始。
    if (block.isParagraphStart && startOff == 0) startOff = 1;
    if (endOff <= startOff) return;

    final String plain = _plainForSpan(block, indentWidth);
    final int s = startOff.clamp(0, plain.length);
    final int e = endOff.clamp(0, plain.length);

    setState(() {
      _selIndentWidth = indentWidth;
      _startBlock = blockIndex;
      _startOff = s;
      _endBlock = blockIndex;
      _endOff = e;
      _selText = _computeSelText();
    });
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _showSelectionOverlay());
  }

  /// 与 [_spanFor] 对齐的纯文本：段首前置一个占位符（对应缩进 WidgetSpan）。
  String _plainForSpan(ReaderBlock block, double indentWidth) {
    if (!block.isParagraphStart) return block.text;
    final String body = block.text.replaceFirst(_leadingIndent, '');
    return '￼$body';
  }

  void _showSelectionOverlay() {
    _removeToolbar();
    if (!_hasSel) return;
    _toolbar = OverlayEntry(builder: _buildSelectionOverlay);
    Overlay.of(context).insert(_toolbar!);
  }

  /// 首个非空选区盒（跨块向后找）：某端点所在块切片为空时（起点被拖到段尾等），
  /// 仍能取到实际可见的选区盒，避免 anchor 为 null 导致整个浮层消失。
  (RenderParagraph, TextBox)? _firstSelBox() {
    if (!_hasSel) return null;
    for (int i = _startBlock!; i <= _endBlock!; i++) {
      final RenderParagraph? rp = _para(i);
      final TextSelection? ls = _localSel(i);
      if (rp == null || ls == null) continue;
      final List<TextBox> boxes = rp.getBoxesForSelection(ls);
      if (boxes.isNotEmpty) return (rp, boxes.first);
    }
    return null;
  }

  /// 末个非空选区盒（跨块向前找）。
  (RenderParagraph, TextBox)? _lastSelBox() {
    if (!_hasSel) return null;
    for (int i = _endBlock!; i >= _startBlock!; i--) {
      final RenderParagraph? rp = _para(i);
      final TextSelection? ls = _localSel(i);
      if (rp == null || ls == null) continue;
      final List<TextBox> boxes = rp.getBoxesForSelection(ls);
      if (boxes.isNotEmpty) return (rp, boxes.last);
    }
    return null;
  }

  /// 起点手柄的全局锚点（首字左边界的行顶）。返回 (行顶全局坐标, 行高)。
  (Offset, double)? _startAnchor() {
    final (RenderParagraph, TextBox)? r = _firstSelBox();
    if (r == null) return null;
    final (RenderParagraph rp, TextBox fb) = r;
    return (rp.localToGlobal(Offset(fb.left, fb.top)), fb.bottom - fb.top);
  }

  /// 终点手柄的全局锚点（末字右边界的行底）。返回 (行底全局坐标, 行高)。
  (Offset, double)? _endAnchor() {
    final (RenderParagraph, TextBox)? r = _lastSelBox();
    if (r == null) return null;
    final (RenderParagraph rp, TextBox lb) = r;
    return (rp.localToGlobal(Offset(lb.right, lb.bottom)), lb.bottom - lb.top);
  }

  /// 依据当前选区实时计算高亮盒的全局位置，绘制工具条 + 首尾可拖拽手柄。
  Widget _buildSelectionOverlay(BuildContext ctx) {
    final (Offset, double)? start = _startAnchor();
    final (Offset, double)? end = _endAnchor();
    if (start == null || end == null) return const SizedBox.shrink();

    final Offset startTop = start.$1; // 起点行顶
    final double startH = start.$2;
    final Offset endBottom = end.$1; // 终点行底
    final double endH = end.$2;

    final Color accent = _config.theme.accentColor;
    final MediaQueryData mq = MediaQuery.of(ctx);
    const double barH = 66;
    final double selTop = startTop.dy; // 起点行顶
    final double selBottom = endBottom.dy; // 终点行底
    final bool above = selTop - mq.padding.top > barH + 12;
    final double barTop = (above ? selTop - barH - 8 : selBottom + 8)
        .clamp(mq.padding.top + 4, mq.size.height - barH - 4);

    // 每个子节点都带稳定 key：手柄在重建时按 key 正确复用元素，拖动手势不被中断。
    return Stack(
      children: <Widget>[
        // 全屏遮罩：吞掉遮罩上的拖动手势，避免「带位移的点击」穿透到下层 PageView
        // 的水平拖动而偶发翻页；点击遮罩空白处取消选中。
        Positioned.fill(
          key: const ValueKey<String>('sel-barrier'),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _clearSelection,
            onHorizontalDragStart: (_) {},
            onVerticalDragStart: (_) {},
          ),
        ),
        // 起始手柄：点在上、竖线贴住首字左侧、覆盖起点所在行。
        _handle(
          key: const ValueKey<String>('sel-start'),
          center: Offset(startTop.dx, startTop.dy),
          height: startH,
          accent: accent,
          dotOnTop: true,
          isStart: true,
        ),
        // 结束手柄：竖线贴住末字右侧、点在下、覆盖终点所在行。
        _handle(
          key: const ValueKey<String>('sel-end'),
          center: Offset(endBottom.dx, endBottom.dy),
          height: endH,
          accent: accent,
          dotOnTop: false,
          isStart: false,
        ),
        // 气泡小菜单：拖动手柄时隐藏，松手后再显示。
        if (!_draggingHandle)
          Positioned(
            key: const ValueKey<String>('sel-toolbar'),
            left: 12,
            right: 12,
            top: barTop,
            // 同样吞掉气泡条上的拖动：手指在按钮上带位移时不会漏到下层翻页。
            child: Center(
              child: GestureDetector(
                onHorizontalDragStart: (_) {},
                onVerticalDragStart: (_) {},
                child: _selectionBar(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _handle({
    required Key key,
    required Offset center,
    required double height,
    required Color accent,
    required bool dotOnTop,
    required bool isStart,
  }) {
    const double dot = 12;
    const double touch = 22; // 透明触摸外扩，便于抓取
    const double bar = 2;
    // 竖线落在文字间的缝隙上：起点竖线整体在首字左侧、终点在末字右侧，
    // 不压到被选中的字（center.dx 为选区边界的接缝位置）。
    final double nudge = isStart ? -bar / 2 : bar / 2;
    // dotOnTop：竖线顶端(center 为线顶)向下延伸 height，圆点在其上方；
    // 否则：竖线底端(center 为线底)向上延伸，圆点在其下方。
    final double stackHeight = height + dot;
    final double topY = dotOnTop ? center.dy - dot : center.dy - height;
    return Positioned(
      key: key,
      left: center.dx - touch + nudge,
      top: topY - touch,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          _draggingHandle = true;
          _toolbar?.markNeedsBuild();
        },
        onPanUpdate: (DragUpdateDetails d) =>
            _dragHandle(isStart, d.globalPosition),
        onPanEnd: (_) => _endHandleDrag(),
        onPanCancel: _endHandleDrag,
        child: SizedBox(
          width: touch * 2,
          height: stackHeight + touch * 2,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (dotOnTop) _dotWidget(dot, accent),
                Container(width: bar, height: height, color: accent),
                if (!dotOnTop) _dotWidget(dot, accent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dotWidget(double size, Color accent) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      );

  /// (b1,o1) 是否严格早于 (b2,o2)。
  bool _before(int b1, int o1, int b2, int o2) =>
      b1 < b2 || (b1 == b2 && o1 < o2);

  void _dragHandle(bool isStart, Offset globalPos) {
    if (!_hasSel) return;
    // 手柄圆点在文字上/下方，把落点向文字内部偏移约半行，命中更准。
    final double bias = _config.fontSize * _config.lineHeight * 0.4;
    final Offset biased =
        Offset(globalPos.dx, globalPos.dy + (isStart ? bias : -bias));

    // 命中块：竖直落在哪个块内；落在块间空隙取竖直最近的块（支持跨段落）。
    int? hitBlock;
    RenderParagraph? hitRp;
    double bestGap = double.infinity;
    for (final int i in _keys.keys) {
      final RenderParagraph? rp = _para(i);
      if (rp == null) continue;
      final double top = rp.localToGlobal(Offset.zero).dy;
      final double bottom = top + rp.size.height;
      final double gap = biased.dy < top
          ? top - biased.dy
          : (biased.dy > bottom ? biased.dy - bottom : 0);
      if (gap < bestGap) {
        bestGap = gap;
        hitBlock = i;
        hitRp = rp;
      }
      if (gap == 0) break;
    }
    if (hitBlock == null || hitRp == null) return;

    final Offset local = hitRp.globalToLocal(biased);
    int off = hitRp.getPositionForOffset(local).offset;
    final int len =
        _plainForSpan(widget.page[hitBlock], _selIndentWidth).length;
    off = off.clamp(_minBase(hitBlock), len);

    int sb = _startBlock!, so = _startOff, eb = _endBlock!, eo = _endOff;
    if (isStart) {
      sb = hitBlock;
      so = off;
    } else {
      eb = hitBlock;
      eo = off;
    }
    // 归一化：保证起点严格早于终点（至少 1 个字符）。
    if (!_before(sb, so, eb, eo)) {
      if (isStart) {
        sb = eb;
        so = eo - 1;
        if (so < _minBase(eb)) return;
      } else {
        eb = sb;
        eo = so + 1;
        if (eo > _plainForSpan(widget.page[sb], _selIndentWidth).length) return;
      }
    }
    setState(() {
      _startBlock = sb;
      _startOff = so;
      _endBlock = eb;
      _endOff = eo;
      _selText = _computeSelText();
    });
    _toolbar?.markNeedsBuild();
  }

  Widget _selectionBar() {
    final ReaderLabels labels = ReaderLabels.of(context);
    final ReaderSelectionScope? scope = ReaderSelectionScope.of(context);
    final ReaderUnderlineScope? uScope = ReaderUnderlineScope.of(context);
    // 复制 / 评论 / 查询 / 分享：插件不做任何内部处理（不写剪贴板、不弹输入框），
    // 仅把选中详情（章号 + 章标题 + 章内区间 + 文字）回调给业务方，由其自行处理。
    void act(ReaderTextAction action) {
      final (int, int)? range = _selChapterRange();
      scope?.onAction?.call(
        action,
        ReaderSelection(
          chapterIndex: widget.chapterIndex,
          chapterTitle: widget.chapterTitle,
          start: range?.$1 ?? -1,
          end: range?.$2 ?? -1,
          text: _selText,
        ),
      );
      _clearSelection();
    }

    // 划线：始终可「划线」（给整段选区划线，含其中未划线的部分）；若选区与已有划线
    // 相交，再额外显示「删除划线」删掉相交的。未接入划线作用域时回退旧的 onAction。
    final List<Underline> overlapping =
        uScope == null ? const <Underline>[] : _overlappingUnderlines();
    final bool hasOverlap = overlapping.isNotEmpty;
    void onAddHighlight() {
      if (uScope == null) {
        act(ReaderTextAction.highlight);
        return;
      }
      final (int, int)? range = _selChapterRange();
      if (range != null) {
        uScope.onAdd(widget.chapterIndex, range.$1, range.$2, _selText);
      }
      _clearSelection();
    }

    void onRemoveHighlight() {
      uScope?.onRemove(overlapping);
      _clearSelection();
    }

    Widget item(IconData icon, String label, VoidCallback onTap) => InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(height: 5),
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.white)),
              ],
            ),
          ),
        );

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2A28),
          borderRadius: BorderRadius.circular(14),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            item(Icons.content_copy_rounded, labels.selectCopy,
                () => act(ReaderTextAction.copy)),
            item(Icons.border_color_outlined, labels.selectHighlight,
                onAddHighlight),
            item(Icons.mode_comment_outlined, labels.selectComment,
                () => act(ReaderTextAction.comment)),
            if (hasOverlap)
              item(Icons.format_color_reset_outlined,
                  labels.selectRemoveHighlight, onRemoveHighlight),
            item(Icons.search_rounded, labels.selectQuery,
                () => act(ReaderTextAction.query)),
            item(Icons.ios_share_rounded, labels.selectShare,
                () => act(ReaderTextAction.share)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextScaler scaler = MediaQuery.textScalerOf(context);
    final double indentWidth =
        _measureIndent(_config.indent, _config.textStyle, scaler);
    final bool selectable = ReaderSelectionScope.of(context)?.enabled ?? false;

    final List<Widget> children = <Widget>[];
    for (int i = 0; i < widget.page.length; i++) {
      final ReaderBlock block = widget.page[i];
      if (i > 0 && block.isParagraphStart) {
        children.add(SizedBox(height: _config.paragraphSpacing));
      }
      children.add(_paragraph(i, block, indentWidth, selectable));
    }
    final Column column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (!widget.bounded) return column;
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: column,
      ),
    );
  }

  Widget _paragraph(
    int i,
    ReaderBlock block,
    double indentWidth,
    bool selectable,
  ) {
    final Widget text = block.isParagraphStart
        ? Text.rich(
            _spanFor(block, indentWidth),
            textAlign: _config.textAlign,
            strutStyle: _config.strut,
          )
        : Text(
            block.text,
            style: _config.textStyle,
            textAlign: _config.textAlign,
            strutStyle: _config.strut,
          );

    final GlobalKey key = _keys.putIfAbsent(i, () => GlobalKey());
    final TextSelection? localSel = _localSel(i);
    final List<TextSelection> underlines = _underlineRangesFor(i);
    final Widget keyed = KeyedSubtree(key: key, child: text);
    final bool layered = localSel != null || underlines.isNotEmpty;
    final Widget content = layered
        ? Stack(
            children: <Widget>[
              if (localSel != null)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HighlightPainter(
                      paragraphKey: key,
                      selection: localSel,
                      color: _config.theme.selectionColor,
                    ),
                  ),
                ),
              if (underlines.isNotEmpty)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _UnderlinePainter(
                      paragraphKey: key,
                      ranges: underlines,
                      color: _underlineColor,
                    ),
                  ),
                ),
              keyed,
            ],
          )
        : keyed;

    // 未启用选择时仍渲染已有划线，只是不响应长按。
    if (!selectable) return content;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onLongPressStart: (LongPressStartDetails d) => _onLongPress(
        i,
        block,
        d.globalPosition,
        indentWidth,
      ),
      child: content,
    );
  }
}

/// 在段落文字后面绘制选区高亮块。
///
/// 直接取真实渲染段落（[RenderParagraph]）的选区盒，而非另建 [TextPainter]，
/// 从而与屏幕上的实际排版严格对齐（避免 Web 字体回退 / locale 导致的错位、缺字）。
class _HighlightPainter extends CustomPainter {
  _HighlightPainter({
    required this.paragraphKey,
    required this.selection,
    required this.color,
  });

  final GlobalKey paragraphKey;
  final TextSelection selection;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final RenderObject? ro = paragraphKey.currentContext?.findRenderObject();
    if (ro is! RenderParagraph || !ro.hasSize) return;
    final Paint paint = Paint()..color = color;
    for (final TextBox b in ro.getBoxesForSelection(selection)) {
      final RRect r = RRect.fromRectAndRadius(
        Rect.fromLTRB(b.left - 1, b.top, b.right + 1, b.bottom),
        const Radius.circular(3),
      );
      canvas.drawRRect(r, paint);
    }
  }

  @override
  bool shouldRepaint(_HighlightPainter old) =>
      old.selection != selection ||
      old.color != color ||
      old.paragraphKey != paragraphKey;
}

/// 在文字下方绘制持久「划线」波浪线。取真实渲染段落的选区盒，沿每个盒的底边画波浪。
class _UnderlinePainter extends CustomPainter {
  _UnderlinePainter({
    required this.paragraphKey,
    required this.ranges,
    required this.color,
  });

  final GlobalKey paragraphKey;
  final List<TextSelection> ranges;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final RenderObject? ro = paragraphKey.currentContext?.findRenderObject();
    if (ro is! RenderParagraph || !ro.hasSize) return;
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final TextSelection r in ranges) {
      for (final TextBox b in ro.getBoxesForSelection(r)) {
        _wave(canvas, b.left, b.right, b.bottom + 1.5, paint);
      }
    }
  }

  /// 在 [y] 处、[left,right] 区间画一条正弦波浪线。
  void _wave(Canvas canvas, double left, double right, double y, Paint paint) {
    const double period = 6; // 波长
    const double amp = 1.6; // 振幅
    final Path path = Path()..moveTo(left, y);
    double x = left;
    bool up = true;
    while (x < right) {
      final double nx = (x + period / 2).clamp(left, right);
      final double cx = x + period / 4;
      path.quadraticBezierTo(cx, y + (up ? -amp : amp), nx, y);
      x = nx;
      up = !up;
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_UnderlinePainter old) =>
      old.ranges != ranges ||
      old.color != color ||
      old.paragraphKey != paragraphKey;
}
