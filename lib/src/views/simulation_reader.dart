import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../paginator.dart';
import '../widgets/loading_page.dart';
import '../widgets/page_frame.dart';
import 'reader_mode_view.dart';

/// 仿真翻页：真实书页折角，跟随手指。
///
/// 折角几何为经典书籍翻页算法：书角固定在右下角 [f]，手指点 [a] 与 [f] 连线的
/// 中垂线即折痕，用两段二次贝塞尔勾出折边。当前页按“整页去掉折角”裁剪，露出
/// 底下相邻页；折起的纸背填纯色 + 多层渐变阴影，营造纸张卷折的立体感。
///
/// 该几何/绘制模型参考开源库 bookfx（lixp），此处为独立实现与适配。
class SimulationReader extends ReaderModeView {
  const SimulationReader({super.key, required super.controller});

  @override
  State<SimulationReader> createState() => _SimulationReaderState();
}

class _SimulationReaderState extends ReaderModeViewState<SimulationReader>
    with SingleTickerProviderStateMixin {
  Size _size = Size.zero;

  /// 折角控制点；null 表示平放（无折角）。用 ValueNotifier 让裁剪/绘制局部刷新，
  /// 拖动时不重建页面 Widget。
  final ValueNotifier<_Fold?> _fold = ValueNotifier<_Fold?>(null);

  /// 是否处于折页态（控制显示 Stack 还是平铺页）。
  bool _folding = false;

  /// 翻向：true 向后（下一页），false 向前（上一页）。
  bool _forward = true;

  Offset _down = Offset.zero;
  bool _started = false;

  /// 起手落在上下中段 → 水平翻页（竖直卷曲），否则折角卷曲。
  bool _midBand = false;

  late final AnimationController _anim = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 320),
  );
  Point<double> _animFrom = const Point<double>(0, 0);
  Point<double> _animTo = const Point<double>(0, 0);

  @override
  void initState() {
    super.initState();
    _anim.addListener(() {
      final double t = _anim.value;
      _fold.value = _Fold(
        Point<double>(
          _animFrom.x + (_animTo.x - _animFrom.x) * t,
          _animFrom.y + (_animTo.y - _animFrom.y) * t,
        ),
        _size,
      );
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _fold.dispose();
    super.dispose();
  }

  bool get _canForward =>
      controller.pageIndex < controller.pages.length - 1 || controller.hasNext;
  bool get _canBackward => controller.pageIndex > 0 || controller.hasPrev;

  void _onPanDown(DragDownDetails d) {
    _anim.stop();
    _down = d.localPosition;
    _started = false;
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_size.isEmpty) return;
    final double w = _size.width, h = _size.height;
    final Offset m = d.localPosition;
    if (!_started) {
      final double dx = m.dx - _down.dx;
      if (dx.abs() < 6) return;
      _forward = dx < 0;
      if ((_forward && !_canForward) || (!_forward && !_canBackward)) return;
      _midBand = _down.dy > h / 3 && _down.dy < h * 2 / 3;
      setState(() {
        _started = true;
        _folding = true;
      });
    }
    // 起手位置在上下中段 → 水平翻页：折角贴底边，折痕近乎竖直，纸张整体从右向
    // 左卷；否则跟随手指高度，形成右下角折角卷曲。
    final double mx = m.dx.clamp(-w + 1, w - 1);
    final double my = _midBand ? h - 1 : m.dy.clamp(1.0, h - 1);
    _fold.value = _Fold(Point<double>(mx, my), _size);
  }

  void _onPanEnd(DragEndDetails d) {
    if (!_started) {
      _resetFlat();
      return;
    }
    final double w = _size.width, h = _size.height;
    final Point<double>? a = _fold.value?.a;
    if (a == null) {
      _resetFlat();
      return;
    }
    final double vx = d.velocity.pixelsPerSecond.dx;
    if (_forward) {
      // 向后：新页覆盖比例 = (w - a.x)/w，超过 1/3 或向左快甩则翻过去
      final bool commit = (w - a.x) / w > 1 / 3 || vx < -600;
      _animateTo(
        commit ? Point<double>(-w, h) : Point<double>(w, h),
        onDone: commit ? controller.nextPage : null,
      );
    } else {
      // 向前：上一页覆盖比例 = a.x/w，超过 1/2 或向右快甩则翻过去（上一页覆盖）
      final bool commit = a.x / w > 1 / 2 || vx > 600;
      _animateTo(
        commit ? Point<double>(w, h) : Point<double>(-w, h),
        onDone: commit ? controller.prevPage : null,
      );
    }
  }

  void _animateTo(Point<double> target, {VoidCallback? onDone}) {
    _animFrom = _fold.value?.a ?? target;
    _animTo = target;
    _anim.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      onDone?.call();
      _resetFlat();
    });
  }

  void _resetFlat() {
    _fold.value = null;
    if (mounted) {
      setState(() {
        _folding = false;
        _started = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (controller.pages.isEmpty) {
      final int idx = controller.chapterIndex;
      return ReaderStatusPage(
        theme: theme,
        error: controller.hasError(idx),
        onRetry: () => controller.retry(idx),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        _size = constraints.biggest;
        return GestureDetector(
          onPanDown: _onPanDown,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: _buildContent(),
        );
      },
    );
  }

  Widget _buildContent() {
    // 平放：正常显示当前页
    if (!_folding) {
      return _pageWidget(
        controller.chapterIndex,
        controller.pages,
        controller.pageIndex,
      );
    }
    // 折页：底层露出的相邻页 + 上层被裁剪的翻动页 + 折角纸背与阴影
    final Widget front = _forward ? _currentWidget() : _backwardWidget();
    final Widget behind = _forward ? _forwardWidget() : _currentWidget();
    final Color backColor = ui.Color.alphaBlend(
      Colors.black.withValues(alpha: 0.06),
      theme.paperColor,
    );
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        behind,
        ClipPath(clipper: _FrontClipper(_fold), child: front),
        CustomPaint(
          size: _size,
          painter: _FoldPainter(
            fold: _fold,
            backColor: backColor,
            isDark: theme.isDark,
          ),
        ),
      ],
    );
  }

  Widget _currentWidget() => _pageWidget(
        controller.chapterIndex,
        controller.pages,
        controller.pageIndex,
      );

  Widget _forwardWidget() {
    if (controller.pageIndex < controller.pages.length - 1) {
      return _pageWidget(
        controller.chapterIndex,
        controller.pages,
        controller.pageIndex + 1,
      );
    }
    return _adjacentChapterWidget(controller.chapterIndex + 1, atEnd: false);
  }

  Widget _backwardWidget() {
    if (controller.pageIndex > 0) {
      return _pageWidget(
        controller.chapterIndex,
        controller.pages,
        controller.pageIndex - 1,
      );
    }
    return _adjacentChapterWidget(controller.chapterIndex - 1, atEnd: true);
  }

  Widget _adjacentChapterWidget(int chapterIdx, {required bool atEnd}) {
    final List<ReaderPage>? pages = controller.pagesFor(chapterIdx);
    if (pages == null) {
      return ColoredBox(
        color: theme.paperColor,
        child: ReaderStatusPage(theme: theme),
      );
    }
    final int pageIdx = atEnd ? (pages.isEmpty ? 0 : pages.length - 1) : 0;
    return _pageWidget(chapterIdx, pages, pageIdx);
  }

  Widget _pageWidget(int chapterIdx, List<ReaderPage> pages, int pageIdx) {
    final ReaderPage content = (pageIdx >= 0 && pageIdx < pages.length)
        ? pages[pageIdx]
        : const <ReaderBlock>[];
    return ColoredBox(
      color: theme.paperColor,
      child: ReaderPageContent(
        theme: theme,
        config: config,
        bookTitle: controller.manifest.title,
        chapterTitle: controller.chapterTitleAt(chapterIdx),
        page: content,
        isChapterHead: pageIdx == 0,
        chapterIndex: chapterIdx,
        chapterCount: controller.chapterCount,
        pageIndex: pageIdx,
        pageCount: pages.length,
        progress: controller.progressFor(chapterIdx, pages, pageIdx),
      ),
    );
  }
}

// ————————————————————— 几何 —————————————————————

class _Line {
  const _Line(this.a, this.b, this.slope, this.intercept);
  final Point<double> a;
  final Point<double> b;
  final double slope;
  final double intercept;
}

_Line _lineEq(Point<double> p1, Point<double> p2) {
  double slope;
  if (p1.x == p2.x) {
    slope = p1.y == p2.y
        ? double.nan
        : (p1.y > p2.y ? double.infinity : double.negativeInfinity);
  } else {
    slope = (p1.y - p2.y) / (p1.x - p2.x);
  }
  final double intercept =
      (slope.isNaN || slope.isInfinite) ? double.nan : p1.y - slope * p1.x;
  return _Line(p1, p2, slope, intercept);
}

Point<double> _cross(
  Point<double> a,
  Point<double> b,
  Point<double> m,
  Point<double> n,
) {
  final _Line l1 = _lineEq(a, b);
  final _Line l2 = _lineEq(m, n);
  final double x = (l2.intercept - l1.intercept) / (l1.slope - l2.slope);
  return Point<double>(x, x * l1.slope + l1.intercept);
}

Point<double> _project(_Line line, double distance) {
  final double slope = line.slope;
  final double k = sqrt(distance * distance / (1 + slope * slope));
  if (slope > 0 || line.a.y >= line.b.y) {
    return Point<double>(line.a.x - k, line.a.y - k * slope);
  }
  return Point<double>(line.a.x + k, line.a.y + k * slope);
}

/// 折角九点几何（+ 折面阴影投影点 p1/p2）。书角 f 固定在右下角。
class _Fold {
  _Fold(this._touch, this.size) {
    Point<double> a = _touch;
    f = Point<double>(size.width, size.height);
    g = Point<double>((a.x + f.x) / 2, (a.y + f.y) / 2);
    e = Point<double>(g.x - _sq(f.y - g.y) / (f.x - g.x), f.y);
    double cx = e.x - (f.x - e.x) / 2;
    // 模拟左侧书封：折角不越过左边界
    if (a.x > 0 && cx <= 0) {
      final double fc = f.x - cx;
      final double fa = f.x - a.x;
      final double bb1 = size.width * fa / fc;
      final double fd = bb1 * (f.y - a.y) / fa;
      a = Point<double>(f.x - bb1, f.y - fd);
      g = Point<double>((a.x + f.x) / 2, (a.y + f.y) / 2);
      e = Point<double>(g.x - _sq(f.y - g.y) / (f.x - g.x), f.y);
      cx = 0;
    }
    this.a = a;
    c = Point<double>(cx, f.y);
    h = Point<double>(f.x, g.y - _sq(f.x - g.x) / (f.y - g.y));
    j = Point<double>(f.x, h.y - (f.y - h.y) / 2);
    b = _cross(c, j, a, e);
    k = _cross(c, j, a, h);
    final Point<double> tp = Point<double>((c.x + b.x) / 2, (c.y + b.y) / 2);
    final Point<double> to = Point<double>((j.x + k.x) / 2, (j.y + k.y) / 2);
    d = Point<double>((tp.x + e.x) / 2, (tp.y + e.y) / 2);
    i = Point<double>((to.x + h.x) / 2, (to.y + h.y) / 2);
    p1 = _project(_lineEq(a, h), elevationC);
    p2 = _project(_lineEq(a, e), elevationC);
  }

  final Point<double> _touch;
  final Size size;
  static const double elevationC = 12;

  late final Point<double> a; // 手指点（可能被书封约束修正）
  late final Point<double> f; // 右下角
  late Point<double> g, e, c, h, j, b, k, d, i, p1, p2;

  static double _sq(double v) => v * v;

  bool get flat => a == f || a.y == f.y;

  /// 折起纸片的外轮廓（c→e→b→a→k→h→j→f）。
  Path flapPath() => Path()
    ..moveTo(c.x, c.y)
    ..quadraticBezierTo(e.x, e.y, b.x, b.y)
    ..lineTo(a.x, a.y)
    ..lineTo(k.x, k.y)
    ..quadraticBezierTo(h.x, h.y, j.x, j.y)
    ..lineTo(f.x, f.y)
    ..close();
}

// ————————————————————— 裁剪 & 绘制 —————————————————————

/// 翻动页可见区域 = 整页 − 折角。
class _FrontClipper extends CustomClipper<Path> {
  _FrontClipper(this.fold) : super(reclip: fold);
  final ValueListenable<_Fold?> fold;

  @override
  Path getClip(Size size) {
    final Path rect = Path()..addRect(Offset.zero & size);
    final _Fold? p = fold.value;
    if (p == null || p.flat || p.a.x <= -size.width) return rect;
    return Path.combine(PathOperation.difference, rect, p.flapPath());
  }

  @override
  bool shouldReclip(_FrontClipper old) => old.fold != fold;
}

/// 折起纸背（纯色）+ 折痕多层渐变阴影。
class _FoldPainter extends CustomPainter {
  _FoldPainter({
    required this.fold,
    required this.backColor,
    required this.isDark,
  }) : super(repaint: fold);

  final ValueListenable<_Fold?> fold;
  final Color backColor;
  final bool isDark;

  Offset _o(Point<double> p) => Offset(p.x, p.y);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    final _Fold? p = fold.value;
    if (p == null || p.flat) return;

    final Color shadowSoft = Colors.black.withValues(alpha: 0.12);
    final Color shadowMid = Colors.black.withValues(alpha: 0.16);
    final Color shadowStrong = Colors.black.withValues(alpha: 0.22);
    final Color clear = Colors.black.withValues(alpha: 0);

    // 折起纸片外轮廓
    final Path flap = p.flapPath();

    // —— A 区（翻动页）折痕两侧的投影阴影 ——
    final double dx1 = p.a.x - p.p1.x, dy1 = p.a.y - p.p1.y;
    final Path aShadowLeft = Path()
      ..moveTo(p.c.x - dx1, p.c.y)
      ..quadraticBezierTo(p.e.x - dx1, p.e.y - dy1, p.b.x - dx1, p.b.y - dy1)
      ..lineTo(p.p1.x, p.p1.y)
      ..lineTo(p.k.x, p.k.y)
      ..lineTo(p.f.x, p.f.y)
      ..close();

    final double dx2 = p.a.x - p.p2.x, dy2 = p.a.y - p.p2.y;
    final Path aShadowRight = Path()
      ..moveTo(p.j.x, p.j.y - dy2)
      ..quadraticBezierTo(p.i.x - dx2, p.i.y - dy2, p.k.x - dx2, p.k.y - dy2)
      ..lineTo(p.p2.x, p.p2.y)
      ..lineTo(p.b.x, p.b.y)
      ..lineTo(p.f.x, p.f.y)
      ..close();

    final Paint sp = Paint()..style = PaintingStyle.fill;
    canvas.drawPath(
      Path.combine(PathOperation.reverseDifference, flap, aShadowLeft),
      sp
        ..shader = ui.Gradient.linear(
          _o(p.a),
          _o(p.p1),
          <Color>[shadowSoft, clear],
        ),
    );
    canvas.drawPath(
      Path.combine(PathOperation.reverseDifference, flap, aShadowRight),
      sp
        ..shader = ui.Gradient.linear(
          _o(p.a),
          _o(p.p2),
          <Color>[shadowSoft, clear],
        ),
    );

    // a 点缺口的三角补偿
    final Point<double> xp = _cross(
      Point<double>(p.b.x - dx1, p.b.y - dy1),
      p.p1,
      p.p2,
      Point<double>(p.k.x - dx2, p.k.y - dy2),
    );
    canvas.drawPath(
      Path()
        ..moveTo(p.a.x, p.a.y)
        ..lineTo(xp.x, xp.y)
        ..lineTo(p.p1.x, p.p1.y)
        ..close(),
      sp
        ..shader =
            ui.Gradient.linear(_o(p.a), _o(p.p1), <Color>[shadowSoft, clear]),
    );
    canvas.drawPath(
      Path()
        ..moveTo(p.a.x, p.a.y)
        ..lineTo(xp.x, xp.y)
        ..lineTo(p.p2.x, p.p2.y)
        ..close(),
      sp
        ..shader =
            ui.Gradient.linear(_o(p.a), _o(p.p2), <Color>[shadowSoft, clear]),
    );

    // —— B 区：折起纸背（纯色）——
    final Path triangleB = Path()
      ..moveTo(p.d.x, p.d.y)
      ..lineTo(p.a.x, p.a.y)
      ..lineTo(p.i.x, p.i.y)
      ..close();
    final Path mPathB = Path.combine(PathOperation.intersect, flap, triangleB);
    canvas.drawPath(
      mPathB,
      Paint()
        ..style = PaintingStyle.fill
        ..color = backColor,
    );

    // —— C 区：纸背靠折痕一侧的加深阴影 ——
    final Path bcArea = Path()
      ..moveTo(p.c.x, p.c.y)
      ..lineTo(p.j.x, p.j.y)
      ..lineTo(p.h.x, p.h.y)
      ..lineTo(p.e.x, p.e.y)
      ..close();
    final Path combineToBC =
        Path.combine(PathOperation.intersect, bcArea, flap);
    final Path combineToC =
        Path.combine(PathOperation.difference, combineToBC, mPathB);
    final Point<double> u = _cross(p.a, p.f, p.d, p.i);
    canvas.drawPath(
      combineToC,
      Paint()
        ..style = PaintingStyle.fill
        ..shader = ui.Gradient.linear(
          _o(u),
          _o(p.g),
          <Color>[isDark ? shadowStrong : shadowMid, clear],
        ),
    );
  }

  @override
  bool shouldRepaint(_FoldPainter old) =>
      old.fold != fold || old.backColor != backColor;
}
