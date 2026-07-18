import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 一种可选语言的展示信息（用于语言选择弹窗）。
class AppLanguage {
  const AppLanguage(this.locale, this.nativeName, this.englishName, this.flag);

  final Locale locale;

  /// 语言自身写法（如 “Español”）
  final String nativeName;

  /// 英文名（副标题）
  final String englishName;

  /// 旗帜 emoji
  final String flag;
}

/// 世界主流语言（使用人数前十）+ 日语、韩语，共 12 种。
const List<AppLanguage> kAppLanguages = <AppLanguage>[
  AppLanguage(Locale('en'), 'English', 'English', '🇬🇧'),
  AppLanguage(Locale('zh'), '中文（简体）', 'Chinese', '🇨🇳'),
  AppLanguage(Locale('hi'), 'हिन्दी', 'Hindi', '🇮🇳'),
  AppLanguage(Locale('es'), 'Español', 'Spanish', '🇪🇸'),
  AppLanguage(Locale('fr'), 'Français', 'French', '🇫🇷'),
  AppLanguage(Locale('ar'), 'العربية', 'Arabic', '🇸🇦'),
  AppLanguage(Locale('bn'), 'বাংলা', 'Bengali', '🇧🇩'),
  AppLanguage(Locale('pt'), 'Português', 'Portuguese', '🇧🇷'),
  AppLanguage(Locale('ru'), 'Русский', 'Russian', '🇷🇺'),
  AppLanguage(Locale('ur'), 'اردو', 'Urdu', '🇵🇰'),
  AppLanguage(Locale('ja'), '日本語', 'Japanese', '🇯🇵'),
  AppLanguage(Locale('ko'), '한국어', 'Korean', '🇰🇷'),
];

/// 全局语言控制：切换后通知 [MaterialApp] 重建，并持久化到 SharedPreferences。
class LocaleController {
  LocaleController._();

  static const String _key = 'app_locale';

  /// 当前语言；null 表示跟随系统。
  static final ValueNotifier<Locale?> notifier = ValueNotifier<Locale?>(null);

  /// 启动时读取上次选择的语言。
  static Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? code = prefs.getString(_key);
    if (code != null && code.isNotEmpty) {
      notifier.value = Locale(code);
    }
  }

  /// 切换语言并持久化。
  static Future<void> set(Locale locale) async {
    notifier.value = locale;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
