import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../battery.dart';

/// 把宿主注入的电量监听沿组件树下传，供页脚 [BatteryIndicator] 读取（内部管道）。
class ReaderBatteryScope extends InheritedWidget {
  const ReaderBatteryScope({
    super.key,
    required this.battery,
    required super.child,
  });

  final ValueListenable<ReaderBatteryInfo?>? battery;

  static ValueListenable<ReaderBatteryInfo?>? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ReaderBatteryScope>()
      ?.battery;

  @override
  bool updateShouldNotify(ReaderBatteryScope oldWidget) =>
      oldWidget.battery != battery;
}

/// 页脚电量指示器：
/// - 充电中 → 电池内显示**绿色闪电**；
/// - 未充电 → 按电量比例填充，电量**数字显示在电池内部**。
class BatteryIndicator extends StatelessWidget {
  const BatteryIndicator({super.key, required this.info, required this.color});

  final ReaderBatteryInfo info;

  /// 基础色（页脚字色）：描边 / 数字 / 电量填充都基于它；充电闪电用绿色。
  final Color color;

  static const Color _chargingGreen = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    final int level = info.level.clamp(0, 100);
    final Color outline = color.withValues(alpha: 0.55);

    return SizedBox(
      width: 30,
      height: 14,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: outline, width: 1),
                borderRadius: BorderRadius.circular(3.5),
              ),
              child: Stack(
                children: <Widget>[
                  // 未充电：按电量比例的淡色填充（数字覆盖其上）。
                  if (!info.charging)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: level / 100,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.28),
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),
                    ),
                  // 充电 → 绿色闪电；未充电 → 电量数字，均居中于电池内部。
                  Center(
                    child: info.charging
                        ? const Icon(
                            Icons.bolt,
                            size: 12,
                            color: _chargingGreen,
                          )
                        : Text(
                            '$level',
                            style: TextStyle(
                              fontSize: 8.5,
                              height: 1.0,
                              fontWeight: FontWeight.w700,
                              color: color,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          // 电池正极小凸点
          Container(
            width: 2,
            height: 6,
            margin: const EdgeInsets.only(left: 1.5),
            decoration: BoxDecoration(
              color: outline,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
