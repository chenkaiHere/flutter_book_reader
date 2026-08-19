import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/controller/reading_controller.dart';
import 'package:flutter_book_reader/src/paginator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 章末自定义组件：只出现在每章最后一页，且分页会为它预留高度。
void main() {
  setUp(() => ReaderConfig.instance.setFlipType(FlipType.slideHorizontal));

  Widget block(String text) => SizedBox(
        height: 60,
        child: Center(child: Text(text)),
      );

  Future<BookReaderController> mount(
    WidgetTester tester, {
    ReaderChapterEndBuilder? builder,
    double reserve = 96,
    int chapters = 3,
    bool Function(int)? locked,
  }) async {
    final BookReaderController controller = BookReaderController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: BookReader(
          source: FakeBookSource(chapters: chapters),
          labels: ReaderLabels.chinese,
          controller: controller,
          chapterEndBuilder: builder,
          chapterEndReserve: reserve,
          isChapterLocked: locked,
          chapterLockBuilder: locked == null
              ? null
              : (BuildContext _, ReaderTheme __, ReaderLockInfo ___) =>
                  const Text('订阅本章'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return controller;
  }

  /// 把当前章翻到最后一页。
  Future<void> toChapterEnd(
    WidgetTester tester,
    BookReaderController c,
  ) async {
    while (c.pageIndex < c.pageCount - 1) {
      c.nextPage();
      await tester.pumpAndSettle();
    }
  }

  testWidgets('未配置构建器时不显示任何章末内容', (WidgetTester tester) async {
    final BookReaderController c = await mount(tester);
    await toChapterEnd(tester, c);
    expect(find.text('章末内容'), findsNothing);
  });

  testWidgets('只在本章最后一页显示，中间页不显示', (WidgetTester tester) async {
    final BookReaderController c = await mount(
      tester,
      builder: (BuildContext _, ReaderTheme __, ReaderChapterEndInfo ___) =>
          block('章末内容'),
    );
    expect(c.pageCount, greaterThan(1));
    expect(find.text('章末内容'), findsNothing, reason: '首页不是章末');

    await toChapterEnd(tester, c);
    expect(find.text('章末内容'), findsOneWidget);
  });

  testWidgets('每一章的末页都会显示（跨章后依然出现）', (WidgetTester tester) async {
    final BookReaderController c = await mount(
      tester,
      builder: (BuildContext _, ReaderTheme __, ReaderChapterEndInfo info) =>
          block('第 ${info.chapterIndex + 1} 章末'),
    );
    await toChapterEnd(tester, c);
    expect(find.text('第 1 章末'), findsOneWidget);

    c.goToChapter(1);
    await tester.pumpAndSettle();
    await toChapterEnd(tester, c);
    expect(find.text('第 2 章末'), findsOneWidget);
  });

  testWidgets('info 带上章号 / 标题 / 是否末章', (WidgetTester tester) async {
    final List<ReaderChapterEndInfo> seen = <ReaderChapterEndInfo>[];
    final BookReaderController c = await mount(
      tester,
      chapters: 2,
      builder: (BuildContext _, ReaderTheme __, ReaderChapterEndInfo info) {
        seen.add(info);
        return block('x');
      },
    );
    await toChapterEnd(tester, c);
    expect(seen.last.chapterIndex, 0);
    expect(seen.last.chapterTitle, '第 1 章');
    expect(seen.last.isLastChapter, isFalse);

    c.goToChapter(1);
    await tester.pumpAndSettle();
    await toChapterEnd(tester, c);
    expect(seen.last.isLastChapter, isTrue, reason: '最后一章应标记 isLastChapter');
  });

  testWidgets('点击章末组件的回调能正常触发（弹层由宿主自己弹）', (WidgetTester tester) async {
    int taps = 0;
    final BookReaderController c = await mount(
      tester,
      builder: (BuildContext _, ReaderTheme __, ReaderChapterEndInfo ___) =>
          SizedBox(
        height: 60,
        child: Center(
          child: ElevatedButton(
            onPressed: () => taps++,
            child: const Text('送礼物'),
          ),
        ),
      ),
    );
    await toChapterEnd(tester, c);
    await tester.tap(find.text('送礼物'));
    await tester.pumpAndSettle();
    expect(taps, 1);
  });

  testWidgets('未解锁付费章不显示章末组件（读者到不了章末）', (WidgetTester tester) async {
    await mount(
      tester,
      locked: (int ch) => ch == 0,
      builder: (BuildContext _, ReaderTheme __, ReaderChapterEndInfo ___) =>
          block('章末内容'),
    );
    expect(find.text('订阅本章'), findsOneWidget);
    expect(find.text('章末内容'), findsNothing);
  });

  testWidgets('上下滚动模式下每章正文后也会出现', (WidgetTester tester) async {
    ReaderConfig.instance.setFlipType(FlipType.scrollVertical);
    addTearDown(
      () => ReaderConfig.instance.setFlipType(FlipType.slideHorizontal),
    );
    await mount(
      tester,
      builder: (BuildContext _, ReaderTheme __, ReaderChapterEndInfo info) =>
          block('第 ${info.chapterIndex + 1} 章末'),
    );
    // 连续滚动里章末组件跟在该章正文之后，向下滚即可看到
    for (int i = 0; i < 30; i++) {
      if (find.text('第 1 章末').evaluate().isNotEmpty) break;
      await tester.fling(find.byType(ListView), const Offset(0, -600), 1500);
      await tester.pumpAndSettle();
    }
    expect(find.text('第 1 章末'), findsOneWidget);
  });

  group('分页预留（lastPageReserve）', () {
    const TextStyle style = TextStyle(fontSize: 18, height: 1.6);

    List<ReaderPage> run({required double reserve, int paragraphs = 12}) =>
        Paginator.paginate(
          paragraphs: List<String>.generate(
            paragraphs,
            (int i) => '这是第 ${i + 1} 段的内容，' * 6,
          ),
          style: style,
          size: const Size(320, 480),
          indent: '　　',
          lastPageReserve: reserve,
        );

    test('末页放不下预留高度时另起一页承载组件', () {
      final int without = run(reserve: 0).length;
      // 预留一整屏，末页必然放不下 → 追加一页
      final List<ReaderPage> withReserve = run(reserve: 480);
      expect(withReserve.length, without + 1);
      expect(withReserve.last, isEmpty, reason: '追加的那页专门给章末组件');
    });

    test('末页空间充足时不追加页', () {
      // 段落很少，末页剩余空间远大于预留值
      final List<ReaderPage> pages = run(reserve: 40, paragraphs: 2);
      expect(pages, hasLength(1));
      expect(pages.single, isNotEmpty);
    });

    test('预留为 0（未配置章末组件）时与原来完全一致', () {
      expect(run(reserve: 0).length, run(reserve: 0).length);
      expect(run(reserve: 0).last, isNotEmpty);
    });

    test('内容不因预留而丢失', () {
      String joined(List<ReaderPage> pages) => pages
          .expand((ReaderPage p) => p)
          .map((ReaderBlock b) => b.text)
          .join();
      expect(joined(run(reserve: 480)), joined(run(reserve: 0)));
    });
  });

  test('控制器：未配置构建器时预留高度视为 0', () async {
    final FakeBookSource source = FakeBookSource();
    final BookManifest manifest = await source.loadManifest();
    final ReadingController c = ReadingController(
      source: source,
      manifest: manifest,
    );
    addTearDown(c.dispose);

    c.chapterEndReserve = 120;
    expect(c.hasChapterEnd, isFalse);
    expect(c.chapterEndPageReserve, 0, reason: '没有组件就不该占用分页空间');

    c.chapterEndBuilder =
        (BuildContext _, ReaderTheme __, ReaderChapterEndInfo ___) =>
            const SizedBox.shrink();
    expect(c.hasChapterEnd, isTrue);
    expect(c.chapterEndPageReserve, 120);
  });
}
