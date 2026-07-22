import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';

import '../l10n/app_localizations.dart';
import '../listen/listen_service.dart';
import '../theme/warm_theme.dart';
import 'listen_widgets.dart';

/// 阅读页内的听书控件：右下角入口按钮 + 底部完整播放条。二者都只是驱动全局
/// [listenService]；mini 气泡由全局 [ListenHost] 负责，故退出阅读页也不消失。
class ListenOverlay extends StatefulWidget {
  const ListenOverlay({
    super.key,
    required this.controller,
    required this.bookId,
    required this.bookTitle,
    required this.source,
    required this.localeCode,
    required this.child,
  });

  final BookReaderController controller;
  final Object bookId;
  final String bookTitle;
  final BookSource source;
  final String localeCode;
  final Widget child;

  @override
  State<ListenOverlay> createState() => _ListenOverlayState();
}

class _ListenOverlayState extends State<ListenOverlay> {
  bool _panelHidesFab = false;
  Timer? _panelTimer;

  // 上次已下发跟读高亮的（章, 句），避免重复下发同一句导致定位回跳。
  int _lastMarkCh = -1;
  String? _lastMarkFrag;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChange);
    listenService.addListener(_onChange);
    listenService.setInReader(true);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChange);
    listenService.removeListener(_onChange);
    _panelTimer?.cancel();
    // 离开阅读页：交回全局 mini（不停止播放）。
    listenService.setInReader(false);
    listenService.setExpanded(false);
    super.dispose();
  }

  void _onChange() {
    final bool expanded = widget.controller.isMenuPanelExpanded;
    if (expanded) {
      _panelTimer?.cancel();
      _panelHidesFab = true;
    } else if (_panelHidesFab) {
      _panelTimer?.cancel();
      _panelTimer = Timer(const Duration(milliseconds: 280), () {
        if (mounted) setState(() => _panelHidesFab = false);
      });
    }
    _syncReading();
    if (!mounted) return;
    // 只有 idle / postFrame 阶段可安全 setState；build/layout（如 ReaderMenu
    // .didUpdateWidget 转发面板状态）、拖动重采样指针事件的 transientCallbacks 等
    // 被锁阶段都需推迟到帧末，否则单发通知会丢失、全屏条不收起。
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

  /// 把「当前朗读句」下发给阅读器做跟读高亮 + 自动翻页；仅当听的是本书时。
  void _syncReading() {
    final bool isThisBook =
        listenService.active && listenService.bookId == widget.bookId;
    if (!isThisBook) {
      if (_lastMarkFrag != null) {
        widget.controller.clearReading();
        _lastMarkFrag = null;
        _lastMarkCh = -1;
      }
      return;
    }
    final int ci = listenService.chapterIndex;
    final String frag = listenService.currentFragment;
    if (frag.isEmpty || (ci == _lastMarkCh && frag == _lastMarkFrag)) return;
    _lastMarkCh = ci;
    _lastMarkFrag = frag;
    widget.controller.markReading(ci, frag);
  }

  void _startListening() {
    listenService.start(
      bookId: widget.bookId,
      bookTitle: widget.bookTitle,
      source: widget.source,
      startChapter: widget.controller.chapterIndex,
      localeCode: widget.localeCode,
      // 从当前正在阅读的这一页开始，而非本章开头。
      startText: widget.controller.currentPageText,
    );
    widget.controller.closeMenu();
  }

  @override
  Widget build(BuildContext context) {
    final bool isThisBook =
        listenService.active && listenService.bookId == widget.bookId;
    final bool showFull = isThisBook && listenService.expanded;
    // 入口按钮：本书未在听书时（无论空闲还是在听别的书）唤起菜单即可开始。
    final bool showFab =
        !isThisBook && widget.controller.isMenuVisible && !_panelHidesFab;

    return Stack(
      children: <Widget>[
        // 侦测阅读区触碰：本书完整条展开时任意触碰（唤起菜单 / 翻页）→ 收成全局 mini。
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (_) {
              if (isThisBook && listenService.expanded) {
                listenService.setExpanded(false);
              }
            },
            child: widget.child,
          ),
        ),
        if (showFull)
          Positioned(
            left: 16,
            right: 16,
            bottom: 22,
            child: SafeArea(child: _playbackBar()),
          ),
        Positioned(
          right: 20,
          bottom: 200,
          child: IgnorePointer(
            ignoring: !showFab,
            child: AnimatedScale(
              scale: showFab ? 1.0 : 0.7,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: showFab ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 180),
                child: ListenFab(onTap: _startListening),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _playbackBar() {
    return Material(
      color: Warm.sheet,
      borderRadius: BorderRadius.circular(20),
      elevation: 8,
      shadowColor: const Color(0x33140C04),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: <Widget>[
            SpinningDisc(playing: listenService.playing, size: 42),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        AppLocalizations.of(context).listeningNow,
                        style: Warm.serif(size: 15.5, weight: FontWeight.w700),
                      ),
                      const SizedBox(width: 8),
                      Equalizer(
                        playing: listenService.playing,
                        color: Warm.accent,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listenService.chapterTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Warm.sans(size: 12, color: Warm.muted2),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: listenService.cycleSpeed,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Warm.ink.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                ),
                child: Text(
                  listenService.speedLabel,
                  style: Warm.sans(
                    size: 13.5,
                    weight: FontWeight.w700,
                    color: Warm.ink,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: listenService.togglePlay,
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Warm.accent,
                  shape: BoxShape.circle,
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x66B3572F),
                      blurRadius: 10,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  listenService.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
            IconButton(
              onPressed: listenService.stop,
              icon: const Icon(Icons.close_rounded, color: Warm.muted),
              iconSize: 20,
              splashRadius: 20,
            ),
          ],
        ),
      ),
    );
  }
}
