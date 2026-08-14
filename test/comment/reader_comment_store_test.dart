import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Comment sample({
    int chapterIndex = 1,
    int start = 10,
    int end = 40,
    String quote = '原文片段',
    String text = '我的想法',
    int createdAt = 1700000000000,
  }) =>
      Comment(
        chapterIndex: chapterIndex,
        start: start,
        end: end,
        quote: quote,
        text: text,
        chapterTitle: '第 2 章',
        createdAt: createdAt,
      );

  group('Comment.key', () {
    test('包含创建时间，使同一段落可有多条评论', () {
      expect(sample().key, '1:10:40:1700000000000');
      expect(
        sample(createdAt: 1).key,
        isNot(sample(createdAt: 2).key),
        reason: '同区间不同时间必须是不同条目',
      );
    });

    test('正文不同但区间与时间相同视为同一条', () {
      expect(sample(text: 'A').key, sample(text: 'B').key);
    });
  });

  group('Comment.copyWith', () {
    test('只改 quote / text，锚点与时间保持不变', () {
      final Comment changed = sample().copyWith(text: '改后的想法');
      expect(changed.text, '改后的想法');
      expect(changed.quote, '原文片段');
      expect(changed.key, sample().key, reason: 'copyWith 不应改变去重键');
    });
  });

  group('Comment 序列化', () {
    test('toJson / fromJson 往返后字段不变', () {
      final Comment restored = Comment.fromJson(sample().toJson());
      expect(restored.key, '1:10:40:1700000000000');
      expect(restored.quote, '原文片段');
      expect(restored.text, '我的想法');
      expect(restored.chapterTitle, '第 2 章');
    });

    test('缺字段时回退到默认值', () {
      final Comment restored = Comment.fromJson(<String, dynamic>{});
      expect(restored.chapterIndex, 0);
      expect(restored.start, 0);
      expect(restored.end, 0);
      expect(restored.quote, '');
      expect(restored.text, '');
    });
  });

  group('NoopReaderCommentStore', () {
    test('读取恒为空，写入不生效', () async {
      const ReaderCommentStore store = NoopReaderCommentStore();
      await store.save('book', <Comment>[sample()]);
      expect(await store.load('book'), isEmpty);
    });
  });

  group('InMemoryReaderCommentStore', () {
    test('写入后可读回，并按 bookId 隔离', () async {
      final ReaderCommentStore store = InMemoryReaderCommentStore();
      await store.save('a', <Comment>[sample()]);
      await store.save('b', <Comment>[sample(), sample(createdAt: 2)]);
      expect(await store.load('a'), hasLength(1));
      expect(await store.load('b'), hasLength(2));
      expect(await store.load('missing'), isEmpty);
    });

    test('再次写入为整表覆盖', () async {
      final ReaderCommentStore store = InMemoryReaderCommentStore();
      await store.save('a', <Comment>[sample(), sample(createdAt: 2)]);
      await store.save('a', <Comment>[sample()]);
      expect(await store.load('a'), hasLength(1));
    });
  });
}
