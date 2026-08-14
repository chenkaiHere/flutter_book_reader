import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 阅读菜单：顶栏 / 底栏 / 设置面板的交互。
void main() {
  setUp(() {
    // 每个用例都从同一份默认设置出发，避免相互污染（ReaderConfig.instance 是全局默认）。
    ReaderConfig.instance
      ..setFlipType(FlipType.slideHorizontal)
      ..setTheme(ReaderTheme.yellow)
      ..setLineHeight(1.7)
      ..setDimLevel(0);
  });

  Future<void> mount(WidgetTester tester, {VoidCallback? onClose}) async {
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        bookmarkStore: InMemoryReaderBookmarkStore(),
        onClose: onClose,
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    final Size size = tester.getSize(find.byType(BookReader));
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
  }

  Future<void> openSettings(WidgetTester tester) async {
    await openMenu(tester);
    await tester.tap(find.text(ReaderLabels.chinese.settingsMenu));
    await tester.pumpAndSettle();
  }

  testWidgets('中间点击唤起菜单，底栏按钮进入可点击区域', (WidgetTester tester) async {
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

    // 菜单未唤起时整体被移出屏幕（顶/底栏在视口之外），因此按钮不可命中。
    expect(controller.isMenuVisible, isFalse);
    final Offset hiddenAt =
        tester.getCenter(find.text(ReaderLabels.chinese.catalog));
    expect(hiddenAt.dy, greaterThan(600), reason: '关闭时底栏在视口下方');

    await openMenu(tester);
    expect(controller.isMenuVisible, isTrue);
    final Offset shownAt =
        tester.getCenter(find.text(ReaderLabels.chinese.catalog));
    expect(shownAt.dy, lessThan(600), reason: '唤起后底栏进入视口');
    expect(find.text(ReaderLabels.chinese.settingsMenu), findsOneWidget);
  });

  testWidgets('顶栏返回按钮触发 onClose', (WidgetTester tester) async {
    int closed = 0;
    await mount(tester, onClose: () => closed++);
    await openMenu(tester);
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();
    expect(closed, 1);
  });

  testWidgets('上一章 / 下一章按钮切章（点菜单按钮不会关闭菜单）', (WidgetTester tester) async {
    await mount(tester);
    await openMenu(tester);

    await tester.tap(find.text(ReaderLabels.chinese.nextChapter));
    await tester.pumpAndSettle();
    expect(find.text('第 2 章'), findsWidgets);

    // 菜单仍开着，可直接点「上一章」
    await tester.tap(find.text(ReaderLabels.chinese.prevChapter));
    await tester.pumpAndSettle();
    expect(find.text('第 1 章'), findsWidgets);
  });

  testWidgets('日夜切换按钮改变主题，再点回到日间', (WidgetTester tester) async {
    await mount(tester);
    expect(ReaderConfig.instance.theme.isDark, isFalse);

    await openMenu(tester);
    await tester.tap(find.text(ReaderLabels.chinese.nightMode));
    await tester.pumpAndSettle();
    expect(ReaderConfig.instance.theme.isDark, isTrue);

    await tester.tap(find.text(ReaderLabels.chinese.dayMode));
    await tester.pumpAndSettle();
    expect(ReaderConfig.instance.theme.isDark, isFalse);
  });

  group('设置面板', () {
    testWidgets('展开后显示字号 / 行距 / 背景 / 翻页方式', (WidgetTester tester) async {
      await mount(tester);
      await openSettings(tester);
      expect(find.text(ReaderLabels.chinese.fontSize), findsOneWidget);
      expect(find.text(ReaderLabels.chinese.lineSpacing), findsOneWidget);
      expect(find.text(ReaderLabels.chinese.background), findsOneWidget);
      expect(find.text(ReaderLabels.chinese.flipMode), findsOneWidget);
    });

    testWidgets('A+ / A- 调字号', (WidgetTester tester) async {
      await mount(tester);
      await openSettings(tester);
      final double base = ReaderConfig.instance.fontSize;

      await tester.tap(find.text('A+'));
      await tester.pumpAndSettle();
      expect(ReaderConfig.instance.fontSize, base + 1);

      await tester.tap(find.text('A-'));
      await tester.pumpAndSettle();
      expect(ReaderConfig.instance.fontSize, base);
    });

    testWidgets('色板展示全部 6 套主题，当前主题带勾选标记', (WidgetTester tester) async {
      await mount(tester);
      await openSettings(tester);

      // 6 个圆形色板：每套主题的纸张色各画一个
      final Iterable<Container> swatches = tester
          .widgetList<Container>(find.byType(Container))
          .where((Container c) {
        final Decoration? d = c.decoration;
        return d is BoxDecoration &&
            d.shape == BoxShape.circle &&
            ReaderTheme.presets.any((ReaderTheme t) => t.paperColor == d.color);
      });
      expect(swatches, hasLength(ReaderTheme.presets.length));

      // 选中项内有一个对勾
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('点击翻页方式切到上下滚动', (WidgetTester tester) async {
      await mount(tester);
      await openSettings(tester);
      await tester.tap(find.text(ReaderLabels.chinese.flipVertical));
      await tester.pumpAndSettle();
      expect(ReaderConfig.instance.flipType, FlipType.scrollVertical);
      expect(find.byType(ListView), findsWidgets, reason: '应切换为纵向滚动视图');
    });

    testWidgets('设置面板里有「自动翻页」入口，点击后关菜单并开始自动阅读', (WidgetTester tester) async {
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
      await openSettings(tester);

      expect(find.text(ReaderLabels.chinese.autoTurn), findsOneWidget);
      await tester.tap(find.text(ReaderLabels.chinese.autoTurn));
      await tester.pump();

      expect(controller.isAutoTurning, isTrue);
      expect(controller.isMenuVisible, isFalse, reason: '开启后应收起菜单');

      controller.stopAutoTurn();
      await tester.pump();
    });

    testWidgets('自动阅读中入口变为「停止自动阅读」，点击即停', (WidgetTester tester) async {
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

      controller.startAutoTurn(const Duration(seconds: 30));
      await tester.pump();
      await openSettings(tester);

      expect(find.text(ReaderLabels.chinese.autoTurnStop), findsOneWidget);
      await tester.tap(find.text(ReaderLabels.chinese.autoTurnStop));
      await tester.pump();
      expect(controller.isAutoTurning, isFalse);
    });
  });

  testWidgets('菜单打开时点击空白处只关闭菜单，不翻页', (WidgetTester tester) async {
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

    controller.nextPage();
    await tester.pumpAndSettle();
    final int page = controller.pageIndex;

    await openMenu(tester);
    expect(controller.isMenuVisible, isTrue);

    final Size size = tester.getSize(find.byType(BookReader));
    await tester.tapAt(Offset(size.width * 0.85, size.height * 0.3));
    await tester.pumpAndSettle();
    expect(controller.isMenuVisible, isFalse);
    expect(controller.pageIndex, page, reason: '关闭菜单的那一下不得翻页');
  });
}
