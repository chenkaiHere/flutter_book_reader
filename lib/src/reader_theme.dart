import 'package:flutter/material.dart';

/// 阅读主题：纸张背景色 + 正文文字色。
///
/// 参考自 tapon 阅读器的纸张配色（灰/黄/绿/蓝），并补充了夜间主题。
class ReaderTheme {
  const ReaderTheme({
    required this.alias,
    required this.name,
    required this.paperColor,
    required this.textColor,
    this.accentColor = const Color(0xFFE0662B),
  });

  final String alias;
  final String name;

  /// 阅读纸张背景颜色
  final Color paperColor;

  /// 正文文字颜色
  final Color textColor;

  /// 强调色（进度条、选中态、目录高亮等），支持白标定制
  final Color accentColor;

  Color get subTextColor => textColor.withValues(alpha: 0.55);

  /// 复制并覆盖部分字段，便于业务方基于预设微调。
  ReaderTheme copyWith({
    String? alias,
    String? name,
    Color? paperColor,
    Color? textColor,
    Color? accentColor,
  }) {
    return ReaderTheme(
      alias: alias ?? this.alias,
      name: name ?? this.name,
      paperColor: paperColor ?? this.paperColor,
      textColor: textColor ?? this.textColor,
      accentColor: accentColor ?? this.accentColor,
    );
  }

  bool get isDark => paperColor.computeLuminance() < 0.3;

  static const ReaderTheme white = ReaderTheme(
    alias: 'white',
    name: '白',
    paperColor: Color(0xFFFBFBF9),
    textColor: Color(0xFF2B2B2B),
  );

  static const ReaderTheme grey = ReaderTheme(
    alias: 'grey',
    name: '灰',
    paperColor: Color(0xFFF0F0F0),
    textColor: Color(0xFF33373D),
  );

  static const ReaderTheme yellow = ReaderTheme(
    alias: 'yellow',
    name: '黄',
    paperColor: Color(0xFFF5EDD8),
    textColor: Color(0xFF4A4235),
  );

  static const ReaderTheme green = ReaderTheme(
    alias: 'green',
    name: '绿',
    paperColor: Color(0xFFDBE7E2),
    textColor: Color(0xFF2F3D38),
  );

  static const ReaderTheme blue = ReaderTheme(
    alias: 'blue',
    name: '蓝',
    paperColor: Color(0xFFE5F1FE),
    textColor: Color(0xFF2C3A47),
  );

  static const ReaderTheme night = ReaderTheme(
    alias: 'night',
    name: '夜',
    paperColor: Color(0xFF1B1B1D),
    textColor: Color(0xFFA8A8A8),
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
