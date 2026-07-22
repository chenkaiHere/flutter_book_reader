import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/paginator.dart';
import 'package:flutter_book_reader/src/widgets/page_frame.dart';
import 'package:flutter_book_reader/src/widgets/catalog_sheet.dart';
import 'package:flutter_book_reader/src/widgets/reader_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_book_source.dart';

void main() {
  Future<void> openMenu(WidgetTester tester) async {
    final Size size = tester.getSize(find.byType(BookReader));
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
  }

  Widget bookmarkHost() => MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home: BookReader(
          source: FakeBookSource(),
          labels: ReaderLabels.chinese,
          bookmarkStore: InMemoryReaderBookmarkStore(),
        ),
      );

  Widget host(FakeBookSource source) => MaterialApp(
        home: BookReader(source: source, labels: ReaderLabels.chinese),
      );

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

    // 菜单可见时滑动正文 —— 滑动那一刻菜单隐藏，但不翻页
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(menuOpacity(), 0, reason: '滑动应隐藏菜单');
    expect(find.textContaining('1/'), findsWidgets, reason: '菜单可见时滑动不翻页');
  });

  testWidgets('菜单唤起后单击/滑动都只关闭菜单、不翻页；关闭后滑动才翻页',
      (WidgetTester tester) async {
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

    // 再次唤起，滑动 —— 只隐藏菜单、不翻页（菜单挡住翻页）
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
    expect(menuOpacity(), 1);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(menuOpacity(), 0, reason: '滑动应隐藏菜单');
    expect(find.textContaining('1/'), findsWidgets,
        reason: '菜单可见时滑动只关闭菜单，不翻页');

    // 菜单已关闭，再滑动 —— 才翻到下一页
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1200);
    await tester.pumpAndSettle();
    expect(find.textContaining('2/'), findsWidgets, reason: '关闭菜单后滑动才翻页');
  });

  testWidgets('目录弹窗滚到顶部后下拉可关闭', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home:
            BookReader(source: FakeBookSource(), labels: ReaderLabels.chinese),
      ),
    );
    await tester.pumpAndSettle();
    final Size size = tester.getSize(find.byType(BookReader));

    // 唤起菜单 → 打开目录
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('目录'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogSheet), findsOneWidget);

    // 列表已在顶部（当前第 1 章），继续向下拖拽应带动面板下移并关闭弹窗
    await tester.fling(
      find.descendant(
        of: find.byType(CatalogSheet),
        matching: find.byType(ListView),
      ),
      const Offset(0, 700),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.byType(CatalogSheet), findsNothing, reason: '顶部下拉应关闭目录弹窗');
  });

  testWidgets('书签：顶栏按钮加入后出现在书签页', (WidgetTester tester) async {
    await tester.pumpWidget(bookmarkHost());
    await tester.pumpAndSettle();

    await openMenu(tester);
    // 初始未加书签：空心图标
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsNothing);

    // 点击加入书签 → 变实心
    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark), findsWidgets);

    // 打开目录 → 切到「笔记」标签 → 列表出现一条书签笔记
    await tester.tap(find.text('目录'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('笔记'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogSheet), findsOneWidget);
    expect(find.text('还没有笔记'), findsNothing);
    expect(
      find.descendant(
        of: find.byType(CatalogSheet),
        matching: find.byIcon(Icons.bookmark_border),
      ),
      findsWidgets,
      reason: '笔记页应有一条书签笔记',
    );
  });

  testWidgets('评论：会话中途由外部写入 commentStore 后，打开目录能在笔记页看到',
      (WidgetTester tester) async {
    // 空 store 打开阅读器：模拟真实用法（评论由外部处理，插件内存里一开始没有）。
    final InMemoryReaderCommentStore store = InMemoryReaderCommentStore();
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        commentStore: store,
      ),
    ));
    await tester.pumpAndSettle();

    // 模拟外部（App 侧回调）在会话中途把评论写入同一个 store。
    await store.save('fake-book', <Comment>[
      Comment(
        chapterIndex: 0,
        start: 2,
        end: 8,
        quote: '这是第 1 章的正文段落',
        text: '一条测试评论内容',
        chapterTitle: '第 1 章',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ]);

    // 打开目录 → 笔记：应触发从 store 重新拉取，展示刚写入的评论。
    await openMenu(tester);
    await tester.tap(find.text('目录'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('笔记'));
    await tester.pumpAndSettle();
    expect(find.byType(CatalogSheet), findsOneWidget);
    expect(find.text('一条测试评论内容'), findsWidgets,
        reason: '中途写入的评论应出现在笔记页');
  });

  testWidgets('听书：BookReaderController 可读当前页文本并翻页',
      (WidgetTester tester) async {
    final BookReaderController controller = BookReaderController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        controller: controller,
      ),
    ));
    await tester.pumpAndSettle();

    expect(controller.isReady, isTrue, reason: '就绪后应可用');
    expect(controller.chapterCount, 5);
    expect(controller.currentPageText.trim(), isNotEmpty, reason: '应能读到当前页文本');
    expect(controller.isAtBookEnd, isFalse);

    final String before = controller.currentPageText;
    controller.nextPage();
    await tester.pumpAndSettle();
    // 翻页后：页序或文本应发生变化。
    expect(
      controller.pageIndex != 0 || controller.currentPageText != before,
      isTrue,
      reason: 'nextPage 应推进阅读位置',
    );
  });

  testWidgets('书签：BookReaderController 可编程式加 / 删并读取状态',
      (WidgetTester tester) async {
    final BookReaderController controller = BookReaderController();
    addTearDown(controller.dispose);
    int notifies = 0;
    controller.addListener(() => notifies++);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        controller: controller,
      ),
    ));
    await tester.pumpAndSettle();

    expect(controller.isCurrentPageBookmarked, isFalse, reason: '初始未加书签');
    final int before = notifies;
    controller.toggleBookmark();
    await tester.pumpAndSettle();
    expect(controller.isCurrentPageBookmarked, isTrue, reason: '加书签后为 true');
    expect(notifies, greaterThan(before), reason: '状态变化应通知监听者');

    controller.toggleBookmark();
    await tester.pumpAndSettle();
    expect(controller.isCurrentPageBookmarked, isFalse, reason: '再次调用应移除');
  });

  testWidgets('听书跟读：markReading 定位高亮 / 翻页且不抛异常',
      (WidgetTester tester) async {
    final BookReaderController controller = BookReaderController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        controller: controller,
      ),
    ));
    await tester.pumpAndSettle();

    // 第 1 章正文里存在的句子 → 应能定位（高亮 + 必要时翻页），不抛异常。
    controller.markReading(0, '这是第 1 章的正文段落');
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    controller.clearReading();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('段评：有评论的段落尾部显示数字角标，点击回调段落信息',
      (WidgetTester tester) async {
    final InMemoryReaderCommentStore store = InMemoryReaderCommentStore();
    await store.save('fake-book', <Comment>[
      Comment(
        chapterIndex: 0,
        start: 2,
        end: 8,
        quote: '正文',
        text: '段评一',
        chapterTitle: '第 1 章',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ]);
    ReaderSegmentTap? tapped;
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(splashFactory: NoSplash.splashFactory),
      home: BookReader(
        source: FakeBookSource(),
        labels: ReaderLabels.chinese,
        commentStore: store,
        onSegmentCommentTap: (ReaderSegmentTap seg) => tapped = seg,
      ),
    ));
    await tester.pumpAndSettle();

    // 段尾角标（对话气泡内显示评论数「1」）应出现。
    final Finder badge = find.text('1');
    expect(badge, findsWidgets, reason: '有评论的段落尾部应有角标');

    await tester.tap(badge.first);
    await tester.pumpAndSettle();
    expect(tapped, isNotNull, reason: '点击角标应回调');
    expect(tapped!.count, 1);
    expect(tapped!.chapterIndex, 0);
  });

  testWidgets('书签：再次点击移除', (WidgetTester tester) async {
    await tester.pumpWidget(bookmarkHost());
    await tester.pumpAndSettle();

    await openMenu(tester);
    await tester.tap(find.byIcon(Icons.bookmark_border)); // 加入
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.bookmark)); // 移除
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);
    expect(find.byIcon(Icons.bookmark), findsNothing);

    await tester.tap(find.text('目录'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('笔记'));
    await tester.pumpAndSettle();
    expect(find.text('还没有笔记'), findsOneWidget, reason: '移除后笔记页应为空');
  });

  testWidgets('书籍抽屉可在详情 / 目录标签间切换', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home:
            BookReader(source: FakeBookSource(), labels: ReaderLabels.chinese),
      ),
    );
    await tester.pumpAndSettle();
    final Size size = tester.getSize(find.byType(BookReader));
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('目录'));
    await tester.pumpAndSettle();

    // 默认落在「目录」标签：能看到章节
    expect(find.byType(CatalogSheet), findsOneWidget);
    expect(find.text('第 2 章'), findsOneWidget);
    expect(find.text('这是一本用于测试的书籍简介。'), findsNothing);

    // 切到「详情」标签：显示简介
    await tester.tap(find.text('详情'));
    await tester.pumpAndSettle();
    expect(find.text('这是一本用于测试的书籍简介。'), findsOneWidget, reason: '详情标签应显示书籍简介');
  });

  testWidgets('目录可在正序 / 倒序间切换', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(splashFactory: NoSplash.splashFactory),
        home:
            BookReader(source: FakeBookSource(), labels: ReaderLabels.chinese),
      ),
    );
    await tester.pumpAndSettle();
    final Size size = tester.getSize(find.byType(BookReader));
    await tester.tapAt(Offset(size.width * 0.5, size.height * 0.5));
    await tester.pumpAndSettle();
    await tester.tap(find.text('目录'));
    await tester.pumpAndSettle();

    expect(find.text('正序'), findsOneWidget);
    expect(find.text('倒序'), findsNothing);

    await tester.tap(find.text('正序'));
    await tester.pumpAndSettle();
    expect(find.text('倒序'), findsOneWidget, reason: '点击后应切换为倒序');
    expect(find.text('正序'), findsNothing);
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
