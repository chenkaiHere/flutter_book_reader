import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/paginator.dart';
import 'package:flutter_book_reader/src/widgets/page_frame.dart';
import 'package:flutter_book_reader/src/widgets/reader_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  testWidgets('切换主题立即生效（纸张背景色随之更新，无需重进）', (WidgetTester tester) async {
    final ReaderConfig config = ReaderConfig();
    await tester.pumpWidget(
      MaterialApp(home: BookReader(source: FakeBookSource(), config: config)),
    );
    await tester.pumpAndSettle();

    Color bg() =>
        tester.widget<Scaffold>(find.byType(Scaffold)).backgroundColor!;
    expect(bg(), ReaderTheme.yellow.paperColor, reason: '默认黄色主题');

    // 在同一个组件实例上切主题
    config.setTheme(ReaderTheme.night);
    await tester.pump();
    expect(bg(), ReaderTheme.night.paperColor, reason: '切换后应立即更新背景');
  });

  testWidgets('菜单唤起后滑动正文会隐藏菜单', (WidgetTester tester) async {
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
    // 中间点击唤出菜单
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
    expect(menuOpacity(), 1);

    // 菜单可见时滑动正文 —— 滑动那一刻菜单隐藏
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(menuOpacity(), 0, reason: '滑动应隐藏菜单');
  });

  testWidgets('菜单唤起后单击只隐藏菜单、不翻页；滑动才翻页', (WidgetTester tester) async {
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
    // 唤起菜单
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
    expect(menuOpacity(), 1);
    expect(find.textContaining('1/'), findsWidgets, reason: '仍在第 1 页');

    // 菜单可见时点右侧 —— 只隐藏菜单，不翻页
    await tester.tapAt(Offset(size.width * 0.85, size.height * 0.5));
    await tester.pumpAndSettle();
    expect(menuOpacity(), 0, reason: '单击应隐藏菜单');
    expect(find.textContaining('1/'), findsWidgets, reason: '单击不应翻页');

    // 再次唤起，滑动 —— 隐藏菜单并翻页
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
    expect(menuOpacity(), 1);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(menuOpacity(), 0, reason: '滑动应隐藏菜单');
    expect(find.textContaining('2/'), findsWidgets, reason: '滑动应翻到下一页');
  });

  testWidgets('退出阅读页后把底部导航栏恢复为白底黑字', (WidgetTester tester) async {
    final List<MethodCall> calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(host(FakeBookSource()));
    await tester.pumpAndSettle();
    // 卸载阅读页（等价于退出返回）
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();

    final Iterable<MethodCall> styleCalls = calls.where(
      (MethodCall c) => c.method == 'SystemChrome.setSystemUIOverlayStyle',
    );
    expect(styleCalls, isNotEmpty);
    final Map<Object?, Object?> args =
        styleCalls.last.arguments as Map<Object?, Object?>;
    expect(args['systemNavigationBarColor'], 0xFFFFFFFF, reason: '底部导航栏应为白色');
    expect(args['systemNavigationBarIconBrightness'], 'Brightness.dark',
        reason: '底部导航栏图标应为黑色');
  });

  for (final FlipType style in <FlipType>[
    FlipType.cover,
    FlipType.simulation,
  ]) {
    testWidgets('$style 翻页模式：点按可翻到下一页', (WidgetTester tester) async {
      final ReaderConfig config = ReaderConfig()..setFlipType(style);
      await tester.pumpWidget(
        MaterialApp(
          home: BookReader(source: FakeBookSource(), config: config),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('1/'), findsWidgets);

      final Size size = tester.getSize(find.byType(BookReader));
      await tester.tapAt(Offset(size.width * 0.85, size.height * 0.5));
      await tester.pumpAndSettle();
      expect(find.textContaining('2/'), findsWidgets, reason: '$style 应能翻页');
    });
  }

  testWidgets('仿真翻页：拖动（卷曲手势）可翻到下一页', (WidgetTester tester) async {
    final ReaderConfig config = ReaderConfig()
      ..setFlipType(FlipType.simulation);
    await tester.pumpWidget(
      MaterialApp(home: BookReader(source: FakeBookSource(), config: config)),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('1/'), findsWidgets);

    // 从右向左快速拖动（卷曲翻页）
    await tester.fling(
      find.byType(BookReader),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('2/'), findsWidgets, reason: '卷曲拖动应翻到下一页');
  });

  testWidgets('页眉：章首显示书名，非章首显示章节标题（随页翻动）', (
    WidgetTester tester,
  ) async {
    Widget frame(int pageIndex) => MaterialApp(
          home: Scaffold(
            body: ReaderPageContent(
              theme: ReaderTheme.yellow,
              config: ReaderConfig(),
              bookTitle: 'BOOK',
              chapterTitle: 'CH-ONE',
              page: const <ReaderBlock>[
                ReaderBlock(text: '正文内容', isParagraphStart: true),
              ],
              isChapterHead: pageIndex == 0,
              chapterIndex: 0,
              chapterCount: 3,
              pageIndex: pageIndex,
              pageCount: 4,
              progress: 0.1,
            ),
          ),
        );

    String headerTitle() =>
        tester.widget<ReaderHeaderBar>(find.byType(ReaderHeaderBar)).title;

    await tester.pumpWidget(frame(0));
    expect(headerTitle(), 'BOOK', reason: '章首显示书名');

    await tester.pumpWidget(frame(1));
    expect(headerTitle(), 'CH-ONE', reason: '非章首显示章节标题');
  });
}
