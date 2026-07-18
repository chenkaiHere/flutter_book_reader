import 'package:flutter/material.dart';

import '../theme/warm_theme.dart';

/// 暖色渐变进度条。[value] 取值 0..1。
class WarmProgressBar extends StatelessWidget {
  const WarmProgressBar({super.key, required this.value, this.height = 6});

  final double value;
  final double height;

  @override
  Widget build(BuildContext context) {
    final double v = value.clamp(0.0, 1.0);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: Container(
        height: height,
        color: const Color(0x24784028), // rgba(120,80,40,.14)
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          // 有进度时至少露一点，视觉上不至于完全空。
          widthFactor: v <= 0 ? 0 : v.clamp(0.02, 1.0),
          child: const DecoratedBox(
            decoration: BoxDecoration(gradient: Warm.progressGradient),
          ),
        ),
      ),
    );
  }
}

/// 赤陶描边小标签（如「本地」）。
class TagChip extends StatelessWidget {
  const TagChip(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Warm.accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Warm.sans(size: 11, weight: FontWeight.w600, color: Warm.accent),
      ),
    );
  }
}
