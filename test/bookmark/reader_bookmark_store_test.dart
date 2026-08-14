import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Bookmark sample({
    int chapterIndex = 1,
    int charOffset = 120,
    String chapterTitle = '第 2 章',
    int createdAt = 1700000000000,
  }) =>
      Bookmark(
        chapterIndex: chapterIndex,
        charOffset: charOffset,
        chapterTitle: chapterTitle,
        createdAt: createdAt,
      );

  group('Bookmark.key', () {
    test('由章号与章内偏移唯一确定', () {
      expect(sample().key, '1:120');
    });

    test('同章同偏移视为同一条（支持「再次点击即取消」）', () {
      expect(sample(chapterTitle: 'A').key, sample(chapterTitle: 'B').key);
    });

    test('偏移不同即为不同条目', () {
      expect(sample(charOffset: 0).key, isNot(sample(charOffset: 1).key));
    });
  });

  group('Bookmark 序列化', () {
    test('toJson / fromJson 往返后字段不变', () {
      final Bookmark restored = Bookmark.fromJson(sample().toJson());
      expect(restored.chapterIndex, 1);
      expect(restored.charOffset, 120);
      expect(restored.chapterTitle, '第 2 章');
      expect(restored.createdAt, 1700000000000);
    });

    test('缺字段时回退到默认值而不是抛异常', () {
      final Bookmark restored = Bookmark.fromJson(<String, dynamic>{});
      expect(restored.chapterIndex, 0);
      expect(restored.charOffset, 0);
      expect(restored.chapterTitle, '');
      expect(restored.createdAt, 0);
    });

    test('显式 null 视为缺字段，回退默认值', () {
      final Bookmark restored = Bookmark.fromJson(<String, dynamic>{
        'chapterIndex': null,
        'charOffset': null,
        'chapterTitle': null,
      });
      expect(restored.chapterIndex, 0);
      expect(restored.charOffset, 0);
      expect(restored.chapterTitle, '');
    });
  });

  group('NoopReaderBookmarkStore', () {
    test('读取恒为空列表', () async {
      const ReaderBookmarkStore store = NoopReaderBookmarkStore();
      expect(await store.load('book'), isEmpty);
    });

    test('写入后读取仍为空（不持久化）', () async {
      const ReaderBookmarkStore store = NoopReaderBookmarkStore();
      await store.save('book', <Bookmark>[sample()]);
      expect(await store.load('book'), isEmpty);
    });
  });

  group('InMemoryReaderBookmarkStore', () {
    test('未写入过的书返回空列表', () async {
      final ReaderBookmarkStore store = InMemoryReaderBookmarkStore();
      expect(await store.load('unknown'), isEmpty);
    });

    test('写入后可读回', () async {
      final ReaderBookmarkStore store = InMemoryReaderBookmarkStore();
      await store.save('book', <Bookmark>[sample()]);
      final List<Bookmark> loaded = await store.load('book');
      expect(loaded, hasLength(1));
      expect(loaded.single.key, '1:120');
    });

    test('按 bookId 隔离，互不干扰', () async {
      final ReaderBookmarkStore store = InMemoryReaderBookmarkStore();
      await store.save('a', <Bookmark>[sample()]);
      await store.save('b', <Bookmark>[sample(), sample(charOffset: 9)]);
      expect(await store.load('a'), hasLength(1));
      expect(await store.load('b'), hasLength(2));
    });

    test('再次写入同一本书为整表覆盖', () async {
      final ReaderBookmarkStore store = InMemoryReaderBookmarkStore();
      await store.save('a', <Bookmark>[sample(), sample(charOffset: 9)]);
      await store.save('a', <Bookmark>[sample()]);
      expect(await store.load('a'), hasLength(1));
    });

    test('读回的列表被改动不影响存储内容', () async {
      final ReaderBookmarkStore store = InMemoryReaderBookmarkStore();
      await store.save('a', <Bookmark>[sample()]);
      final List<Bookmark> first = await store.load('a');
      try {
        first.add(sample(charOffset: 999));
      } on UnsupportedError {
        // 返回不可变列表也是合规实现
      }
      expect(await store.load('a'), hasLength(1));
    });
  });
}
