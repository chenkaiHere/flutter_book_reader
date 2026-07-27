part of '../book_reader_widget.dart';

/// 系统 UI（状态栏 / 底部导航栏）沉浸态管理。
///
/// 进入阅读页即隐藏系统栏让正文铺满整屏；唤起菜单时按配置以 `edgeToEdge` 叠加
/// 显示系统栏（不改变窗口尺寸、不触发重排）；退出时恢复系统栏与默认样式。
/// 抽成 mixin 后主 [State] 不必再关心 [SystemChrome] 细节。
mixin _ImmersiveSystemUi on State<BookReader> {
  // 由宿主 State 提供：菜单可见性。
  ValueNotifier<bool> get _menuVisible;

  /// 依据「是否配置了菜单时显示系统栏」与「菜单当前是否可见」应用系统 UI 模式。
  void _enterImmersive() {
    if (widget.showSystemBarsWithMenu && _menuVisible.value) {
      // 菜单可见：用 edgeToEdge 显示系统栏——系统栏作为**覆盖层**出现，窗口仍是全屏，
      // 正文画在栏下方。这样系统栏显隐不会改变窗口尺寸，正文不会重新分页 / 跳页。
      // （若用 SystemUiMode.manual，系统栏会占用布局空间挤小窗口，导致重排跳页。）
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } else {
      // 沉浸态：隐藏系统状态栏与导航栏，正文铺满整屏。
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

  /// 状态栏 + 底部系统导航栏都用纸张色（沉浸），图标明暗随主题。
  SystemUiOverlayStyle _overlayStyle(ReaderTheme t) {
    final Brightness icons = t.isDark ? Brightness.light : Brightness.dark;
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: icons,
      statusBarBrightness: t.isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: t.paperColor,
      systemNavigationBarIconBrightness: icons,
    );
  }

  /// 离开阅读页：恢复系统栏显示，并把状态栏 / 底部导航栏重置为“白底黑字”默认样式，
  /// 否则阅读页设置的纸张色会残留到退出后的页面。
  void _restoreSystemUiOnExit() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }
}
