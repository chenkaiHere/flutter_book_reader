import 'package:flutter/material.dart';

/// 阅读主题：纸张背景色 + 正文文字色 + 面板/强调等派生色。
///
/// 配色参考「阅读器菜单」设计稿的 6 套主题（白 / 灰 / 米 / 青 / 蓝 / 夜）。
class ReaderTheme {
  const ReaderTheme({
    required this.alias,
    required this.name,
    required this.paperColor,
    required this.textColor,
    this.accentColor = const Color(0xFFE8622A),
    Color? panelColor,
    Color? segActiveColor,
  })  : _panelColor = panelColor,
        _segActiveColor = segActiveColor;

  final String alias;
  final String name;

  /// 阅读纸张背景颜色
  final Color paperColor;

  /// 正文文字颜色
  final Color textColor;

  /// 强调色（进度条、选中态、目录高亮等），支持白标定制
  final Color accentColor;

  final Color? _panelColor;
  final Color? _segActiveColor;

  /// 菜单栏 / 设置面板背景色（较纸张略有区分）；未提供时回退纸张色。
  Color get panelColor => _panelColor ?? paperColor;

  /// 分段控件选中项底色（略亮的一档）；未提供时按主题明暗派生。
  Color get segActiveColor =>
      _segActiveColor ??
      (isDark
          ? Color.alphaBlend(Colors.white.withValues(alpha: 0.08), panelColor)
          : Color.alphaBlend(Colors.white.withValues(alpha: 0.6), paperColor));

  Color get subTextColor => textColor.withValues(alpha: 0.55);

  /// 细分隔线
  Color get dividerColor => textColor.withValues(alpha: 0.09);

  /// 滑块轨道底色
  Color get trackColor => textColor.withValues(alpha: 0.14);

  /// 描边色
  Color get borderColor => textColor.withValues(alpha: 0.16);

  /// 复制并覆盖部分字段，便于业务方基于预设微调。
  ReaderTheme copyWith({
    String? alias,
    String? name,
    Color? paperColor,
    Color? textColor,
    Color? accentColor,
    Color? panelColor,
    Color? segActiveColor,
  }) {
    return ReaderTheme(
      alias: alias ?? this.alias,
      name: name ?? this.name,
      paperColor: paperColor ?? this.paperColor,
      textColor: textColor ?? this.textColor,
      accentColor: accentColor ?? this.accentColor,
      panelColor: panelColor ?? _panelColor,
      segActiveColor: segActiveColor ?? _segActiveColor,
    );
  }

  bool get isDark => paperColor.computeLuminance() < 0.3;

  static const ReaderTheme white = ReaderTheme(
    alias: 'white',
    name: '白',
    paperColor: Color(0xFFFFFFFF),
    textColor: Color(0xFF2B2B2B),
    panelColor: Color(0xFFF7F6F4),
    segActiveColor: Color(0xFFFFFFFF),
  );

  static const ReaderTheme grey = ReaderTheme(
    alias: 'grey',
    name: '灰',
    paperColor: Color(0xFFE8E6E0),
    textColor: Color(0xFF33322E),
    panelColor: Color(0xFFF0EEE8),
    segActiveColor: Color(0xFFFAF9F5),
  );

  static const ReaderTheme yellow = ReaderTheme(
    alias: 'yellow',
    name: '米',
    paperColor: Color(0xFFF2E9DC),
    textColor: Color(0xFF3A322B),
    panelColor: Color(0xFFEFE6D5),
    segActiveColor: Color(0xFFFDFAF3),
  );

  static const ReaderTheme green = ReaderTheme(
    alias: 'green',
    name: '青',
    paperColor: Color(0xFFDDE9E2),
    textColor: Color(0xFF2F3A34),
    panelColor: Color(0xFFD7E4DC),
    segActiveColor: Color(0xFFF1F7F4),
  );

  static const ReaderTheme blue = ReaderTheme(
    alias: 'blue',
    name: '蓝',
    paperColor: Color(0xFFDDE6F2),
    textColor: Color(0xFF2D3540),
    panelColor: Color(0xFFD5E1F0),
    segActiveColor: Color(0xFFF0F4FB),
  );

  static const ReaderTheme night = ReaderTheme(
    alias: 'night',
    name: '夜',
    paperColor: Color(0xFF191712),
    textColor: Color(0xFFB5AB9C),
    panelColor: Color(0xFF221F19),
    segActiveColor: Color(0xFF3A352A),
  );

  static const List<ReaderTheme> presets = <ReaderTheme>[
    white,
    grey,
    yellow,
    green,
    blue,
    night,
  ];

  static ReaderTheme fromAlias(String? alias) {
    return presets.firstWhere(
      (ReaderTheme t) => t.alias == alias,
      orElse: () => yellow,
    );
  }
}
