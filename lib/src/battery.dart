import 'package:flutter/foundation.dart';

/// 电量信息：由业务方注入（如用 `battery_plus` 采集）。阅读器只负责在页脚绘制。
///
/// 传给 `BookReader(battery: ValueListenable<ReaderBatteryInfo?>)`；值为 null（或未传
/// 该监听）时不显示电量。用 [ValueListenable] 便于电量变化时只重绘页脚、不触发正文重排。
@immutable
class ReaderBatteryInfo {
  const ReaderBatteryInfo({required this.level, required this.charging});

  /// 电量百分比 0–100。
  final int level;

  /// 是否正在充电。
  final bool charging;

  @override
  bool operator ==(Object other) =>
      other is ReaderBatteryInfo &&
      other.level == level &&
      other.charging == charging;

  @override
  int get hashCode => Object.hash(level, charging);
}
