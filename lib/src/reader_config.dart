import 'package:flutter/material.dart';

import 'reader_theme.dart';

/// 阅读页内容区统一内边距（正文排版与分页测量共用同一基准）。
const EdgeInsets kReaderPagePadding = EdgeInsets.fromLTRB(20, 12, 20, 16);

/// 头部章节名与底部信息栏预留的高度（分页时从可用高度中扣除）。
const double kReaderHeaderHeight = 24;
const double kReaderFooterHeight = 22;

/// 分页时在可用高度上再预留的安全余量：吸收多段落逐块渲染时的亚像素累计，
/// 确保排版好的一页永远不会撑破可视区域（视觉上仅是底部多一点留白）。
const double kReaderContentSafety = 16;

/// 翻页方式
enum FlipType {
  /// 左右平滑翻页（横向 PageView）
  slideHorizontal('平滑翻页', Icons.view_carousel_outlined),

  /// 上下滚动（纵向连续滚动）
  scrollVertical('上下滚动', Icons.swap_vert),

  /// 无动画直接切换
  none('无动画', Icons.crop_square);

  const FlipType(this.label, this.icon);

  final String label;
  final IconData icon;
}

/// 阅读器全局设置。用 [ChangeNotifier] 承载，页面通过监听刷新。
///
/// 对应 tapon 中的 ReaderSettings：字号、行距、主题、翻页方式、亮度蒙层。
class ReaderConfig extends ChangeNotifier {
  /// 每个阅读器可持有独立配置；[instance] 仅作为便捷的全局默认。
  ReaderConfig();

  static final ReaderConfig instance = ReaderConfig();

  // —— 字号 ——
  static const double minFontSize = 14;
  static const double maxFontSize = 32;
  double _fontSize = 19;
  double get fontSize => _fontSize;

  // —— 行距（行高倍数）——
  static const double minLineHeight = 1.2;
  static const double maxLineHeight = 2.4;
  double _lineHeight = 1.7;
  double get lineHeight => _lineHeight;

  // —— 排版：首行缩进（全角空格数）——
  int _firstLineIndent = 2;
  int get firstLineIndent => _firstLineIndent;
  String get indent => '　' * _firstLineIndent;

  // —— 排版：段间距（像素）——
  double _paragraphSpacing = 8;
  double get paragraphSpacing => _paragraphSpacing;

  // —— 排版：两端对齐 ——
  bool _justify = true;
  bool get justify => _justify;
  TextAlign get textAlign => _justify ? TextAlign.justify : TextAlign.start;

  // —— 主题 ——
  ReaderTheme _theme = ReaderTheme.yellow;
  ReaderTheme get theme => _theme;

  // —— 翻页方式 ——
  FlipType _flipType = FlipType.slideHorizontal;
  FlipType get flipType => _flipType;

  // —— 屏幕亮度蒙层（0 = 不变暗，1 = 全黑）——
  double _dimLevel = 0;
  double get dimLevel => _dimLevel;

  TextStyle get textStyle => TextStyle(
    fontSize: _fontSize,
    height: _lineHeight,
    color: _theme.textColor,
  );

  void increaseFont() {
    if (_fontSize >= maxFontSize) return;
    _fontSize = (_fontSize + 1).clamp(minFontSize, maxFontSize);
    notifyListeners();
  }

  void decreaseFont() {
    if (_fontSize <= minFontSize) return;
    _fontSize = (_fontSize - 1).clamp(minFontSize, maxFontSize);
    notifyListeners();
  }

  void setLineHeight(double value) {
    _lineHeight = value.clamp(minLineHeight, maxLineHeight);
    notifyListeners();
  }

  void setFirstLineIndent(int chars) {
    final int v = chars.clamp(0, 4);
    if (v == _firstLineIndent) return;
    _firstLineIndent = v;
    notifyListeners();
  }

  void setParagraphSpacing(double value) {
    _paragraphSpacing = value.clamp(0, 32);
    notifyListeners();
  }

  void setJustify(bool value) {
    if (value == _justify) return;
    _justify = value;
    notifyListeners();
  }

  void setTheme(ReaderTheme theme) {
    if (_theme.alias == theme.alias) return;
    _theme = theme;
    notifyListeners();
  }

  void setFlipType(FlipType type) {
    if (_flipType == type) return;
    _flipType = type;
    notifyListeners();
  }

  void setDimLevel(double value) {
    _dimLevel = value.clamp(0, 0.7);
    notifyListeners();
  }
}
