import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/widgets/reader_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_book_source.dart';

void main() {
  Widget host(FakeBookSource source) =>
      MaterialApp(home: BookReader(source: source));

  testWidgets('阅读器可打开并翻页', (WidgetTester tester) async {
    await tester.pumpWidget(host(FakeBookSource()));
    await tester.pumpAndSettle();

    expect(find.text('第 1 章'), findsWidgets);
    expect(find.textContaining('1/'), findsWidgets);

    final Size size = tester.getSize(find.byType(BookReader));
    await tester.tapAt(Offset(size.width * 0.85, size.height * 0.5));
    await tester.pumpAndSettle();

    expect(find.textContaining('2/'), findsWidgets);
  });

  testWidgets('横向滑动到本章末尾可继续滑入下一章', (WidgetTester tester) async {
    await tester.pumpWidget(host(FakeBookSource()));
    await tester.pumpAndSettle();

    expect(find.text('第 1 章'), findsWidgets);

    bool reachedCh2 = false;
    for (int i = 0; i < 60; i++) {
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
      await tester.pumpAndSettle();
      if (find.text('第 2 章').evaluate().isNotEmpty) {
        reachedCh2 = true;
        break;
      }
    }
    expect(reachedCh2, isTrue, reason: '滑动应能从第一章跨入第二章');
  });

  testWidgets('上下滚动模式：持续向下滚动会自动接入下一章', (WidgetTester tester) async {
    ReaderConfig.instance.setFlipType(FlipType.scrollVertical);
    addTearDown(
      () => ReaderConfig.instance.setFlipType(FlipType.slideHorizontal),
    );

    await tester.pumpWidget(host(FakeBookSource()));
    await tester.pumpAndSettle();

    expect(find.text('第 2 章'), findsNothing);

    bool appended = false;
    for (int i = 0; i < 40; i++) {
      await tester.fling(find.byType(ListView), const Offset(0, -600), 1500);
      await tester.pumpAndSettle();
      if (find.text('第 2 章').evaluate().isNotEmpty) {
        appended = true;
        break;
      }
    }
    expect(appended, isTrue, reason: '向下滚动应自动接入下一章，无需点按钮');
  });

  testWidgets('中间点击唤出菜单后，再次点击空白处可隐藏菜单', (WidgetTester tester) async {
    await tester.pumpWidget(host(FakeBookSource()));
    await tester.pumpAndSettle();

    double menuOpacity() => tester
        .widget<AnimatedOpacity>(
          find.descendant(
            of: find.byType(ReaderMenu),
            matching: find.byType(AnimatedOpacity),
          ),
        )
        .opacity;

    final Size size = tester.getSize(find.byType(BookReader));
    final Offset center = Offset(size.width * 0.5, size.height * 0.5);

    expect(menuOpacity(), 0);

    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(menuOpacity(), 1);

    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(menuOpacity(), 0);
  });

  testWidgets('切换主题立即生效（纸张背景色随之更新，无需重进）',
      (WidgetTester tester) async {
    final ReaderConfig config = ReaderConfig();
    await tester.pumpWidget(
      MaterialApp(home: BookReader(source: FakeBookSource(), config: config)),
    );
    await tester.pumpAndSettle();

    Color bg() => tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor!;
    expect(bg(), ReaderTheme.yellow.paperColor, reason: '默认黄色主题');

    // 在同一个组件实例上切主题
    config.setTheme(ReaderTheme.night);
    await tester.pump();
    expect(bg(), ReaderTheme.night.paperColor, reason: '切换后应立即更新背景');
  });
}
