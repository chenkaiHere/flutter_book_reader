import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/controller/chapter_content_mixin.dart';
import 'package:flutter_book_reader/src/controller/reading_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 正文加载 / 缓存 / 错误重试 / 淘汰。全部为纯逻辑，不建任何 Widget。
void main() {
  Future<ReadingController> controllerFor(
    FakeBookSource source, {
    int startChapter = 0,
  }) async {
    final BookManifest manifest = await source.loadManifest();
    final ReadingController c = ReadingController(
      source: source,
      manifest: manifest,
      startChapter: startChapter,
    );
    addTearDown(c.dispose);
    return c;
  }

  group('按需加载', () {
    test('加载前 bodyOf 为 null，加载后有内容', () async {
      final ReadingController c = await controllerFor(FakeBookSource());
      expect(c.isLoaded(3), isFalse);
      expect(c.bodyOf(3), isNull);

      await c.ensureLoaded(3);
      expect(c.isLoaded(3), isTrue);
      expect(c.bodyOf(3), isNotNull);
      expect(c.hasError(3), isFalse);
    });

    test('越界章号被忽略，不抛异常', () async {
      final ReadingController c =
          await controllerFor(FakeBookSource(chapters: 3));
      await c.ensureLoaded(-1);
      await c.ensureLoaded(99);
      expect(c.isLoaded(-1), isFalse);
      expect(c.isLoaded(99), isFalse);
    });

    test('已加载的章不会重复请求数据源', () async {
      final FakeBookSource source = FakeBookSource();
      final ReadingController c = await controllerFor(source);
      await c.ensureLoaded(1);
      final int callsAfterFirst = source.bodyLoadCount;
      await c.ensureLoaded(1);
      expect(source.bodyLoadCount, callsAfterFirst, reason: '命中缓存不应再取一次');
    });

    test('并发请求同一章只真正加载一次', () async {
      final FakeBookSource source = FakeBookSource();
      final ReadingController c = await controllerFor(source);
      await Future.wait<void>(<Future<void>>[
        c.ensureLoaded(2),
        c.ensureLoaded(2),
        c.ensureLoaded(2),
      ]);
      // 只断言该章的请求次数：构造时的 prefetchAround 会另外预取相邻章。
      expect(source.bodyLoadCountByChapter[2], 1);
    });
  });

  group('错误与重试', () {
    test('加载失败时记录错误态，正文仍为 null', () async {
      final FakeBookSource source = FakeBookSource()..failing.add(1);
      final ReadingController c = await controllerFor(source);
      await c.ensureLoaded(1);
      expect(c.hasError(1), isTrue);
      expect(c.bodyOf(1), isNull);
      expect(c.isLoaded(1), isFalse);
    });

    test('retry 在数据源恢复后能成功加载并清掉错误态', () async {
      final FakeBookSource source = FakeBookSource()..failing.add(1);
      final ReadingController c = await controllerFor(source);
      await c.ensureLoaded(1);
      expect(c.hasError(1), isTrue);

      source.failing.remove(1);
      await c.retry(1);
      expect(c.hasError(1), isFalse);
      expect(c.bodyOf(1), isNotNull);
    });

    test('失败的章仍可再次失败，不会被误认为已加载', () async {
      final FakeBookSource source = FakeBookSource()..failing.add(2);
      final ReadingController c = await controllerFor(source);
      await c.ensureLoaded(2);
      await c.retry(2);
      expect(c.hasError(2), isTrue);
      expect(c.isLoaded(2), isFalse);
    });

    test('回归：已失败的章不会被 ensureLoaded 自动重试（否则形成无限重试循环）', () async {
      final FakeBookSource source = FakeBookSource()..failing.add(2);
      final ReadingController c = await controllerFor(source);
      await c.ensureLoaded(2);
      expect(c.hasError(2), isTrue);
      final int attempts = source.bodyLoadCountByChapter[2]!;

      // pagesFor / prefetchAround 在每帧都可能触发 ensureLoaded：
      // 错误态必须拦住它们，否则界面永不稳定、请求被刷爆。
      for (int i = 0; i < 5; i++) {
        await c.ensureLoaded(2);
        c.prefetchAround(2);
      }
      await Future<void>.delayed(Duration.zero);
      expect(source.bodyLoadCountByChapter[2], attempts,
          reason: '错误态下不得再自动发起加载');
    });

    test('显式 retry 仍能突破错误态（重试是用户主动行为）', () async {
      final FakeBookSource source = FakeBookSource()..failing.add(2);
      final ReadingController c = await controllerFor(source);
      await c.ensureLoaded(2);
      final int attempts = source.bodyLoadCountByChapter[2]!;

      await c.retry(2);
      expect(source.bodyLoadCountByChapter[2], attempts + 1);
    });
  });

  group('预取与淘汰', () {
    test('prefetchAround 取当前章及左右相邻章', () async {
      final ReadingController c = await controllerFor(
        FakeBookSource(chapters: 5),
        startChapter: 2,
      );
      c.prefetchAround(2);
      await Future<void>.delayed(Duration.zero);
      expect(c.isLoaded(1), isTrue);
      expect(c.isLoaded(2), isTrue);
      expect(c.isLoaded(3), isTrue);
    });

    test('缓存超过上限后淘汰离当前章最远的，且保住当前章与相邻章', () async {
      const int max = ChapterContentMixin.maxCachedChapters;
      const int total = max + 6;
      final ReadingController c = await controllerFor(
        FakeBookSource(chapters: total),
        startChapter: 0,
      );
      // 顺序读到较后的章节，使前面的章成为「最远」缓存
      for (int i = 0; i < total; i++) {
        await c.ensureLoaded(i);
        c.setCurrentChapter(i);
      }
      final int current = c.chapterIndex;
      expect(c.isLoaded(current), isTrue, reason: '当前章必须保留');
      expect(c.isLoaded(current - 1), isTrue, reason: '相邻章必须保留');

      final int cached =
          List<int>.generate(total, (int i) => i).where(c.isLoaded).length;
      expect(cached, lessThanOrEqualTo(max + 1),
          reason: '缓存量必须被上限约束住（+1 容纳 flowChapters 保护项）');
      expect(c.isLoaded(2), isFalse, reason: '既非当前章相邻、也不在纵向流里的远章应被淘汰');
    });

    test('纵向流里的章节不会被淘汰（flowChapters 属保护集）', () async {
      const int max = ChapterContentMixin.maxCachedChapters;
      const int total = max + 6;
      final ReadingController c = await controllerFor(
        FakeBookSource(chapters: total),
        startChapter: 0,
      );
      expect(c.flowChapters, <int>[0], reason: '起始章即纵向流首章');
      for (int i = 0; i < total; i++) {
        await c.ensureLoaded(i);
        c.setCurrentChapter(i);
      }
      expect(c.isLoaded(0), isTrue, reason: '第 0 章仍在 flowChapters 中，必须免于淘汰');
    });
  });

  group('lockInfoFor', () {
    test('带上章号 / 标题 / 字数', () async {
      final ReadingController c = await controllerFor(FakeBookSource());
      await c.ensureLoaded(1);
      final ReaderLockInfo info = c.lockInfoFor(1);
      expect(info.chapterIndex, 1);
      expect(info.chapterTitle, c.chapterTitleAt(1));
      expect(info.wordCount, c.bodyOf(1)!.length);
    });

    test('正文未加载时字数为 0（不阻塞解锁块渲染）', () async {
      final ReadingController c = await controllerFor(FakeBookSource());
      expect(c.lockInfoFor(4).wordCount, 0);
    });
  });
}
