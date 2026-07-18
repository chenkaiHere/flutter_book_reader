import 'package:flutter/material.dart';

import '../theme/warm_theme.dart';

/// 「书本」封面：主色渐变 + 左侧书脊暗条 + 内描边 + 居中衬线书名，带投影。
///
/// 设计稿中列表、网格、继续阅读卡、详情弹窗都复用同一封面观感，故抽成组件。
/// [width] 为空时铺满父级（网格用 aspectRatio 约束）。
class BookCover extends StatelessWidget {
  const BookCover({
    super.key,
    required this.title,
    required this.color,
    this.width,
    this.height,
    this.radius = 7,
    this.fontSize = 15,
    this.showShadow = true,
    this.badge,
  });

  final String title;
  final Color color;
  final double? width;
  final double? height;
  final double radius;
  final double fontSize;
  final bool showShadow;

  /// 右下角小角标（如进度百分比）。
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    // 书脊在左侧，故左内边距更大，让书名视觉居中于「纸面」。
    final double spine = (radius + 5).clamp(6, 10).toDouble();
    final Widget cover = DecoratedBox(
      decoration: BoxDecoration(
        gradient: Warm.coverGradient(color),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: showShadow ? Warm.cover : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            // 书脊暗条
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: spine,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[Color(0x52000000), Color(0x08000000)],
                  ),
                ),
              ),
            ),
            // 内描边
            Positioned(
              left: spine + 1,
              right: 6,
              top: 6,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0x47FFFFFF)),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 书名
            Padding(
              padding: EdgeInsets.fromLTRB(spine + 2, 8, 8, 8),
              child: Center(
                child: Text(
                  title,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style:
                      Warm.serif(
                        size: fontSize,
                        weight: FontWeight.w700,
                        color: Colors.white,
                        height: 1.22,
                      ).copyWith(
                        shadows: const <Shadow>[
                          Shadow(
                            color: Color(0x66000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                ),
              ),
            ),
            if (badge != null) Positioned(right: 6, bottom: 6, child: badge!),
          ],
        ),
      ),
    );

    if (width == null && height == null) return cover;
    return SizedBox(width: width, height: height, child: cover);
  }
}

/// 封面右下角的进度角标（如「34%」）。
class CoverBadge extends StatelessWidget {
  const CoverBadge(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0x8C140A05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: Warm.sans(
          size: 10,
          weight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
