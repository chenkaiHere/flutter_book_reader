import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/warm_theme.dart';

/// 右下角听书入口：渐变圆形按钮 + 脉冲光环 + 耳机图标。
class ListenFab extends StatefulWidget {
  const ListenFab({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  State<ListenFab> createState() => _ListenFabState();
}

class _ListenFabState extends State<ListenFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          AnimatedBuilder(
            animation: _pulse,
            builder: (BuildContext context, _) {
              final double v = _pulse.value;
              return Transform.scale(
                scale: 1 + v * 0.5,
                child: Opacity(
                  opacity: (0.5 * (1 - v)).clamp(0.0, 1.0),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Warm.accent, width: 2),
                    ),
                  ),
                ),
              );
            },
          ),
          Material(
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: const Color(0x80B3572F),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: widget.onTap,
              child: Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[Warm.accent, Warm.accentDark],
                  ),
                ),
                child: const Icon(
                  Icons.headphones_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 旋转黑胶碟：播放时匀速旋转。
class SpinningDisc extends StatefulWidget {
  const SpinningDisc({super.key, required this.playing, required this.size});
  final bool playing;
  final double size;

  @override
  State<SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void initState() {
    super.initState();
    if (widget.playing) _c.repeat();
  }

  @override
  void didUpdateWidget(SpinningDisc old) {
    super.didUpdateWidget(old);
    if (widget.playing && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.playing && _c.isAnimating) {
      _c.stop();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double hole = widget.size * 0.36;
    return RotationTransition(
      turns: _c,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // 黑胶底盘（径向渐变，旋转对称）。
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: <Color>[
                      Color(0xFF7A5636),
                      Color(0xFF3A2716),
                      Color(0xFF241608),
                    ],
                    stops: <double>[0.30, 0.60, 1.0],
                  ),
                  boxShadow: <BoxShadow>[
                    BoxShadow(
                      color: Color(0x59140C04),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
            // 一道扫光（不对称 → 旋转时可见）。
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: <Color>[
                      Colors.transparent,
                      Colors.white.withValues(alpha: 0.16),
                      Colors.transparent,
                      Colors.transparent,
                    ],
                    stops: const <double>[0.0, 0.06, 0.24, 1.0],
                  ),
                ),
              ),
            ),
            // 偏心小反光点（进一步强化旋转感）。
            Align(
              alignment: const Alignment(0, -0.66),
              child: Container(
                width: widget.size * 0.1,
                height: widget.size * 0.1,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ),
            // 中心孔。
            Container(
              width: hole,
              height: hole,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Warm.sheet,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 均衡条：4 根竖条随播放起伏。
class Equalizer extends StatefulWidget {
  const Equalizer({super.key, required this.playing, required this.color});
  final bool playing;
  final Color color;

  @override
  State<Equalizer> createState() => _EqualizerState();
}

class _EqualizerState extends State<Equalizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  static const List<double> _phases = <double>[0.0, 0.15, 0.3, 0.45];

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 13,
      child: AnimatedBuilder(
        animation: _c,
        builder: (BuildContext context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              for (int i = 0; i < 4; i++) ...<Widget>[
                if (i > 0) const SizedBox(width: 2.5),
                Container(
                  width: 2.5,
                  height: 13 * _barScale(i),
                  decoration: BoxDecoration(
                    color: widget.color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  double _barScale(int i) {
    if (!widget.playing) return 0.4;
    final double v = (_c.value + _phases[i]) % 1.0;
    return 0.35 + 0.65 * (0.5 * (1 + math.sin(v * 2 * math.pi)));
  }
}
