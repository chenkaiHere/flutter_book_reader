import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 段评角标的显 / 隐：正文里的小气泡可一键收起，评论本身不受影响。
void main() {
  setUp(() {
    ReaderConfig.instance
      ..setFlipType(FlipType.slideHorizontal)
      ..setTheme(ReaderTheme.yellow)
      ..setSegmentCommentsVisible(visible: true);
  });
  tearDown(
    () => ReaderConfig.instance.setSegmentCommentsVisible(visible: true),
  );

  /// 段评角标上的评论数文字（气泡里显示的数字）。
  Finder badge(String count) => find.text(count);

  Future<void> mount(
    WidgetTester tester, {
    ReaderConfig? config,
    List<Comment>? comments,
  }) async {
    final InMemoryReaderCommentStore store = InMemoryReaderCommentStore();
    await store.save(
      'fake-book',
      comments ??
          <Comment>[
            const Comment(
              chapterIndex: 0,
              start: 0,
              end: 10,
              quote: '开头',
              text: '第一条想法',
              chapterTitle: '第 1 章',
              createdAt: 1,
            ),
          ],
    );
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        config: config,
        commentStore: store,
        onSegmentCommentTap: (_) {},
      ),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openMenu(WidgetTester tester) async {
    final Size size = tester.getSize(find.byType(BookReader));
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
  }

  group('ReaderConfig.showSegmentComments', () {
    test('默认显示', () {
      expect(ReaderConfig().showSegmentComments, isTrue);
    });

    test('切换后取反并通知监听者', () {
      final ReaderConfig c = ReaderConfig();
      int notified = 0;
      c.addListener(() => notified++);

      c.toggleSegmentComments();
      expect(c.showSegmentComments, isFalse);
      expect(notified, 1);

      c.toggleSegmentComments();
      expect(c.showSegmentComments, isTrue);
      expect(notified, 2);
    });

    test('设为相同值不发通知', () {
      final ReaderConfig c = ReaderConfig();
      int notified = 0;
      c.addListener(() => notified++);
      c.setSegmentCommentsVisible(visible: true);
      expect(notified, 0);
    });

    test('每个实例独立，互不影响', () {
      final ReaderConfig a = ReaderConfig()..toggleSegmentComments();
      final ReaderConfig b = ReaderConfig();
      expect(a.showSegmentComments, isFalse);
      expect(b.showSegmentComments, isTrue);
    });
  });

  group('正文渲染', () {
    testWidgets('默认显示角标', (WidgetTester tester) async {
      await mount(tester);
      expect(badge('1'), findsOneWidget);
    });

    testWidgets('关闭后角标消失，开启后回来', (WidgetTester tester) async {
      final ReaderConfig config = ReaderConfig();
      await mount(tester, config: config);
      expect(badge('1'), findsOneWidget);

      config.setSegmentCommentsVisible(visible: false);
      await tester.pumpAndSettle();
      expect(badge('1'), findsNothing);

      config.setSegmentCommentsVisible(visible: true);
      await tester.pumpAndSettle();
      expect(badge('1'), findsOneWidget);
    });

    testWidgets('隐藏角标不会删除评论（笔记面板仍能看到）', (WidgetTester tester) async {
      final ReaderConfig config = ReaderConfig()
        ..setSegmentCommentsVisible(visible: false);
      await mount(tester, config: config);
      expect(badge('1'), findsNothing);

      await openMenu(tester);
      await tester.tap(find.text(ReaderLabels.chinese.catalog));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining(ReaderLabels.chinese.notesTab));
      await tester.pumpAndSettle();
      expect(find.text('第一条想法'), findsOneWidget, reason: '评论数据不受角标显隐影响');
    });
  });

  group('顶栏切换按钮', () {
    testWidgets('位于书签按钮左侧', (WidgetTester tester) async {
      await mount(tester);
      await openMenu(tester);

      final double toggleX =
          tester.getCenter(find.byIcon(Icons.mode_comment_outlined)).dx;
      final double bookmarkX =
          tester.getCenter(find.byIcon(Icons.bookmark_border)).dx;
      expect(toggleX, lessThan(bookmarkX));
    });

    testWidgets('点击即切换图标与角标显隐', (WidgetTester tester) async {
      final ReaderConfig config = ReaderConfig();
      await mount(tester, config: config);
      await openMenu(tester);

      expect(find.byIcon(Icons.mode_comment_outlined), findsOneWidget);
      expect(badge('1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.mode_comment_outlined));
      await tester.pumpAndSettle();
      expect(config.showSegmentComments, isFalse);
      expect(find.byIcon(Icons.comments_disabled_outlined), findsOneWidget,
          reason: '关闭态换成禁用图标');
      expect(badge('1'), findsNothing);

      await tester.tap(find.byIcon(Icons.comments_disabled_outlined));
      await tester.pumpAndSettle();
      expect(config.showSegmentComments, isTrue);
      expect(badge('1'), findsOneWidget);
    });

    testWidgets('提示文案随状态切换（且已本地化）', (WidgetTester tester) async {
      await mount(tester);
      await openMenu(tester);

      expect(
        find.byTooltip(ReaderLabels.chinese.hideSegmentComments),
        findsOneWidget,
        reason: '当前显示中，按钮的动作是「隐藏」',
      );

      await tester.tap(find.byIcon(Icons.mode_comment_outlined));
      await tester.pumpAndSettle();
      expect(
        find.byTooltip(ReaderLabels.chinese.showSegmentComments),
        findsOneWidget,
      );
    });
  });
}
