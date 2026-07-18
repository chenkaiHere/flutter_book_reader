import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bookshelf_page.dart';
import 'theme/warm_theme.dart';

void main() {
  runApp(const ReadBookApp());
}

class ReadBookApp extends StatelessWidget {
  const ReadBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: Warm.accent,
      brightness: Brightness.light,
    ).copyWith(primary: Warm.accent, surface: Warm.bg, onSurface: Warm.ink);
    return MaterialApp(
      title: 'ReadBook 阅读器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: Warm.bg,
        // 默认正文用思源黑体；标题处按需覆盖为思源宋体。
        textTheme: GoogleFonts.notoSansScTextTheme(
          ThemeData.light().textTheme,
        ).apply(bodyColor: Warm.ink, displayColor: Warm.ink),
      ),
      home: const BookshelfPage(),
    );
  }
}
