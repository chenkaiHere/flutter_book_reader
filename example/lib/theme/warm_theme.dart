import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 「暖纸」设计语言的设计令牌（颜色 / 字体 / 渐变），来自设计稿 PhoneWarm。
///
/// 全站书架侧 UI（书架页、书卡、封面、目录/详情弹窗、导入弹窗）统一取此处的值，
/// 改主题只需改这里。
class Warm {
  Warm._();

  // ————————————————————— 颜色 —————————————————————
  /// 页面底色（暖米）
  static const Color bg = Color(0xFFF2E9DC);

  /// 卡片 / 输入框底色（更亮的米）
  static const Color card = Color(0xFFFBF5EC);

  /// 弹层底色
  static const Color sheet = Color(0xFFF6EFE3);

  /// 主强调色（赤陶）
  static const Color accent = Color(0xFFB3572F);
  static const Color accentDark = Color(0xFF944522);

  /// 正文主色（暖褐）
  static const Color ink = Color(0xFF3A322B);

  /// 次级文字（浅褐）
  static const Color ink2 = Color(0xFF786C5E);

  /// 弱化文字（灰褐）
  static const Color muted = Color(0xFFA2957F);
  static const Color muted2 = Color(0xFF9C8F7D);

  /// 分段控件轨道底色
  static const Color track = Color(0xFFECE0CF);

  /// 细描边
  static const Color hairline = Color(0x0F3A322B); // rgba(58,50,43,.06)

  // ————————————————————— 渐变 —————————————————————
  /// 主按钮 / 播放圆钮渐变
  static const LinearGradient btnGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFC9743F), Color(0xFFA94E26)],
  );

  /// 进度条渐变
  static const LinearGradient progressGradient = LinearGradient(
    colors: <Color>[Color(0xFFC9743F), Color(0xFFB3572F)],
  );

  /// 继续阅读卡片背景渐变
  static const LinearGradient contCardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: <Color>[Color(0xFFFFFAF2), Color(0xFFF4E4CF)],
  );

  /// 封面渐变：由封面主色派生（深色下压做书脊感）。
  static LinearGradient coverGradient(Color base) {
    final HSLColor hsl = HSLColor.fromColor(base);
    final Color c1 = hsl
        .withLightness((hsl.lightness + 0.06).clamp(0.0, 1.0))
        .toColor();
    final Color c2 = hsl
        .withLightness((hsl.lightness - 0.16).clamp(0.0, 1.0))
        .toColor();
    return LinearGradient(
      begin: const Alignment(-0.6, -1),
      end: const Alignment(0.6, 1),
      colors: <Color>[c1, c2],
    );
  }

  // ————————————————————— 字体 —————————————————————
  /// 系统衬线中文字体回退（思源宋体下载失败/未就绪时，用设备内置宋体，避免豆腐块）。
  static const List<String> _serifFallback = <String>[
    'Songti SC', // iOS / macOS
    'STSong',
    'SimSun', // Windows
    'Noto Serif CJK SC', // Android / Linux
    'Noto Serif SC',
    'serif',
  ];

  /// 系统无衬线中文字体回退。
  static const List<String> _sansFallback = <String>[
    'PingFang SC', // iOS / macOS
    'Heiti SC',
    'Microsoft YaHei', // Windows
    'Noto Sans CJK SC', // Android / Linux
    'Noto Sans SC',
    'sans-serif',
  ];

  /// 衬线（思源宋体）——用于标题、书名、栏目名。
  static TextStyle serif({
    double size = 16,
    FontWeight weight = FontWeight.w700,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.notoSerifSc(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  ).copyWith(fontFamilyFallback: _serifFallback);

  /// 无衬线（思源黑体）——用于正文、说明、次级信息。
  static TextStyle sans({
    double size = 14,
    FontWeight weight = FontWeight.w400,
    Color color = ink,
    double? height,
    double? letterSpacing,
  }) => GoogleFonts.notoSansSc(
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: height,
    letterSpacing: letterSpacing,
  ).copyWith(fontFamilyFallback: _sansFallback);

  // ————————————————————— 阴影 —————————————————————
  static List<BoxShadow> softCard = <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF5A3C1E).withValues(alpha: 0.06),
      blurRadius: 18,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> cover = <BoxShadow>[
    BoxShadow(
      color: const Color(0xFF3C2814).withValues(alpha: 0.24),
      blurRadius: 14,
      offset: const Offset(0, 6),
    ),
  ];
}
