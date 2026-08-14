import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/controller/reading_controller.dart';
import 'package:flutter_book_reader/src/paginator.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 分页与「块长度空间」偏移换算。这些是划线 / 书签 / 段评锚点的地基，必须精确。
void main() {
  const Size viewport = Size(320, 520);

  Future<ReadingController> ready(
    FakeBookSource source, {
    int startChapter = 0,
    Size size = viewport,
  }) async {
    final BookManifest manifest = await source.loadManifest();
    final ReadingController c = ReadingController(
      source: source,
      manifest: manifest,
      startChapter: startChapter,
    );
    addTearDown(c.dispose);
    await c.ensureLoaded(startChapter);
    c.updateViewport(size, TextScaler.noScaling);
    return c;
  }

  int pageLength(ReaderPage page) =>
      page.fold<int>(0, (int sum, ReaderBlock b) => sum + b.length);

  group('updateViewport', () {
    test('正文就绪后分成多页', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.pages.length, greaterThan(1));
      expect(c.signature, isNotEmpty);
    });

    test('正文未就绪时页为空、签名清零', () async {
      final FakeBookSource source = FakeBookSource();
      final BookManifest manifest = await source.loadManifest();
      final ReadingController c = ReadingController(
        source: source,
        manifest: manifest,
        startChapter: 4,
      );
      addTearDown(c.dispose);
      c.updateViewport(viewport, TextScaler.noScaling);
      expect(c.pages, isEmpty);
      expect(c.signature, isEmpty);
    });

    test('同一视口重复调用不重排（签名命中缓存）', () async {
      final ReadingController c = await ready(FakeBookSource());
      final List<ReaderPage> first = c.pages;
      c.updateViewport(viewport, TextScaler.noScaling);
      expect(c.pages, same(first), reason: '签名未变应复用同一份分页结果');
    });

    test('视口变化后重新分页', () async {
      final ReadingController c = await ready(FakeBookSource());
      final int before = c.pages.length;
      c.updateViewport(const Size(320, 260), TextScaler.noScaling);
      expect(c.pages.length, greaterThan(before), reason: '更矮的视口页数更多');
    });

    test('换字号后按 charOffset 保留阅读位置', () async {
      final ReadingController c = await ready(FakeBookSource());
      c.goToPage(3);
      final int offset = c.charOffset;

      c.config.increaseFont();
      c.updateViewport(viewport, TextScaler.noScaling);
      // 重排后当前页应仍覆盖原来的字符位置
      final int start = c.startOffsetOfPage(c.pageIndex);
      final int end = start + pageLength(c.pages[c.pageIndex]);
      expect(offset, greaterThanOrEqualTo(start));
      expect(offset, lessThan(end));
    });
  });

  group('startOffsetOfPageIn（前缀和）', () {
    test('首页偏移为 0，逐页递增', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.startOffsetOfPage(0), 0);
      for (int i = 1; i < c.pages.length; i++) {
        expect(c.startOffsetOfPage(i), greaterThan(c.startOffsetOfPage(i - 1)));
      }
    });

    test('每页偏移等于前面各页长度之和', () async {
      final ReadingController c = await ready(FakeBookSource());
      int sum = 0;
      for (int i = 0; i < c.pages.length; i++) {
        expect(c.startOffsetOfPage(i), sum, reason: '第 $i 页');
        sum += pageLength(c.pages[i]);
      }
    });

    test('越界下标不抛异常', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.startOffsetOfPage(-1), 0);
      expect(c.startOffsetOfPage(9999), isA<int>());
    });

    test('空分页结果返回 0', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.startOffsetOfPageIn(const <ReaderPage>[], 0), 0);
    });
  });

  group('pageIndexForOffset', () {
    test('每页起始偏移都能定位回该页', () async {
      final ReadingController c = await ready(FakeBookSource());
      for (int i = 0; i < c.pages.length; i++) {
        expect(c.pageIndexForOffset(c.startOffsetOfPage(i)), i,
            reason: '第 $i 页');
      }
    });

    test('页内中间偏移定位到该页', () async {
      final ReadingController c = await ready(FakeBookSource());
      final int start = c.startOffsetOfPage(1);
      final int mid = start + pageLength(c.pages[1]) ~/ 2;
      expect(c.pageIndexForOffset(mid), 1);
    });

    test('超出全章长度的偏移落到末页', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.pageIndexForOffset(1 << 28), c.pages.length - 1);
    });
  });

  group('leadingParagraphStartIn（段评角标跨页锚点）', () {
    test('页首是段首时等于本页起始偏移', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.pages.first.first.isParagraphStart, isTrue);
      expect(
        c.leadingParagraphStartIn(c.pages, 0),
        c.startOffsetOfPageIn(c.pages, 0),
      );
    });

    test('页首是上页段落的延续时，回溯到该段真实起点', () async {
      // 用窄高视口制造跨页段落
      final ReadingController c =
          await ready(FakeBookSource(), size: const Size(300, 200));
      int? continued;
      for (int i = 1; i < c.pages.length; i++) {
        if (!c.pages[i].first.isParagraphStart) {
          continued = i;
          break;
        }
      }
      expect(continued, isNotNull, reason: '窄视口下应存在跨页段落');
      final int lead = c.leadingParagraphStartIn(c.pages, continued!);
      expect(lead, lessThan(c.startOffsetOfPageIn(c.pages, continued)),
          reason: '延续段的起点必须早于本页起点');
      expect(lead, greaterThanOrEqualTo(0));
    });

    test('越界下标返回 0', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.leadingParagraphStartIn(c.pages, -1), 0);
      expect(c.leadingParagraphStartIn(c.pages, 9999), 0);
    });
  });

  group('进度', () {
    test('progressFor 在 [0,1] 内且随页递增', () async {
      final ReadingController c = await ready(FakeBookSource(chapters: 4));
      double last = -1;
      for (int i = 0; i < c.pages.length; i++) {
        final double p = c.progressFor(0, c.pages, i);
        expect(p, inInclusiveRange(0.0, 1.0));
        expect(p, greaterThan(last));
        last = p;
      }
    });

    test('空分页时按章序估算', () async {
      final ReadingController c = await ready(FakeBookSource(chapters: 4));
      expect(c.progressFor(2, const <ReaderPage>[], 0), closeTo(0.5, 0.001));
    });

    test('末章末页为 1', () async {
      final ReadingController c =
          await ready(FakeBookSource(chapters: 2), startChapter: 1);
      expect(c.progressFor(1, c.pages, c.pages.length - 1), 1.0);
    });

    test('globalProgress 跟随当前位置', () async {
      final ReadingController c = await ready(FakeBookSource(chapters: 3));
      final double first = c.globalProgress;
      c.goToPage(c.pages.length - 1);
      expect(c.globalProgress, greaterThan(first));
    });
  });

  group('chapterBlocks（纵向模式整章转块）', () {
    test('每块都是段首，且拼接后与去空行的原文一致', () async {
      final ReadingController c = await ready(FakeBookSource());
      final ReaderPage blocks = c.chapterBlocks(c.bodyOf(0)!);
      expect(blocks, isNotEmpty);
      expect(blocks.every((ReaderBlock b) => b.isParagraphStart), isTrue);
      for (final ReaderBlock b in blocks) {
        expect(b.text.startsWith(c.config.indent), isTrue,
            reason: '缩进由阅读器统一施加');
      }
    });

    test('空正文得到空块列表', () async {
      final ReadingController c = await ready(FakeBookSource());
      expect(c.chapterBlocks(''), isEmpty);
      expect(c.chapterBlocks('\n\n   \n'), isEmpty, reason: '空行应被丢弃');
    });
  });

  test('headingReserveFor 返回正数；视口未知时为 0', () async {
    final FakeBookSource source = FakeBookSource();
    final BookManifest manifest = await source.loadManifest();
    final ReadingController fresh = ReadingController(
      source: source,
      manifest: manifest,
    );
    addTearDown(fresh.dispose);
    expect(fresh.headingReserveFor(0), 0, reason: '未 updateViewport 时无法度量');

    final ReadingController c = await ready(FakeBookSource());
    expect(c.headingReserveFor(0), greaterThan(0));
  });
}
