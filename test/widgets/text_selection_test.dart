import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 长按选中 → 气泡工具条 → 划线 / 回调。这块是 page_frame 里最复杂的交互。
void main() {
  setUp(() {
    ReaderConfig.instance
      ..setFlipType(FlipType.slideHorizontal)
      ..setTheme(ReaderTheme.yellow);
  });

  /// 长按正文中部以选中一段文字。
  Future<void> longPressBody(WidgetTester tester) async {
    final Size size = tester.getSize(find.byType(BookReader));
    await tester.longPressAt(Offset(size.width * 0.5, size.height * 0.45));
    await tester.pumpAndSettle();
  }

  testWidgets('长按正文弹出气泡工具条（复制 / 划线 / 评论 / 查询 / 分享）',
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        underlineStore: InMemoryReaderUnderlineStore(),
        onTextAction: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
    await longPressBody(tester);

    expect(find.text(ReaderLabels.chinese.selectCopy), findsOneWidget);
    expect(find.text(ReaderLabels.chinese.selectHighlight), findsOneWidget);
    expect(find.text(ReaderLabels.chinese.selectComment), findsOneWidget);
    expect(find.text(ReaderLabels.chinese.selectQuery), findsOneWidget);
    expect(find.text(ReaderLabels.chinese.selectShare), findsOneWidget);
  });

  testWidgets('禁用选中时长按不弹工具条', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        enableTextSelection: false,
        onTextAction: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
    await longPressBody(tester);
    expect(find.text(ReaderLabels.chinese.selectCopy), findsNothing);
  });

  testWidgets('点「复制」把选中详情回调给宿主并收起工具条', (WidgetTester tester) async {
    final List<ReaderTextAction> actions = <ReaderTextAction>[];
    ReaderSelection? received;
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        onTextAction: (ReaderTextAction a, ReaderSelection s) {
          actions.add(a);
          received = s;
        },
      ),
    ));
    await tester.pumpAndSettle();
    await longPressBody(tester);

    await tester.tap(find.text(ReaderLabels.chinese.selectCopy));
    await tester.pumpAndSettle();

    expect(actions, <ReaderTextAction>[ReaderTextAction.copy]);
    expect(received, isNotNull);
    expect(received!.text, isNotEmpty);
    expect(received!.chapterIndex, 0);
    expect(received!.chapterTitle, '第 1 章');
    expect(received!.start, greaterThanOrEqualTo(0));
    expect(received!.end, greaterThan(received!.start));
    expect(find.text(ReaderLabels.chinese.selectCopy), findsNothing,
        reason: '动作完成后应清除选中');
  });

  testWidgets('「评论」「查询」「分享」都各自回调对应动作', (WidgetTester tester) async {
    final List<ReaderTextAction> actions = <ReaderTextAction>[];
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        onTextAction: (ReaderTextAction a, ReaderSelection _) => actions.add(a),
      ),
    ));
    await tester.pumpAndSettle();

    for (final (String label, ReaderTextAction expected)
        in <(String, ReaderTextAction)>[
      (ReaderLabels.chinese.selectComment, ReaderTextAction.comment),
      (ReaderLabels.chinese.selectQuery, ReaderTextAction.query),
      (ReaderLabels.chinese.selectShare, ReaderTextAction.share),
    ]) {
      await longPressBody(tester);
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(actions.last, expected, reason: label);
    }
    expect(actions, hasLength(3));
  });

  testWidgets('点「划线」由插件内部持久化，并出现「删除划线」选项', (WidgetTester tester) async {
    final InMemoryReaderUnderlineStore store = InMemoryReaderUnderlineStore();
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        underlineStore: store,
        onTextAction: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();

    await longPressBody(tester);
    await tester.tap(find.text(ReaderLabels.chinese.selectHighlight));
    await tester.pumpAndSettle();

    final List<Underline> saved = await store.load('fake-book');
    expect(saved, hasLength(1), reason: '划线由插件内部写入存储，不走 onTextAction');
    expect(saved.single.chapterIndex, 0);
    expect(saved.single.text, isNotEmpty);
    expect(saved.single.end, greaterThan(saved.single.start));

    // 再次长按同一处：因与已有划线相交，工具条多出「删除划线」
    await longPressBody(tester);
    expect(
        find.text(ReaderLabels.chinese.selectRemoveHighlight), findsOneWidget);

    await tester.tap(find.text(ReaderLabels.chinese.selectRemoveHighlight));
    await tester.pumpAndSettle();
    expect(await store.load('fake-book'), isEmpty, reason: '删除后应写回空列表');
  });

  testWidgets('未与已有划线相交时不显示「删除划线」', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        underlineStore: InMemoryReaderUnderlineStore(),
        onTextAction: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
    await longPressBody(tester);
    expect(find.text(ReaderLabels.chinese.selectRemoveHighlight), findsNothing);
  });

  testWidgets('点击遮罩空白处取消选中', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        onTextAction: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
    await longPressBody(tester);
    expect(find.text(ReaderLabels.chinese.selectCopy), findsOneWidget);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text(ReaderLabels.chinese.selectCopy), findsNothing);
  });

  testWidgets('翻页会清除选中态（锚定的渲染盒已失效）', (WidgetTester tester) async {
    final BookReaderController controller = BookReaderController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        controller: controller,
        onTextAction: (_, __) {},
      ),
    ));
    await tester.pumpAndSettle();
    await longPressBody(tester);
    expect(find.text(ReaderLabels.chinese.selectCopy), findsOneWidget);

    controller.nextPage();
    await tester.pumpAndSettle();
    expect(find.text(ReaderLabels.chinese.selectCopy), findsNothing);
  });

  testWidgets('已有划线在页面上会被渲染（即使未启用选中）', (WidgetTester tester) async {
    final InMemoryReaderUnderlineStore store = InMemoryReaderUnderlineStore();
    await store.save('fake-book', <Underline>[
      const Underline(
        chapterIndex: 0,
        start: 0,
        end: 30,
        text: '开头一段',
        chapterTitle: '第 1 章',
        createdAt: 1,
      ),
    ]);

    await tester.pumpWidget(MaterialApp(
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        underlineStore: store,
        enableTextSelection: false,
      ),
    ));
    await tester.pumpAndSettle();
    // 能正常渲染且不抛异常即达标（波浪线由 CustomPainter 绘制，无法用 finder 断言）
    expect(tester.takeException(), isNull);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
