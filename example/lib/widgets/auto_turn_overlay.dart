import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// 让屏幕在「自动翻页」期间保持常亮。
///
/// 常亮插件（wakelock_plus）由**示例**引入——插件本身不依赖任何原生库，只通过
/// [BookReaderController.isAutoTurning] 暴露开关状态；这里据此开/关常亮即可。
/// 自动翻页的开启入口、速度设置、退出等 UI 都已内建在阅读器里，无需示例再画。
class AutoTurnOverlay extends StatefulWidget {
  const AutoTurnOverlay({
    super.key,
    required this.controller,
    required this.child,
  });

  final BookReaderController controller;
  final Widget child;

  @override
  State<AutoTurnOverlay> createState() => _AutoTurnOverlayState();
}

class _AutoTurnOverlayState extends State<AutoTurnOverlay> {
  bool _wakeEnabled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    if (_wakeEnabled) WakelockPlus.disable();
    super.dispose();
  }

  void _onChange() {
    // 屏幕常亮跟随自动翻页开关。
    final bool want = widget.controller.isAutoTurning;
    if (want != _wakeEnabled) {
      _wakeEnabled = want;
      WakelockPlus.toggle(enable: want);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
