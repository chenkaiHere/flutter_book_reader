import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';

/// 用 `battery_plus` 采集电量，暴露成 `ValueListenable<ReaderBatteryInfo?>` 喂给
/// `BookReader(battery: ...)`。充电状态变化即刷新，另每 60s 轮询一次电量百分比。
///
/// 采集失败（如 Web 浏览器不支持电量 API）时保持为 null —— 阅读器据此不显示电量。
class BatteryFeed {
  final Battery _battery = Battery();
  final ValueNotifier<ReaderBatteryInfo?> notifier =
      ValueNotifier<ReaderBatteryInfo?>(null);

  StreamSubscription<BatteryState>? _sub;
  Timer? _timer;

  void start() {
    _refresh();
    _sub = _battery.onBatteryStateChanged.listen(
      (_) => _refresh(),
      onError: (_) {},
    );
    _timer = Timer.periodic(const Duration(seconds: 60), (_) => _refresh());
  }

  Future<void> _refresh() async {
    try {
      final int level = await _battery.batteryLevel;
      final BatteryState state = await _battery.batteryState;
      final bool charging =
          state == BatteryState.charging || state == BatteryState.full;
      notifier.value = ReaderBatteryInfo(level: level, charging: charging);
    } catch (_) {
      // 平台不支持 / 采集失败：保持 null，不显示电量。
    }
  }

  void dispose() {
    _sub?.cancel();
    _timer?.cancel();
    notifier.dispose();
  }
}
