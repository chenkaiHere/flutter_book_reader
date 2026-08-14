import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReadingPosition', () {
    test('charOffset 默认为 0（只给章号即可）', () {
      expect(const ReadingPosition(chapterIndex: 3).charOffset, 0);
    });

    test('toJson / fromJson 往返后字段不变', () {
      const ReadingPosition pos =
          ReadingPosition(chapterIndex: 7, charOffset: 250);
      final ReadingPosition restored = ReadingPosition.fromJson(pos.toJson());
      expect(restored.chapterIndex, 7);
      expect(restored.charOffset, 250);
    });

    test('缺字段时回退到 0', () {
      final ReadingPosition restored =
          ReadingPosition.fromJson(<String, dynamic>{});
      expect(restored.chapterIndex, 0);
      expect(restored.charOffset, 0);
    });
  });

  group('NoopReaderProgressStore', () {
    test('读取恒为 null（无进度）', () async {
      const ReaderProgressStore store = NoopReaderProgressStore();
      expect(await store.load('book'), isNull);
    });

    test('写入后读取仍为 null（不持久化）', () async {
      const ReaderProgressStore store = NoopReaderProgressStore();
      await store.save('book', const ReadingPosition(chapterIndex: 2));
      expect(await store.load('book'), isNull);
    });
  });

  group('InMemoryReaderProgressStore', () {
    test('未存过的书返回 null', () async {
      final ReaderProgressStore store = InMemoryReaderProgressStore();
      expect(await store.load('unknown'), isNull);
    });

    test('写入后可读回', () async {
      final ReaderProgressStore store = InMemoryReaderProgressStore();
      await store.save(
          'a', const ReadingPosition(chapterIndex: 4, charOffset: 8));
      final ReadingPosition? loaded = await store.load('a');
      expect(loaded?.chapterIndex, 4);
      expect(loaded?.charOffset, 8);
    });

    test('同一本书重复写入取最后一次', () async {
      final ReaderProgressStore store = InMemoryReaderProgressStore();
      await store.save('a', const ReadingPosition(chapterIndex: 1));
      await store.save('a', const ReadingPosition(chapterIndex: 9));
      expect((await store.load('a'))?.chapterIndex, 9);
    });

    test('按 bookId 隔离', () async {
      final ReaderProgressStore store = InMemoryReaderProgressStore();
      await store.save('a', const ReadingPosition(chapterIndex: 1));
      await store.save('b', const ReadingPosition(chapterIndex: 2));
      expect((await store.load('a'))?.chapterIndex, 1);
      expect((await store.load('b'))?.chapterIndex, 2);
    });
  });
}
