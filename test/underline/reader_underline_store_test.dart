import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Underline sample({
    int chapterIndex = 2,
    int start = 100,
    int end = 150,
    String text = '被划线的文字',
  }) =>
      Underline(
        chapterIndex: chapterIndex,
        start: start,
        end: end,
        text: text,
        chapterTitle: '第 3 章',
        createdAt: 1700000000000,
      );

  group('Underline.key', () {
    test('由章号与区间唯一确定', () {
      expect(sample().key, '2:100:150');
    });

    test('同区间视为同一条（去重用）', () {
      expect(sample(text: 'A').key, sample(text: 'B').key);
    });
  });

  group('Underline.overlaps', () {
    test('区间相交返回 true', () {
      expect(sample().overlaps(2, 140, 160), isTrue);
    });

    test('完全包含返回 true', () {
      expect(sample().overlaps(2, 0, 999), isTrue);
    });

    test('紧邻但不相交返回 false（end 不含）', () {
      expect(sample().overlaps(2, 150, 160), isFalse,
          reason: 'start == end 边界不算重叠');
      expect(sample().overlaps(2, 50, 100), isFalse,
          reason: 'end == start 边界不算重叠');
    });

    test('仅重叠一个字符也算重叠', () {
      expect(sample().overlaps(2, 149, 150), isTrue);
      expect(sample().overlaps(2, 99, 101), isTrue);
    });

    test('不同章即使区间相同也不重叠', () {
      expect(sample().overlaps(3, 100, 150), isFalse);
    });
  });

  group('Underline.copyWith', () {
    test('只改传入的字段，其余保持原值', () {
      final Underline changed = sample().copyWith(end: 200);
      expect(changed.end, 200);
      expect(changed.start, 100);
      expect(changed.chapterIndex, 2);
      expect(changed.chapterTitle, '第 3 章');
      expect(changed.createdAt, 1700000000000);
    });

    test('不传任何参数得到等值副本', () {
      expect(sample().copyWith().key, sample().key);
    });
  });

  group('Underline 序列化', () {
    test('toJson / fromJson 往返后字段不变', () {
      final Underline restored = Underline.fromJson(sample().toJson());
      expect(restored.key, '2:100:150');
      expect(restored.text, '被划线的文字');
      expect(restored.chapterTitle, '第 3 章');
      expect(restored.createdAt, 1700000000000);
    });

    test('缺字段时回退到默认值', () {
      final Underline restored = Underline.fromJson(<String, dynamic>{});
      expect(restored.key, '0:0:0');
      expect(restored.text, '');
    });
  });

  group('NoopReaderUnderlineStore', () {
    test('读取恒为空，写入不生效', () async {
      const ReaderUnderlineStore store = NoopReaderUnderlineStore();
      await store.save('book', <Underline>[sample()]);
      expect(await store.load('book'), isEmpty);
    });
  });

  group('InMemoryReaderUnderlineStore', () {
    test('写入后可读回，并按 bookId 隔离', () async {
      final ReaderUnderlineStore store = InMemoryReaderUnderlineStore();
      await store.save('a', <Underline>[sample()]);
      await store.save('b', <Underline>[sample(), sample(start: 0, end: 10)]);
      expect(await store.load('a'), hasLength(1));
      expect(await store.load('b'), hasLength(2));
      expect(await store.load('c'), isEmpty);
    });

    test('再次写入为整表覆盖', () async {
      final ReaderUnderlineStore store = InMemoryReaderUnderlineStore();
      await store.save('a', <Underline>[sample(), sample(start: 0, end: 10)]);
      await store.save('a', <Underline>[sample()]);
      expect(await store.load('a'), hasLength(1));
    });
  });
}
