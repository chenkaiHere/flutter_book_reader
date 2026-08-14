import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/widgets/auto_turn_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 自动阅读时的倒计时竖线。它**只在竖屏 + 分页模式**出现，因此测试必须显式把
/// 测试窗口设成竖屏 —— 默认的 800×600 是横屏，进度条不会渲染。
void main() {
  /// 把测试窗口设为竖屏，并在用例结束后复位。
  void usePortrait(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);
  }

  Future<BookReaderController> mount(WidgetTester tester) async {
    final BookReaderController controller = BookReaderController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        controller: controller,
      ),
    ));
    await tester.pumpAndSettle();
    return controller;
  }

  testWidgets('未开启自动阅读时不显示进度条', (WidgetTester tester) async {
    usePortrait(tester);
    await mount(tester);
    expect(find.byType(AutoTurnProgressBar), findsNothing);
  });

  testWidgets('竖屏 + 分页模式下开启自动阅读会显示进度条', (WidgetTester tester) async {
    usePortrait(tester);
    final BookReaderController c = await mount(tester);
    c.startAutoTurn(const Duration(seconds: 4));
    await tester.pump();
    expect(find.byType(AutoTurnProgressBar), findsOneWidget);

    c.stopAutoTurn();
    await tester.pump();
    expect(find.byType(AutoTurnProgressBar), findsNothing);
  });

  testWidgets('横屏下不显示（避免遮挡正文）', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final BookReaderController c = await mount(tester);
    c.startAutoTurn(const Duration(seconds: 4));
    await tester.pump();
    expect(find.byType(AutoTurnProgressBar), findsNothing);

    c.stopAutoTurn();
    await tester.pump();
  });

  testWidgets('上下滚动模式下不显示（该模式为平滑自动滚动，无「本页倒计时」概念）', (WidgetTester tester) async {
    usePortrait(tester);
    ReaderConfig.instance.setFlipType(FlipType.scrollVertical);
    addTearDown(
      () => ReaderConfig.instance.setFlipType(FlipType.slideHorizontal),
    );

    final BookReaderController c = await mount(tester);
    c.startAutoTurn(const Duration(seconds: 4));
    await tester.pump();
    expect(find.byType(AutoTurnProgressBar), findsNothing);

    c.stopAutoTurn();
    await tester.pump();
  });

  testWidgets('进度条随计时推进重绘，且不拦截手势', (WidgetTester tester) async {
    usePortrait(tester);
    final BookReaderController c = await mount(tester);
    c.startAutoTurn(const Duration(seconds: 4));
    await tester.pump();

    final Finder bar = find.byType(AutoTurnProgressBar);
    expect(bar, findsOneWidget);
    // 非交互：整个进度条被 IgnorePointer 包裹，不会吃掉翻页点击
    expect(
      find.descendant(of: bar, matching: find.byType(IgnorePointer)),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);

    c.stopAutoTurn();
    await tester.pump();
  });
}
