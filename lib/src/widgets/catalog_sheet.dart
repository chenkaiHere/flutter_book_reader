import 'package:flutter/material.dart';

import '../bookmark/reader_bookmark_store.dart';
import '../progress/reader_progress_store.dart';
import '../reader_labels.dart';
import '../reader_theme.dart';

/// 书籍信息抽屉：顶部书籍信息区（封面 + 书名 + 作者），下方「详情 / 目录 / 书签」
/// 三个标签页，可点击或左右手势滑动切换（[TabBarView]）。详情页展示书籍信息与简介，
/// 目录页点击某章跳转，书签页点击某条书签跳转。
///
/// 视觉与书架的「书籍详情」弹窗一致，但主题取自阅读器 [ReaderTheme]（随日夜切换），
/// 且不含底部「继续阅读」按钮（阅读器内已在阅读），默认落在「目录」标签页。
///
/// 点击章节或书签均通过 [Navigator.pop] 返回一个 [ReadingPosition]（章 + 偏移）。
class CatalogSheet extends StatefulWidget {
  const CatalogSheet({
    super.key,
    required this.bookTitle,
    required this.author,
    required this.intro,
    required this.coverColor,
    required this.chapterTitles,
    required this.currentIndex,
    required this.theme,
    this.bookmarks = const <Bookmark>[],
    this.scrollController,
  });

  final String bookTitle;
  final String author;
  final String intro;
  final Color coverColor;
  final List<String> chapterTitles;
  final int currentIndex;
  final ReaderTheme theme;

  /// 书签列表（展示于「书签」标签页）
  final List<Bookmark> bookmarks;

  /// 外部滚动控制器（如 [DraggableScrollableSheet] 提供的）；为空时内部自建。
  /// 绑定到「目录」列表，使列表滚到顶部后继续下拉可关闭整个面板。
  final ScrollController? scrollController;

  @override
  State<CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<CatalogSheet>
    with SingleTickerProviderStateMixin {
  /// 标题类文字用衬线中文字体（宋体系）回退，与书架弹窗观感一致，无需额外依赖。
  static const List<String> _serifFallback = <String>[
    'Songti SC',
    'STSong',
    'SimSun',
    'Noto Serif CJK SC',
    'Noto Serif SC',
    'serif',
  ];

  static const double _itemExtent = 56;

  late final TabController _tab = TabController(
    length: 3,
    initialIndex: 1, // 默认落在「目录」（入口即目录按钮）
    vsync: this,
  );

  /// 仅在未外部提供控制器时创建，负责其生命周期。
  ScrollController? _own;

  ScrollController get _listController => widget.scrollController ?? _own!;

  /// 详情 / 书签页各自的独立滚动控制器（面板控制器只给「目录」用）。
  final ScrollController _detailCtrl = ScrollController();
  final ScrollController _markCtrl = ScrollController();

  /// 是否倒序展示（true 时列表从末章到首章）。
  bool _descending = false;

  int get _count => widget.chapterTitles.length;

  int _displayPos(int chapterIndex) =>
      _descending ? _count - 1 - chapterIndex : chapterIndex;

  int _chapterAt(int displayPos) =>
      _descending ? _count - 1 - displayPos : displayPos;

  double _offsetFor(int displayPos) =>
      (displayPos * _itemExtent - 200).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    final double target = _offsetFor(_displayPos(widget.currentIndex));
    if (widget.scrollController == null) {
      _own = ScrollController(initialScrollOffset: target);
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
    }
  }

  void _jumpToCurrent() {
    if (!mounted || !_listController.hasClients) return;
    final double target = _offsetFor(_displayPos(widget.currentIndex));
    _listController.jumpTo(
      target.clamp(0, _listController.position.maxScrollExtent),
    );
  }

  void _toggleOrder() {
    setState(() => _descending = !_descending);
    WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToCurrent());
  }

  @override
  void dispose() {
    _tab.dispose();
    _own?.dispose();
    _detailCtrl.dispose();
    _markCtrl.dispose();
    super.dispose();
  }

  // 颜色便捷取值
  Color get _text => widget.theme.textColor;

  Color get _sub => widget.theme.subTextColor;

  Color get _accent => widget.theme.accentColor;

  Color get _cardColor => widget.theme.isDark
      ? Colors.white.withValues(alpha: 0.06)
      : Colors.black.withValues(alpha: 0.03);

  Color get _hairline => _text.withValues(alpha: 0.08);

  TextStyle _serif({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color? color,
    double? height,
  }) =>
      TextStyle(
        fontFamilyFallback: _serifFallback,
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? _text,
      );

  TextStyle _sans({
    required double size,
    FontWeight weight = FontWeight.w400,
    Color? color,
    double? height,
  }) =>
      TextStyle(
        fontSize: size,
        fontWeight: weight,
        height: height,
        color: color ?? _text,
      );

  @override
  Widget build(BuildContext context) {
    final ReaderLabels labels = ReaderLabels.of(context);
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _grabber(),
          _header(),
          _tabBar(labels),
          Divider(height: 1, color: _hairline),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: <Widget>[
                _buildDetail(labels),
                _buildCatalog(labels),
                _buildBookmarks(labels),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _grabber() => Padding(
        padding: const EdgeInsets.only(top: 11, bottom: 4),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _text.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
      child: Row(
        children: <Widget>[
          _cover(),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  widget.bookTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _serif(size: 22),
                ),
                if (widget.author.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    widget.author,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _sans(size: 13, color: _sub),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: _text.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 16, color: _sub),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cover() {
    const double radius = 6;
    const double spine = 7;
    final HSLColor hsl = HSLColor.fromColor(widget.coverColor);
    final Color c1 =
        hsl.withLightness((hsl.lightness + 0.06).clamp(0.0, 1.0)).toColor();
    final Color c2 =
        hsl.withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0)).toColor();
    return SizedBox(
      width: 56,
      height: 78,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: const Alignment(-0.6, -1),
            end: const Alignment(0.6, 1),
            colors: <Color>[c1, c2],
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: spine,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[Color(0x52000000), Color(0x08000000)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: spine + 1,
                right: 5,
                top: 5,
                bottom: 5,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0x40FFFFFF)),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(spine + 2, 6, 6, 6),
                child: Center(
                  child: Text(
                    widget.bookTitle,
                    maxLines: 3,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: _serif(
                      size: 12,
                      color: Colors.white,
                      height: 1.2,
                    ).copyWith(
                      shadows: const <Shadow>[
                        Shadow(color: Color(0x66000000), blurRadius: 3),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabBar(ReaderLabels labels) {
    final TextStyle label = _serif(size: 16);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TabBar(
        controller: _tab,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: _accent,
        unselectedLabelColor: _sub,
        indicatorColor: _accent,
        indicatorSize: TabBarIndicatorSize.label,
        indicatorWeight: 3,
        labelStyle: label,
        unselectedLabelStyle: label,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: <Widget>[
          Tab(text: labels.detail),
          Tab(text: labels.catalog),
          Tab(text: labels.bookmarkTab),
        ],
      ),
    );
  }

  // ————————————————————— 详情 —————————————————————

  Widget _buildDetail(ReaderLabels labels) {
    final int pct =
        _count == 0 ? 0 : ((widget.currentIndex + 1) / _count * 100).round();
    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            decoration: BoxDecoration(
              color: _cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: <Widget>[
                Text(value, style: _serif(size: 18, color: _accent)),
                const SizedBox(height: 3),
                Text(label, style: _sans(size: 11, color: _sub)),
              ],
            ),
          ),
        );

    final String intro = widget.intro.trim();
    return ListView(
      controller: _detailCtrl,
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
      children: <Widget>[
        Row(
          children: <Widget>[
            stat('$_count', labels.statChapters),
            const SizedBox(width: 10),
            stat('${widget.currentIndex + 1}', labels.statCurrentChapter),
            const SizedBox(width: 10),
            stat('$pct%', labels.statProgress),
          ],
        ),
        const SizedBox(height: 18),
        Text(labels.introHeading, style: _serif(size: 15)),
        const SizedBox(height: 9),
        Text(
          intro.isEmpty ? labels.noIntro : intro,
          style: _sans(
            size: 15,
            height: 1.9,
            color: intro.isEmpty ? _sub : _text.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  // ————————————————————— 目录 —————————————————————

  Widget _buildCatalog(ReaderLabels labels) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(labels.chapterTotal(_count),
                  style: _sans(size: 13, color: _sub)),
              InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: _toggleOrder,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.swap_vert, size: 16, color: _accent),
                      const SizedBox(width: 5),
                      Text(
                        _descending ? labels.orderDesc : labels.orderAsc,
                        style: _sans(
                            size: 13, weight: FontWeight.w600, color: _accent),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _listController,
            itemCount: _count,
            itemExtent: _itemExtent,
            itemBuilder: (BuildContext context, int pos) {
              final int index = _chapterAt(pos);
              final bool active = index == widget.currentIndex;
              return InkWell(
                onTap: () => Navigator.of(context).pop(
                  ReadingPosition(chapterIndex: index),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          widget.chapterTitles[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _sans(
                            size: 15,
                            height: 1.4,
                            weight: active ? FontWeight.w700 : FontWeight.w400,
                            color: active
                                ? _accent
                                : _text.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      if (active)
                        Icon(Icons.play_arrow_rounded,
                            size: 18, color: _accent),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ————————————————————— 书签 —————————————————————

  Widget _buildBookmarks(ReaderLabels labels) {
    if (widget.bookmarks.isEmpty) {
      return ListView(
        controller: _markCtrl,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 30),
            child: Column(
              children: <Widget>[
                Icon(Icons.bookmark_border,
                    size: 46, color: _sub.withValues(alpha: 0.6)),
                const SizedBox(height: 16),
                Text(labels.noBookmarks,
                    style:
                        _sans(size: 15, weight: FontWeight.w600, color: _sub)),
                const SizedBox(height: 6),
                Text(
                  labels.noBookmarksHint,
                  textAlign: TextAlign.center,
                  style: _sans(
                    size: 12.5,
                    height: 1.6,
                    color: _sub.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final List<Bookmark> items = List<Bookmark>.of(widget.bookmarks)
      ..sort((Bookmark a, Bookmark b) => b.createdAt.compareTo(a.createdAt));
    return ListView.builder(
      controller: _markCtrl,
      itemCount: items.length,
      itemBuilder: (BuildContext context, int i) {
        final Bookmark b = items[i];
        return InkWell(
          onTap: () => Navigator.of(context).pop(
            ReadingPosition(
                chapterIndex: b.chapterIndex, charOffset: b.charOffset),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
            decoration: BoxDecoration(
              border:
                  Border(top: BorderSide(color: _text.withValues(alpha: 0.06))),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.bookmark, size: 18, color: _accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '第 ${b.chapterIndex + 1} 章 · ${b.chapterTitle}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sans(
                            size: 14.5,
                            weight: FontWeight.w600,
                            color: _text.withValues(alpha: 0.9)),
                      ),
                      const SizedBox(height: 3),
                      Text(_formatTime(b.createdAt),
                          style: _sans(size: 12, color: _sub)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, size: 18, color: _sub),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 时间戳（毫秒）格式化为 “yyyy-MM-dd HH:mm”。
  static String _formatTime(int ms) {
    if (ms <= 0) return '';
    final DateTime t = DateTime.fromMillisecondsSinceEpoch(ms);
    String two(int n) => n.toString().padLeft(2, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} '
        '${two(t.hour)}:${two(t.minute)}';
  }
}
