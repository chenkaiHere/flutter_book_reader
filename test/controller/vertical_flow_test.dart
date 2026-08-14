import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader/src/controller/reading_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_book_source.dart';

/// 上下滚动模式的章节流装配。纯逻辑，不建 Widget。
void main() {
  Future<ReadingController> flow(
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

  group('appendNextFlowChapter', () {
    test('起始只含当前章', () async {
      final ReadingController c = await flow(FakeBookSource(), startChapter: 1);
      expect(c.flowChapters, <int>[1]);
    });

    test('向下接章后追加到末尾并保持升序', () async {
      final ReadingController c = await flow(FakeBookSource(chapters: 4));
      expect(c.appendNextFlowChapter(), isTrue);
      expect(c.appendNextFlowChapter(), isTrue);
      expect(c.flowChapters, <int>[0, 1, 2]);
    });

    test('已到末章时不再追加', () async {
      final ReadingController c =
          await flow(FakeBookSource(chapters: 2), startChapter: 1);
      expect(c.appendNextFlowChapter(), isFalse);
      expect(c.flowChapters, <int>[1]);
    });

    test('接章会通知监听者并触发正文加载', () async {
      final FakeBookSource source = FakeBookSource(chapters: 3);
      final ReadingController c = await flow(source);
      int notified = 0;
      c.addListener(() => notified++);
      expect(c.appendNextFlowChapter(), isTrue);
      expect(notified, greaterThanOrEqualTo(1));
      await Future<void>.delayed(Duration.zero);
      expect(c.isLoaded(1), isTrue);
    });

    test('末章为未解锁付费章时停止接章（防付费正文漏出）', () async {
      final ReadingController c = await flow(FakeBookSource(chapters: 4));
      c.isChapterLocked = (int ch) => ch == 0;
      expect(c.appendNextFlowChapter(), isFalse);
      expect(c.flowChapters, <int>[0]);
    });

    test('付费章解锁后可以继续接章', () async {
      final ReadingController c = await flow(FakeBookSource(chapters: 4));
      bool locked = true;
      c.isChapterLocked = (int ch) => ch == 0 && locked;
      expect(c.appendNextFlowChapter(), isFalse);
      locked = false;
      expect(c.appendNextFlowChapter(), isTrue);
      expect(c.flowChapters, <int>[0, 1]);
    });
  });

  group('prependPrevFlowChapter', () {
    test('向上接章插到头部，返回被插入的章号', () async {
      final ReadingController c =
          await flow(FakeBookSource(chapters: 4), startChapter: 2);
      expect(c.prependPrevFlowChapter(), 1);
      expect(c.prependPrevFlowChapter(), 0);
      expect(c.flowChapters, <int>[0, 1, 2]);
    });

    test('已到首章时返回 null', () async {
      final ReadingController c = await flow(FakeBookSource());
      expect(c.prependPrevFlowChapter(), isNull);
      expect(c.flowChapters, <int>[0]);
    });

    test('接章会触发正文加载', () async {
      final ReadingController c =
          await flow(FakeBookSource(chapters: 3), startChapter: 2);
      expect(c.prependPrevFlowChapter(), 1);
      await Future<void>.delayed(Duration.zero);
      expect(c.isLoaded(1), isTrue);
    });
  });

  group('setCurrentChapter', () {
    test('切到新章会更新章号、清空分页签名并通知', () async {
      final ReadingController c = await flow(FakeBookSource(chapters: 3));
      c.signature = 'stale-signature';
      int notified = 0;
      c.addListener(() => notified++);

      c.setCurrentChapter(2);
      expect(c.chapterIndex, 2);
      expect(c.signature, isEmpty, reason: '切回横向模式时须按新章重排');
      expect(notified, greaterThanOrEqualTo(1));
    });

    test('设为当前章时什么都不做', () async {
      final ReadingController c = await flow(FakeBookSource());
      c.signature = 'keep-me';
      int notified = 0;
      c.addListener(() => notified++);

      c.setCurrentChapter(c.chapterIndex);
      expect(c.signature, 'keep-me');
      expect(notified, 0);
    });
  });

  test('双向接章后 flowChapters 连续无重复', () async {
    final ReadingController c =
        await flow(FakeBookSource(chapters: 5), startChapter: 2);
    c.appendNextFlowChapter();
    c.prependPrevFlowChapter();
    c.appendNextFlowChapter();
    c.prependPrevFlowChapter();
    expect(c.flowChapters, <int>[0, 1, 2, 3, 4]);
    expect(c.flowChapters.toSet(), hasLength(c.flowChapters.length));
  });
}
