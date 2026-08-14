import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 页脚电量角标：数据由宿主注入，不传则完全不显示（插件不依赖任何原生电量库）。
void main() {
  Future<void> mount(
    WidgetTester tester,
    ValueListenable<ReaderBatteryInfo?>? battery,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        battery: battery,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('不传 battery 时页脚没有电量角标', (WidgetTester tester) async {
    await mount(tester, null);
    expect(find.text('80'), findsNothing);
  });

  testWidgets('传入但值为 null 时同样不显示', (WidgetTester tester) async {
    final ValueNotifier<ReaderBatteryInfo?> feed =
        ValueNotifier<ReaderBatteryInfo?>(null);
    addTearDown(feed.dispose);
    await mount(tester, feed);
    expect(find.textContaining('%'), findsWidgets, reason: '进度百分比仍在');
    expect(find.text('80'), findsNothing);
  });

  testWidgets('未充电时显示电量数字', (WidgetTester tester) async {
    final ValueNotifier<ReaderBatteryInfo?> feed =
        ValueNotifier<ReaderBatteryInfo?>(
      const ReaderBatteryInfo(level: 80, charging: false),
    );
    addTearDown(feed.dispose);
    await mount(tester, feed);
    expect(find.text('80'), findsOneWidget);
  });

  testWidgets('充电时改为显示闪电图标，不显示数字', (WidgetTester tester) async {
    final ValueNotifier<ReaderBatteryInfo?> feed =
        ValueNotifier<ReaderBatteryInfo?>(
      const ReaderBatteryInfo(level: 42, charging: true),
    );
    addTearDown(feed.dispose);
    await mount(tester, feed);
    expect(find.text('42'), findsNothing);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });

  testWidgets('电量变化只需更新数值，无需重建阅读器', (WidgetTester tester) async {
    final ValueNotifier<ReaderBatteryInfo?> feed =
        ValueNotifier<ReaderBatteryInfo?>(
      const ReaderBatteryInfo(level: 80, charging: false),
    );
    addTearDown(feed.dispose);
    await mount(tester, feed);
    expect(find.text('80'), findsOneWidget);

    feed.value = const ReaderBatteryInfo(level: 15, charging: false);
    await tester.pump();
    expect(find.text('80'), findsNothing);
    expect(find.text('15'), findsOneWidget);
  });

  testWidgets('极端电量值也能正常渲染', (WidgetTester tester) async {
    final ValueNotifier<ReaderBatteryInfo?> feed =
        ValueNotifier<ReaderBatteryInfo?>(
      const ReaderBatteryInfo(level: 0, charging: false),
    );
    addTearDown(feed.dispose);
    await mount(tester, feed);
    expect(find.text('0'), findsOneWidget);

    feed.value = const ReaderBatteryInfo(level: 100, charging: false);
    await tester.pump();
    expect(find.text('100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
