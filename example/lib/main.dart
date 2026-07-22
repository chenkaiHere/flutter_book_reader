import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'bookshelf_page.dart';
import 'l10n/app_locales.dart';
import 'l10n/app_localizations.dart';
import 'theme/warm_theme.dart';
import 'widgets/listen_host.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 应用启动即设为沉浸式边到边 + 白底黑字系统栏，与退出阅读页后的样式一致，
  // 避免首次进入书架时出现状态栏灰色遮罩 / 黑色底部导航栏。
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(kAppSystemUi);
  await LocaleController.load(); // 读取上次选择的语言
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
    return ValueListenableBuilder<Locale?>(
      valueListenable: LocaleController.notifier,
      builder: (BuildContext context, Locale? locale, _) {
        return MaterialApp(
          title: 'ReadBook',
          debugShowCheckedModeBanner: false,
          scaffoldMessengerKey: rootMessengerKey,
          // 未手动选择时 locale 为 null → 跟随系统语言；
          // 系统语言不在支持列表内则回退英文（而非 supportedLocales 的首个 ar）。
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          localeResolutionCallback: (Locale? want, Iterable<Locale> supported) {
            if (want != null) {
              for (final Locale l in supported) {
                if (l.languageCode == want.languageCode) return l;
              }
            }
            return const Locale('en');
          },
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: scheme,
            scaffoldBackgroundColor: Warm.bg,
            // 默认正文用思源黑体；标题处按需覆盖为思源宋体。
            textTheme: GoogleFonts.notoSansScTextTheme(
              ThemeData.light().textTheme,
            ).apply(bodyColor: Warm.ink, displayColor: Warm.ink),
          ),
          // 全局听书宿主：在 Navigator 之上叠加 mini 气泡，跨路由常驻。
          builder: (BuildContext context, Widget? child) =>
              ListenHost(child: child ?? const SizedBox.shrink()),
          home: const BookshelfPage(),
        );
      },
    );
  }
}
