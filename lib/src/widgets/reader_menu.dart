import 'package:flutter/material.dart';

import '../reader_config.dart';
import '../reader_labels.dart';
import '../reader_theme.dart';

/// 阅读器悬浮菜单：顶部标题栏 + 底部控制栏 + 设置/主题面板。
///
/// 视觉参考「阅读器菜单」设计稿：顶栏为返回 + 衬线书名 + 书签；底栏为面板色卡片，
/// 含「上一章 / 进度 / 下一章」与「目录 / 日夜 / 设置」，设置面板内含字号、行距、
/// 背景主题、翻页方式。通过 [visible] 控制显隐（滑入滑出）。
class ReaderMenu extends StatefulWidget {
  const ReaderMenu({
    super.key,
    required this.visible,
    required this.bookTitle,
    required this.chapterTitle,
    required this.chapterIndex,
    required this.chapterCount,
    required this.progress,
    required this.config,
    required this.bookmarked,
    required this.onToggleBookmark,
    required this.onBack,
    required this.onOpenCatalog,
    required this.onPrevChapter,
    required this.onNextChapter,
    required this.onSeekChapter,
    required this.onRequestClose,
  });

  final bool visible;
  final String bookTitle;
  final String chapterTitle;
  final int chapterIndex;
  final int chapterCount;

  /// 全书阅读进度 0~1
  final double progress;
  final ReaderConfig config;

  /// 当前页是否已加书签（决定顶栏书签按钮的实心/空心）
  final bool bookmarked;

  /// 点击顶栏书签按钮：已加书签则移除，否则加入
  final VoidCallback onToggleBookmark;

  final VoidCallback onBack;
  final VoidCallback onOpenCatalog;
  final VoidCallback onPrevChapter;
  final VoidCallback onNextChapter;
  final ValueChanged<int> onSeekChapter;

  /// 点击顶/底栏之外的空白区域时请求关闭整个菜单
  final VoidCallback onRequestClose;

  @override
  State<ReaderMenu> createState() => _ReaderMenuState();
}

enum _Panel { none, settings }

class _ReaderMenuState extends State<ReaderMenu> {
  /// 标题类文字用衬线中文字体（宋体系）回退，与设计稿一致，无需额外依赖。
  static const List<String> _serifFallback = <String>[
    'Songti SC',
    'STSong',
    'SimSun',
    'Noto Serif CJK SC',
    'Noto Serif SC',
    'serif',
  ];

  _Panel _panel = _Panel.none;
  late ReaderLabels _labels;

  /// 记住切到夜间前的日间主题，切回时还原。
  ReaderTheme? _lastLight;

  ReaderTheme get _t => widget.config.theme;
  Color get _accent => _t.accentColor;
  Color get _text => _t.textColor;
  Color get _sub => _t.subTextColor;

  TextStyle _serif({
    required double size,
    FontWeight weight = FontWeight.w700,
    Color? color,
  }) =>
      TextStyle(
        fontFamilyFallback: _serifFallback,
        fontSize: size,
        fontWeight: weight,
        color: color ?? _text,
      );

  /// 日间 / 夜间一键切换。
  void _toggleDayNight() {
    final ReaderConfig c = widget.config;
    if (c.theme.isDark) {
      c.setTheme(
        _lastLight ??
            ReaderTheme.presets.firstWhere((ReaderTheme t) => !t.isDark),
      );
    } else {
      _lastLight = c.theme;
      c.setTheme(ReaderTheme.presets.firstWhere((ReaderTheme t) => t.isDark));
    }
  }

  @override
  void didUpdateWidget(covariant ReaderMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible && !widget.visible) {
      _panel = _Panel.none;
    }
  }

  @override
  Widget build(BuildContext context) {
    _labels = ReaderLabels.of(context);
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                // 点击中间阅读区：直接关闭整个菜单（含设置面板），
                // 面板状态在菜单隐藏时由 didUpdateWidget 复位。
                onTap: widget.onRequestClose,
              ),
            ),
            _buildTopBar(),
            _buildBottomArea(),
          ],
        ),
      ),
    );
  }

  // ————————————————————— 顶栏 —————————————————————

  Widget _buildTopBar() {
    // 全屏沉浸下没有系统状态栏，为顶栏预留一段“状态栏高度”的呼吸空间。
    final double sysTop = MediaQuery.of(context).padding.top;
    final double topInset = sysTop > 20 ? sysTop : 24;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      top: widget.visible ? 0 : -180,
      left: 0,
      right: 0,
      child: ColoredBox(
        color: _t.paperColor,
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: SizedBox(
            height: 56,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 14),
                _iconTap(
                  Icons.arrow_back_ios_new,
                  20,
                  _text,
                  widget.onBack,
                  tooltip: _labels.back,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _serif(size: 20),
                  ),
                ),
                _iconTap(
                  widget.bookmarked ? Icons.bookmark : Icons.bookmark_border,
                  22,
                  widget.bookmarked ? _accent : _sub,
                  widget.onToggleBookmark,
                  tooltip: widget.bookmarked
                      ? _labels.removeBookmark
                      : _labels.addBookmark,
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconTap(
    IconData icon,
    double size,
    Color color,
    VoidCallback onTap, {
    String? tooltip,
  }) {
    final Widget btn = InkResponse(
      onTap: onTap,
      radius: 22,
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: size, color: color),
      ),
    );
    return tooltip == null ? btn : Tooltip(message: tooltip, child: btn);
  }

  // ————————————————————— 底栏 —————————————————————

  Widget _buildBottomArea() {
    final bool dark = _t.isDark;
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      bottom: widget.visible ? 0 : -360,
      left: 0,
      right: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _t.panelColor,
          border: Border(top: BorderSide(color: _t.dividerColor)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color.fromRGBO(20, 12, 4, dark ? 0.4 : 0.12),
              blurRadius: 30,
              offset: const Offset(0, -10),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // 设置面板与“上一章/下一章”共用同一区域：打开设置时覆盖住快捷条。
              _buildPanelArea(),
              _buildNavRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPanelArea() {
    final Widget child = _panel == _Panel.settings
        ? KeyedSubtree(
            key: const ValueKey<String>('settings'),
            child: _buildSettingsPanel(),
          )
        : KeyedSubtree(
            key: const ValueKey<String>('seek'),
            child: _buildChapterSeek(),
          );
    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      alignment: Alignment.bottomCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: child,
      ),
    );
  }

  // 上一章 / 进度 / 下一章
  Widget _buildChapterSeek() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 4),
      child: Row(
        children: <Widget>[
          _seekText(_labels.prevChapter, widget.onPrevChapter),
          Expanded(
              child: _buildSlider(
            value: widget.chapterCount <= 1
                ? 0
                : widget.chapterIndex / (widget.chapterCount - 1),
            onChanged: (double v) =>
                widget.onSeekChapter((v * (widget.chapterCount - 1)).round()),
          )),
          _seekText(_labels.nextChapter, widget.onNextChapter),
        ],
      ),
    );
  }

  Widget _seekText(String text, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            text,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600, color: _sub),
          ),
        ),
      );

  Widget _buildSlider({
    required double value,
    required ValueChanged<double> onChanged,
    double min = 0,
    double max = 1,
  }) {
    return SliderTheme(
      data: SliderThemeData(
        trackHeight: 4,
        activeTrackColor: _accent,
        inactiveTrackColor: _t.trackColor,
        thumbColor: _accent,
        overlayColor: _accent.withValues(alpha: 0.15),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        trackShape: const RoundedRectSliderTrackShape(),
      ),
      child: Slider(
          min: min,
          max: max,
          value: value.clamp(min, max),
          onChanged: onChanged),
    );
  }

  // 目录 / 日夜 / 设置
  Widget _buildNavRow() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: _t.dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _navBtn(Icons.format_list_bulleted, _labels.catalog, _sub, () {
            setState(() => _panel = _Panel.none);
            widget.onOpenCatalog();
          }),
          _navBtn(
            _t.isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
            _t.isDark ? _labels.dayMode : _labels.nightMode,
            _t.isDark ? _accent : _sub,
            _toggleDayNight,
          ),
          _navBtn(
            _panel == _Panel.settings
                ? Icons.settings
                : Icons.settings_outlined,
            _labels.settingsMenu,
            _panel == _Panel.settings ? _accent : _sub,
            () => setState(
              () => _panel =
                  _panel == _Panel.settings ? _Panel.none : _Panel.settings,
            ),
            active: _panel == _Panel.settings,
          ),
        ],
      ),
    );
  }

  Widget _navBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    bool active = false,
  }) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ————————————————————— 设置面板 —————————————————————

  Widget _buildSettingsPanel() {
    final ReaderConfig c = widget.config;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 字号
          _sectionLabel(_labels.fontSize),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              _stepBtn('A-', c.decreaseFont),
              Text('${c.fontSize.toInt()}', style: _serif(size: 22)),
              _stepBtn('A+', c.increaseFont),
            ],
          ),
          const SizedBox(height: 20),

          // 行距
          _sectionLabel(_labels.lineSpacing),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              Icon(Icons.density_small, size: 20, color: _sub),
              Expanded(
                child: _buildSlider(
                  min: ReaderConfig.minLineHeight,
                  max: ReaderConfig.maxLineHeight,
                  value: c.lineHeight,
                  onChanged: c.setLineHeight,
                ),
              ),
              Icon(Icons.density_large, size: 20, color: _sub),
            ],
          ),
          const SizedBox(height: 18),

          // 背景 / 主题
          _sectionLabel(_labels.background),
          const SizedBox(height: 14),
          _buildThemeRow(),
          const SizedBox(height: 22),

          // 翻页
          _sectionLabel(_labels.flipMode),
          const SizedBox(height: 12),
          _buildFlipRow(c),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _sub),
      );

  Widget _stepBtn(String text, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 96,
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: _t.borderColor, width: 1.5),
          ),
          child: Text(
            text,
            style: TextStyle(
                fontSize: 19, fontWeight: FontWeight.w600, color: _text),
          ),
        ),
      );

  // 6 套主题圆形色板
  Widget _buildThemeRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: ReaderTheme.presets.map((ReaderTheme t) {
        final bool active = _t.alias == t.alias;
        return GestureDetector(
          onTap: () => widget.config.setTheme(t),
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? _accent : Colors.transparent,
                width: 2.5,
              ),
            ),
            child: Container(
              width: active ? 42 : 46,
              height: active ? 42 : 46,
              decoration: BoxDecoration(
                color: t.paperColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: t.isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.1),
                ),
              ),
              child:
                  active ? Icon(Icons.check, size: 18, color: _accent) : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  // 翻页方式：5 个药丸，选中项强调色文字 + 亮底 + 阴影
  Widget _buildFlipRow(ReaderConfig c) {
    final bool dark = _t.isDark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: FlipType.values.map((FlipType f) {
        final bool active = c.flipType == f;
        return Semantics(
          button: true,
          selected: active,
          label: f.label,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => c.setFlipType(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: EdgeInsets.symmetric(
                  horizontal: active ? 15 : 9, vertical: 9),
              decoration: BoxDecoration(
                color: active ? _t.segActiveColor : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: active
                    ? <BoxShadow>[
                        BoxShadow(
                          color: Color.fromRGBO(20, 12, 4, dark ? 0.35 : 0.12),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                f.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  color: active ? _accent : _sub,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
