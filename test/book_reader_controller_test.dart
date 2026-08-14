import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_book_source.dart';

/// 对外控制器的契约：未绑定阅读器时全部安全降级，绑定后驱动真实阅读。
void main() {
  group('未绑定阅读器（isReady == false）', () {
    test('所有读取返回安全默认值', () {
      final BookReaderController c = BookReaderController();
      addTearDown(c.dispose);

      expect(c.isReady, isFalse);
      expect(c.chapterIndex, 0);
      expect(c.chapterCount, 0);
      expect(c.currentChapterTitle, '');
      expect(c.pageIndex, 0);
      expect(c.pageCount, 0);
      expect(c.currentPageText, '');
      expect(c.isAtBookEnd, isFalse);
      expect(c.position, isNull);
      expect(c.isMenuVisible, isFalse);
      expect(c.isMenuPanelExpanded, isFalse);
      expect(c.isCurrentPageBookmarked, isFalse);
      expect(c.isAutoTurning, isFalse);
      expect(c.autoTurnInterval, const Duration(seconds: 5));
    });

    test('所有命令静默忽略，不抛异常', () {
      final BookReaderController c = BookReaderController();
      addTearDown(c.dispose);

      expect(() {
        c
          ..nextPage()
          ..previousPage()
          ..goToChapter(3)
          ..goToPosition(const ReadingPosition(chapterIndex: 1))
          ..closeMenu()
          ..markReading(0, '任意句子')
          ..clearReading()
          ..toggleBookmark()
          ..startAutoTurn(const Duration(seconds: 2))
          ..stopAutoTurn()
          ..setAutoTurnInterval(const Duration(seconds: 3));
      }, returnsNormally);
    });

    test('dispose 后再调用命令依然安全', () {
      final BookReaderController c = BookReaderController()..dispose();
      expect(c.nextPage, returnsNormally);
      expect(c.isReady, isFalse);
    });
  });

  group('绑定阅读器后', () {
    Future<BookReaderController> mount(
      WidgetTester tester, {
      FakeBookSource? source,
      int? startChapter,
    }) async {
      final BookReaderController controller = BookReaderController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: BookReader(
          source: source ?? FakeBookSource(),
          labels: ReaderLabels.chinese,
          controller: controller,
          startChapter: startChapter,
        ),
      ));
      await tester.pumpAndSettle();
      return controller;
    }

    testWidgets('就绪后可读出章节 / 页码 / 正文', (WidgetTester tester) async {
      final BookReaderController c = await mount(tester);
      expect(c.isReady, isTrue);
      expect(c.chapterCount, 5);
      expect(c.chapterIndex, 0);
      expect(c.pageCount, greaterThan(1));
      expect(c.currentChapterTitle, '第 1 章');
      expect(c.currentPageText, isNotEmpty);
      expect(c.position?.chapterIndex, 0);
    });

    testWidgets('nextPage / previousPage 驱动翻页并通知监听者',
        (WidgetTester tester) async {
      final BookReaderController c = await mount(tester);
      int notified = 0;
      c.addListener(() => notified++);

      c.nextPage();
      await tester.pumpAndSettle();
      expect(c.pageIndex, 1);
      expect(notified, greaterThanOrEqualTo(1));

      c.previousPage();
      await tester.pumpAndSettle();
      expect(c.pageIndex, 0);
    });

    testWidgets('currentPageText 随翻页变化', (WidgetTester tester) async {
      final BookReaderController c = await mount(tester);
      final String first = c.currentPageText;
      c.nextPage();
      await tester.pumpAndSettle();
      expect(c.currentPageText, isNot(first));
    });

    testWidgets('goToChapter 跳章，goToPosition 跳到章内偏移',
        (WidgetTester tester) async {
      final BookReaderController c = await mount(tester);
      c.goToChapter(2);
      await tester.pumpAndSettle();
      expect(c.chapterIndex, 2);
      expect(c.pageIndex, 0);

      c.goToPosition(
          const ReadingPosition(chapterIndex: 1, charOffset: 100000));
      await tester.pumpAndSettle();
      expect(c.chapterIndex, 1);
      expect(c.pageIndex, c.pageCount - 1, reason: '巨大偏移应落到该章末页');
    });

    testWidgets('isAtBookEnd 在全书最后一页为真', (WidgetTester tester) async {
      final BookReaderController c = await mount(
        tester,
        source: FakeBookSource(chapters: 2),
        startChapter: 1,
      );
      expect(c.isAtBookEnd, isFalse);
      c.goToPosition(
          const ReadingPosition(chapterIndex: 1, charOffset: 100000));
      await tester.pumpAndSettle();
      expect(c.isAtBookEnd, isTrue);
    });

    testWidgets('toggleBookmark 加书签后状态翻转，再次调用移除', (WidgetTester tester) async {
      final BookReaderController controller = BookReaderController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(MaterialApp(
        home: BookReader(
          source: FakeBookSource(),
          labels: ReaderLabels.chinese,
          controller: controller,
          bookmarkStore: InMemoryReaderBookmarkStore(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(controller.isCurrentPageBookmarked, isFalse);
      controller.toggleBookmark();
      await tester.pumpAndSettle();
      expect(controller.isCurrentPageBookmarked, isTrue);

      controller.toggleBookmark();
      await tester.pumpAndSettle();
      expect(controller.isCurrentPageBookmarked, isFalse);
    });

    testWidgets('自动翻页开关经控制器可读可写', (WidgetTester tester) async {
      final BookReaderController c = await mount(tester);
      expect(c.isAutoTurning, isFalse);

      c.startAutoTurn(const Duration(seconds: 3));
      await tester.pump();
      expect(c.isAutoTurning, isTrue);
      expect(c.autoTurnInterval, const Duration(seconds: 3));

      c.setAutoTurnInterval(const Duration(seconds: 6));
      await tester.pump();
      expect(c.autoTurnInterval, const Duration(seconds: 6));

      c.stopAutoTurn();
      await tester.pump();
      expect(c.isAutoTurning, isFalse);
    });

    testWidgets('markReading 高亮并翻到该句所在页，clearReading 清除',
        (WidgetTester tester) async {
      final BookReaderController c = await mount(tester);
      // 取靠后页面里某一整段（各段文字唯一），跟读定位应把视图翻过去
      c.nextPage();
      await tester.pumpAndSettle();
      c.nextPage();
      await tester.pumpAndSettle();
      final String laterParagraph = c.currentPageText
          .split('\n')
          .firstWhere((String s) => s.contains('段的正文'));
      c.goToChapter(0);
      await tester.pumpAndSettle();
      expect(c.pageIndex, 0);

      c.markReading(0, laterParagraph);
      await tester.pumpAndSettle();
      expect(c.pageIndex, greaterThan(0), reason: '应自动翻到该句所在页');

      c.clearReading();
      await tester.pumpAndSettle();
      expect(c.isReady, isTrue);
    });

    testWidgets('markReading 传入不存在的句子时安全忽略', (WidgetTester tester) async {
      final BookReaderController c = await mount(tester);
      final int before = c.pageIndex;
      c.markReading(0, '这句话在正文里根本不存在-zzz');
      await tester.pumpAndSettle();
      expect(c.pageIndex, before);
    });

    testWidgets('closeMenu 收起菜单', (WidgetTester tester) async {
      final BookReaderController c = await mount(tester);
      final Size size = tester.getSize(find.byType(BookReader));
      await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
      await tester.pumpAndSettle();
      expect(c.isMenuVisible, isTrue);

      c.closeMenu();
      await tester.pumpAndSettle();
      expect(c.isMenuVisible, isFalse);
    });

    testWidgets('阅读器卸载后控制器回到未就绪态', (WidgetTester tester) async {
      final BookReaderController c = await mount(tester);
      expect(c.isReady, isTrue);

      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pumpAndSettle();
      expect(c.isReady, isFalse);
      expect(c.nextPage, returnsNormally);
    });
  });
}
