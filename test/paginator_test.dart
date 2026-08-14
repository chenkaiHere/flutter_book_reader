import 'package:flutter_book_reader/src/paginator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const TextStyle style = TextStyle(fontSize: 18, height: 1.6);
  const String indent = '　　';

  List<String> makeParagraphs(int n) =>
      List<String>.generate(n, (int i) => '这是第 ${i + 1} 段的内容，' * 6);

  test('分页保留全部内容且不丢字（块拼接 == 各段加缩进）', () {
    final List<String> paras = makeParagraphs(20);
    final List<ReaderPage> pages = Paginator.paginate(
      paragraphs: paras,
      style: style,
      size: const Size(320, 480),
      indent: indent,
      paragraphSpacing: 8,
      textAlign: TextAlign.justify,
    );

    expect(pages.length, greaterThan(1), reason: '应切成多页');

    final String joined =
        pages.expand((ReaderPage p) => p).map((ReaderBlock b) => b.text).join();
    final String expected = paras.map((String p) => '$indent$p').join();
    expect(joined, expected, reason: '分页只是切分，不应丢字或改写');
  });

  test('每段起始块标记 isParagraphStart，用于施加段间距', () {
    final List<ReaderPage> pages = Paginator.paginate(
      paragraphs: makeParagraphs(6),
      style: style,
      size: const Size(400, 2000), // 足够高，单页容纳
      indent: indent,
    );
    expect(pages.length, 1);
    final int starts =
        pages.first.where((ReaderBlock b) => b.isParagraphStart).length;
    expect(starts, 6, reason: '6 段应有 6 个段落起始块');
  });

  test('段间距变化会改变每页容纳的段数', () {
    List<ReaderPage> run(double spacing) => Paginator.paginate(
          paragraphs: makeParagraphs(40),
          style: style,
          size: const Size(320, 480),
          indent: indent,
          paragraphSpacing: spacing,
        );
    // 段间距越大，首页能放下的块越少（页数不减）
    expect(run(24).length, greaterThanOrEqualTo(run(0).length));
  });

  group('边界输入', () {
    test('空段落列表返回单个空页，不抛异常', () {
      final List<ReaderPage> pages = Paginator.paginate(
        paragraphs: const <String>[],
        style: style,
        size: const Size(320, 480),
        indent: indent,
      );
      expect(pages, hasLength(1));
      expect(pages.single, isEmpty);
    });

    test('视口宽 / 高为 0 时退化为单页，仍保留全部内容', () {
      for (final Size size in <Size>[
        const Size(0, 480),
        const Size(320, 0),
        Size.zero,
      ]) {
        final List<ReaderPage> pages = Paginator.paginate(
          paragraphs: makeParagraphs(3),
          style: style,
          size: size,
          indent: indent,
        );
        expect(pages, hasLength(1), reason: '$size');
        expect(pages.single, hasLength(3), reason: '$size 下内容不得丢失');
      }
    });

    test('单字段落也能正常分页', () {
      final List<ReaderPage> pages = Paginator.paginate(
        paragraphs: const <String>['一'],
        style: style,
        size: const Size(320, 480),
        indent: indent,
      );
      expect(pages, hasLength(1));
      expect(pages.single.single.text, '$indent一');
      expect(pages.single.single.isParagraphStart, isTrue);
      expect(pages.single.single.isParagraphEnd, isTrue);
    });

    test('极窄视口下强制每页至少放一行，不会死循环', () {
      final List<ReaderPage> pages = Paginator.paginate(
        paragraphs: makeParagraphs(3),
        style: style,
        // 高度只够一行左右，逼出「空页也放不下」的强制分支
        size: const Size(200, 30),
        indent: indent,
      );
      expect(pages.length, greaterThan(1));
      expect(pages.every((ReaderPage p) => p.isNotEmpty), isTrue);
    });

    test('跨页拆分的段落：只有最后一片标记 isParagraphEnd', () {
      final List<ReaderPage> pages = Paginator.paginate(
        paragraphs: <String>['很长的一段。' * 200],
        style: style,
        size: const Size(300, 200),
        indent: indent,
      );
      expect(pages.length, greaterThan(1), reason: '超长段落应被拆到多页');

      final List<ReaderBlock> blocks =
          pages.expand((ReaderPage p) => p).toList();
      expect(blocks.first.isParagraphStart, isTrue);
      expect(
          blocks.skip(1).every((ReaderBlock b) => !b.isParagraphStart), isTrue,
          reason: '续片不是段首');
      expect(blocks.last.isParagraphEnd, isTrue, reason: '最后一片才是段尾');
      expect(
        blocks
            .take(blocks.length - 1)
            .every((ReaderBlock b) => !b.isParagraphEnd),
        isTrue,
        reason: '中间各片都不是段尾（段评角标只画在真正段尾）',
      );
    });

    test('含 emoji（UTF-16 代理对）的段落不会被切成乱码', () {
      final List<ReaderPage> pages = Paginator.paginate(
        paragraphs: <String>['🌟星光灿烂的夜晚🌙' * 60],
        style: style,
        size: const Size(300, 180),
        indent: indent,
      );
      final String joined = pages
          .expand((ReaderPage p) => p)
          .map((ReaderBlock b) => b.text)
          .join();
      expect(joined, '$indent${'🌟星光灿烂的夜晚🌙' * 60}');
      // 每一片单独解码都不应出现半个代理对
      for (final ReaderBlock b in pages.expand((ReaderPage p) => p)) {
        expect(b.text.runes.toList(), isNotEmpty);
        expect(() => b.text.runes.map(String.fromCharCode).join(),
            returnsNormally);
      }
    });

    test('首页预留标题高度会让首页少放内容', () {
      List<ReaderPage> run(double reserve) => Paginator.paginate(
            paragraphs: makeParagraphs(40),
            style: style,
            size: const Size(320, 480),
            indent: indent,
            firstPageReserve: reserve,
          );
      expect(run(200).first.length, lessThanOrEqualTo(run(0).first.length));
    });

    test('预留高度过大时被钳制，不会挤空首页', () {
      final List<ReaderPage> pages = Paginator.paginate(
        paragraphs: makeParagraphs(10),
        style: style,
        size: const Size(320, 480),
        indent: indent,
        firstPageReserve: 99999,
      );
      expect(pages.first, isNotEmpty, reason: '首页至少要放得下一点内容');
    });
  });

  group('measureHeight', () {
    test('返回正数，且更长的文本更高', () {
      final double short = Paginator.measureHeight('短', style, 300);
      final double long = Paginator.measureHeight('很长的文本。' * 30, style, 300);
      expect(short, greaterThan(0));
      expect(long, greaterThan(short));
    });

    test('空文本高度不为负', () {
      expect(Paginator.measureHeight('', style, 300), greaterThanOrEqualTo(0));
    });
  });

  group('ReaderBlock', () {
    test('length 即文本长度', () {
      const ReaderBlock b = ReaderBlock(text: '你好世界', isParagraphStart: true);
      expect(b.length, 4);
    });

    test('isParagraphEnd 默认为 true（不拆分时段首即段尾）', () {
      const ReaderBlock b = ReaderBlock(text: 'x', isParagraphStart: true);
      expect(b.isParagraphEnd, isTrue);
    });
  });
}
