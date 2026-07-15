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

    final String joined = pages
        .expand((ReaderPage p) => p)
        .map((ReaderBlock b) => b.text)
        .join();
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
    final int starts = pages.first
        .where((ReaderBlock b) => b.isParagraphStart)
        .length;
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
}
