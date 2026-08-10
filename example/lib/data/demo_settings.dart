import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 示例 App 的演示开关。
///
/// 这些开关只为了演示插件能力，真实业务不需要它们（付费章是否加锁由业务自己的
/// 订阅状态决定）。与 `LocaleController` 同样的模式：静态 [ValueNotifier] + 持久化。
class DemoSettings {
  DemoSettings._();

  static const String _lockKey = 'demo_chapter_lock_enabled';

  /// 是否开启「章节解锁（付费章）」演示。默认关闭 —— 平时阅读不被解锁页打断。
  static final ValueNotifier<bool> chapterLockEnabled =
      ValueNotifier<bool>(false);

  /// 启动时读取上次的选择。
  static Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    chapterLockEnabled.value = prefs.getBool(_lockKey) ?? false;
  }

  /// 切换并持久化。
  static Future<void> setChapterLockEnabled(bool value) async {
    chapterLockEnabled.value = value;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_lockKey, value);
  }
}
