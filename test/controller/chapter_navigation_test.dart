import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/controller/reading_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 翻页 / 切章 / 扉页 / 付费章的导航规则。纯逻辑，不建 Widget。
void main() {
  const Size viewport = Size(320, 520);

  Future<ReadingController> ready(
    FakeBookSource source, {
    int startChapter = 0,
    int startCharOffset = 0,
  }) async {
    final BookManifest manifest = await source.loadManifest();
    final ReadingController c = ReadingController(
      source: source,
      manifest: manifest,
      startChapter: startChapter,
      startCharOffset: startCharOffset,
    );
    addTearDown(c.dispose);
    await c.ensureLoaded(startChapter);
    c.updateViewport(viewport, TextScaler.noScaling);
    return c;
  }

  group('章节边界', () {
    test('首章没有上一章，末章没有下一章', () async {
      final ReadingController first = await ready(FakeBookSource(chapters: 3));
      expect(first.hasPrev, isFalse);
      expect(first.hasNext, isTrue);
      expect(first.leading, 0, reason: '首章前无边界页');

      final ReadingController last =
          await ready(FakeBookSource(chapters: 3), startChapter: 2);
      expect(last.hasPrev, isTrue);
      expect(last.hasNext, isFalse);
      expect(last.leading, 1, reason: '非首章前有一张边界页');
    });

    test('loadChapter 越界时被钳制到合法范围', () async {
      final ReadingController c = await ready(FakeBookSource(chapters: 3));
      c.loadChapter(99);
      expect(c.chapterIndex, 2);
      c.loadChapter(-5);
      expect(c.chapterIndex, 0);
    });

    test('isAtBookEnd 只在全书最后一页为真', () async {
      final ReadingController c =
          await ready(FakeBookSource(chapters: 2), startChapter: 1);
      expect(c.isAtBookEnd, isFalse);
      c.goToPage(c.pages.length - 1);
      expect(c.isAtBookEnd, isTrue);
    });
  });

  group('goToPage', () {
    test('钳制到 [0, 末页]', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.goToPage(-3);
      expect(c.pageIndex, 0);
      c.goToPage(9999);
      expect(c.pageIndex, c.pages.length - 1);
    });

    test('同步更新 charOffset 为该页起始偏移', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.goToPage(2);
      expect(c.charOffset, c.startOffsetOfPage(2));
    });
  });

  group('nextPage / prevPage', () {
    test('章内正常前后翻', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.nextPage();
      expect(c.pageIndex, 1);
      c.prevPage();
      expect(c.pageIndex, 0);
    });

    test('章末 nextPage 进入下一章首页', () async {
      final ReadingController c = await ready(FakeBookSource(chapters: 3));
      c.goToPage(c.pages.length - 1);
      c.nextPage();
      expect(c.chapterIndex, 1);
      expect(c.pageIndex, 0);
    });

    test('章首 prevPage 进入上一章并定位末页', () async {
      final FakeBookSource source = FakeBookSource(chapters: 3);
      final ReadingController c = await ready(source, startChapter: 1);
      c.prevPage();
      expect(c.chapterIndex, 0);
      expect(c.pendingAtEnd, isTrue, reason: '待布局时定位到上一章末页');

      await c.ensureLoaded(0);
      c.updateViewport(viewport, TextScaler.noScaling);
      expect(c.pageIndex, c.pages.length - 1);
    });

    test('全书首页 prevPage 不动（无扉页时）', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.prevPage();
      expect(c.chapterIndex, 0);
      expect(c.pageIndex, 0);
    });

    test('全书末页 nextPage 不动', () async {
      final ReadingController c =
          await ready(FakeBookSource(chapters: 2), startChapter: 1);
      c.goToPage(c.pages.length - 1);
      final int page = c.pageIndex;
      c.nextPage();
      expect(c.chapterIndex, 1);
      expect(c.pageIndex, page);
    });
  });

  group('扉页', () {
    test('未配置构建器时 hasTitlePage 为 false，showTitlePage 无效', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.hasTitlePage, isFalse);
      c.showTitlePage();
      expect(c.onTitlePage, isFalse);
    });

    test('配置后可停在扉页，nextPage 进入正文首页', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.titlePageBuilder =
          (BuildContext _, ReaderTheme __) => const SizedBox.shrink();
      c.showTitlePage();
      expect(c.onTitlePage, isTrue);

      c.nextPage();
      expect(c.onTitlePage, isFalse);
      expect(c.pageIndex, 0);
    });

    test('在扉页时 prevPage 不动（前面没有内容了）', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.titlePageBuilder =
          (BuildContext _, ReaderTheme __) => const SizedBox.shrink();
      c.showTitlePage();
      c.prevPage();
      expect(c.onTitlePage, isTrue);
    });

    test('第一章首页 prevPage 回到扉页', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.titlePageBuilder =
          (BuildContext _, ReaderTheme __) => const SizedBox.shrink();
      c.prevPage();
      expect(c.onTitlePage, isTrue);
    });

    test('切章即离开扉页；非第 0 章不显示扉页', () async {
      final ReadingController c = await ready(FakeBookSource(chapters: 3));
      c.titlePageBuilder =
          (BuildContext _, ReaderTheme __) => const SizedBox.shrink();
      c.showTitlePage();
      c.loadChapter(1);
      expect(c.onTitlePage, isFalse);
      c.showTitlePage();
      expect(c.onTitlePage, isFalse, reason: '扉页只属于第 0 章');
    });
  });

  group('付费章导航', () {
    test('未解锁付费章只放行首页', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.isChapterLocked = (int ch) => ch == 0;
      expect(c.currentChapterLocked, isTrue);
      expect(c.visiblePageCount, 1);

      c.goToPage(3);
      expect(c.pageIndex, 0, reason: '锁定章内不得翻到后续页');
    });

    test('未解锁付费章 nextPage 直接跳到下一章', () async {
      final ReadingController c = await ready(FakeBookSource(chapters: 3));
      c.isChapterLocked = (int ch) => ch == 0;
      c.nextPage();
      expect(c.chapterIndex, 1);
      expect(c.pageIndex, 0);
    });

    test('从下一章向前翻入付费章时落在首页而非末页（防翻页卡死）', () async {
      final ReadingController c =
          await ready(FakeBookSource(chapters: 3), startChapter: 1);
      c.isChapterLocked = (int ch) => ch == 0;
      c.loadChapter(0, atEnd: true);
      expect(c.pageIndex, 0);
      expect(c.pendingAtEnd, isFalse, reason: '锁定章必须忽略 atEnd');
    });

    test('解锁后恢复完整页数与正常翻页', () async {
      final ReadingController c = await ready(FakeBookSource());
      bool locked = true;
      c.isChapterLocked = (int ch) => ch == 0 && locked;
      expect(c.visiblePageCount, 1);

      locked = false;
      expect(c.visiblePageCount, c.pages.length);
      c.goToPage(2);
      expect(c.pageIndex, 2);
    });

    test('未配置判定时全书都不加锁', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.chapterLocked(0), isFalse);
      expect(c.currentChapterLocked, isFalse);
      expect(c.visiblePageCount, c.pages.length);
    });
  });

  group('自动翻页状态', () {
    test('默认关闭，开关切换会通知监听者', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.autoTurning, isFalse);
      int notified = 0;
      c.addListener(() => notified++);

      c.setAutoTurning(true);
      expect(c.autoTurning, isTrue);
      expect(notified, 1);

      c.setAutoTurning(true);
      expect(notified, 1, reason: '重复设同值不发通知');

      c.setAutoTurning(false);
      expect(c.autoTurning, isFalse);
      expect(notified, 2);
    });

    test('间隔有 1 秒下限，重复设同值不发通知', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.setAutoTurnInterval(const Duration(milliseconds: 10));
      expect(c.autoTurnInterval, const Duration(seconds: 1));

      c.setAutoTurnInterval(const Duration(seconds: 8));
      expect(c.autoTurnInterval, const Duration(seconds: 8));

      int notified = 0;
      c.addListener(() => notified++);
      c.setAutoTurnInterval(const Duration(seconds: 8));
      expect(notified, 0);
    });
  });

  test('refreshLocks 只发通知，不影响分页结果', () async {
    final ReadingController c = await ready(FakeBookSource());
    final int pages = c.pages.length;
    int notified = 0;
    c.addListener(() => notified++);
    c.refreshLocks();
    expect(notified, 1);
    expect(c.pages.length, pages);
  });
}
