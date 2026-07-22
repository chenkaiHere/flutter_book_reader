import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../listen/listen_service.dart';
import '../theme/warm_theme.dart';
import 'listen_widgets.dart';

/// 全局听书宿主：挂在 [MaterialApp.builder]（Navigator 之上），因此 mini 气泡跨路由常驻，
/// 退出阅读页也不消失。仅当「听书中」且当前不是阅读页内的完整播放条态时显示 mini。
class ListenHost extends StatefulWidget {
  const ListenHost({super.key, required this.child});
  final Widget child;

  @override
  State<ListenHost> createState() => _ListenHostState();
}

class _ListenHostState extends State<ListenHost> {
  static const double _miniW = 132;
  static const double _miniH = 52;

  Offset? _pos;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    listenService.addListener(_onSvc);
  }

  @override
  void dispose() {
    listenService.removeListener(_onSvc);
    super.dispose();
  }

  void _onSvc() {
    if (!mounted) return;
    // 只有 idle / postFrame 阶段可安全 setState；其余阶段（widget 卸载时的
    // finalizeTree、以及拖动时重采样投递指针事件所处的 transientCallbacks 等）
    // 树都被锁，直接 setState 会被丢弃 —— 推迟到本帧结束后再刷新。否则暂停后
    // 「收起 / 退出」只发一次通知，一旦落在被锁阶段就丢失，mini 不再出现。
    final SchedulerPhase phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.idle ||
        phase == SchedulerPhase.postFrameCallbacks) {
      setState(() {});
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  Offset _defaultPos(Size size) => Offset(12, size.height * 0.6);

  @override
  Widget build(BuildContext context) {
    // 完整播放条在阅读页内展示时，隐藏全局 mini（避免重复）。其余时候（收起态、或不在
    // 阅读页）只要在听书就显示 mini。
    final bool showMini =
        listenService.active &&
        !(listenService.expanded && listenService.inReader);
    // LayoutBuilder 包在外层：AnimatedPositioned 必须是 Stack 的直接子节点，
    // 否则 Positioned 的 parentData 失效，定位与拖动都会失灵。
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          children: <Widget>[
            Positioned.fill(child: widget.child),
            if (showMini) _mini(constraints.biggest),
          ],
        );
      },
    );
  }

  Widget _mini(Size size) {
    final double topMin = MediaQuery.of(context).padding.top + 12;
    final Offset pos = _pos ?? _defaultPos(size);
    return AnimatedPositioned(
      duration: _dragging ? Duration.zero : const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      left: pos.dx,
      top: pos.dy,
      child: GestureDetector(
        onPanStart: (_) => setState(() {
          _dragging = true;
          _pos = pos;
        }),
        onPanUpdate: (DragUpdateDetails d) => setState(() {
          final Offset base = _pos ?? _defaultPos(size);
          _pos = Offset(
            (base.dx + d.delta.dx).clamp(12.0, size.width - _miniW - 12),
            (base.dy + d.delta.dy).clamp(topMin, size.height - _miniH - 12),
          );
        }),
        onPanEnd: (_) => setState(() {
          _dragging = false;
          final Offset p = _pos ?? _defaultPos(size);
          final double snapX = (p.dx + _miniW / 2) < size.width / 2
              ? 12.0
              : size.width - _miniW - 12;
          _pos = Offset(snapX, p.dy);
        }),
        child: Material(
          color: Warm.sheet,
          borderRadius: BorderRadius.circular(28),
          elevation: 8,
          shadowColor: const Color(0x33140C04),
          child: SizedBox(
            width: _miniW,
            height: _miniH,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // 点碟子：在阅读页内直接展开为完整条；不在阅读页则跳转到该书阅读页并展开。
                GestureDetector(
                  onTap: () {
                    if (listenService.inReader) {
                      listenService.setExpanded(true);
                    } else {
                      listenService.requestOpenReader();
                    }
                  },
                  child: SpinningDisc(playing: listenService.playing, size: 34),
                ),
                GestureDetector(
                  onTap: listenService.togglePlay,
                  child: Icon(
                    listenService.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Warm.ink,
                    size: 24,
                  ),
                ),
                GestureDetector(
                  onTap: listenService.stop,
                  child: const Icon(
                    Icons.close_rounded,
                    color: Warm.muted,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
