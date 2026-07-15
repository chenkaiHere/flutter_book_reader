import 'package:flutter/material.dart';

import '../reader_config.dart';
import '../reader_labels.dart';
import '../reader_theme.dart';

/// 阅读器悬浮菜单：顶部标题栏 + 底部控制栏 + 设置/主题面板。
///
/// 通过 [visible] 控制显隐（带滑入滑出动画）。所有交互通过回调上抛给阅读页。
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

enum _Panel { none, settings, theme }

class _ReaderMenuState extends State<ReaderMenu> {
  _Panel _panel = _Panel.none;
  late ReaderLabels _labels;

  Color get _accent => widget.config.theme.accentColor;

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
    final ReaderTheme t = widget.config.theme;
    final Color barColor = t.isDark ? const Color(0xFF262629) : Colors.white;
    final Color iconColor = t.isDark
        ? const Color(0xFFCACACA)
        : const Color(0xFF33373D);

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
                onTap: () {
                  if (_panel != _Panel.none) {
                    setState(() => _panel = _Panel.none);
                  } else {
                    widget.onRequestClose();
                  }
                },
              ),
            ),
            _buildTopBar(barColor, iconColor),
            _buildBottomArea(barColor, iconColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Color barColor, Color iconColor) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      top: widget.visible ? 0 : -140,
      left: 0,
      right: 0,
      child: Container(
        color: barColor,
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 52,
            child: Row(
              children: <Widget>[
                IconButton(
                  tooltip: _labels.back,
                  icon: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: iconColor,
                  ),
                  onPressed: widget.onBack,
                ),
                Expanded(
                  child: Text(
                    widget.bookTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _labels.more,
                  icon: Icon(Icons.more_horiz, color: iconColor),
                  onPressed: () {},
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomArea(Color barColor, Color iconColor) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      bottom: widget.visible ? 0 : -320,
      left: 0,
      right: 0,
      child: Container(
        color: barColor,
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_panel == _Panel.settings) _buildSettingsPanel(iconColor),
              if (_panel == _Panel.theme) _buildThemePanel(iconColor),
              _buildChapterSeek(iconColor),
              Divider(height: 1, color: iconColor.withValues(alpha: 0.08)),
              _buildActionRow(iconColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChapterSeek(Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: <Widget>[
          TextButton(
            onPressed: widget.onPrevChapter,
            child: Text(
              _labels.prevChapter,
              style: TextStyle(color: iconColor, fontSize: 13),
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: _accent,
                thumbColor: _accent,
                inactiveTrackColor: iconColor.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: widget.chapterCount <= 1
                    ? 0
                    : widget.chapterIndex / (widget.chapterCount - 1),
                onChanged: (double v) {
                  final int idx = (v * (widget.chapterCount - 1)).round();
                  widget.onSeekChapter(idx);
                },
              ),
            ),
          ),
          TextButton(
            onPressed: widget.onNextChapter,
            child: Text(
              _labels.nextChapter,
              style: TextStyle(color: iconColor, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: <Widget>[
          _menuBtn(Icons.list, _labels.catalog, iconColor, () {
            setState(() => _panel = _Panel.none);
            widget.onOpenCatalog();
          }),
          _menuBtn(
            Icons.brightness_6_outlined,
            _labels.themeMenu,
            iconColor,
            () {
              setState(
                () => _panel = _panel == _Panel.theme
                    ? _Panel.none
                    : _Panel.theme,
              );
            },
          ),
          _menuBtn(Icons.text_fields, _labels.settingsMenu, iconColor, () {
            setState(
              () => _panel = _panel == _Panel.settings
                  ? _Panel.none
                  : _Panel.settings,
            );
          }),
        ],
      ),
    );
  }

  Widget _menuBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 24, color: color),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  // —— 设置面板：字号、行距、翻页方式 ——
  Widget _buildSettingsPanel(Color iconColor) {
    final ReaderConfig c = widget.config;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _rowLabel(_labels.fontSize, iconColor),
          Row(
            children: <Widget>[
              _stepBtn('A-', iconColor, c.decreaseFont),
              Expanded(
                child: Center(
                  child: Text(
                    '${c.fontSize.toInt()}',
                    style: TextStyle(fontSize: 15, color: iconColor),
                  ),
                ),
              ),
              _stepBtn('A+', iconColor, c.increaseFont),
            ],
          ),
          const SizedBox(height: 6),
          _rowLabel(_labels.lineSpacing, iconColor),
          Row(
            children: <Widget>[
              Icon(Icons.density_small, size: 18, color: iconColor),
              Expanded(
                child: Slider(
                  min: ReaderConfig.minLineHeight,
                  max: ReaderConfig.maxLineHeight,
                  activeColor: _accent,
                  value: c.lineHeight,
                  onChanged: c.setLineHeight,
                ),
              ),
              Icon(Icons.density_large, size: 18, color: iconColor),
            ],
          ),
          const SizedBox(height: 4),
          _rowLabel(_labels.flipMode, iconColor),
          const SizedBox(height: 6),
          Row(
            children: FlipType.values.map((FlipType f) {
              final bool active = c.flipType == f;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton.icon(
                    onPressed: () => c.setFlipType(f),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: active ? _accent : iconColor,
                      side: BorderSide(
                        color: active
                            ? _accent
                            : iconColor.withValues(alpha: 0.3),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    icon: Icon(f.icon, size: 16),
                    label: Text(
                      f.label,
                      style: const TextStyle(fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // —— 主题面板：纸张背景色 ——
  Widget _buildThemePanel(Color iconColor) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _rowLabel(_labels.background, iconColor),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ReaderTheme.presets.map((ReaderTheme t) {
              final bool active = widget.config.theme.alias == t.alias;
              return GestureDetector(
                onTap: () => widget.config.setTheme(t),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: t.paperColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: active
                              ? _accent
                              : iconColor.withValues(alpha: 0.25),
                          width: active ? 2.5 : 1,
                        ),
                      ),
                      child: active
                          ? Icon(Icons.check, size: 18, color: _accent)
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.name,
                      style: TextStyle(fontSize: 11, color: iconColor),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _rowLabel(String text, Color color) => Text(
    text,
    style: TextStyle(fontSize: 12, color: color.withValues(alpha: 0.6)),
  );

  Widget _stepBtn(String text, Color color, VoidCallback onTap) =>
      OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          minimumSize: const Size(64, 34),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(text),
      );
}
