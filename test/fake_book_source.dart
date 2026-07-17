import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter/material.dart';

/// 测试用假数据源：证明阅读器只依赖 [BookSource] 抽象，无需真实资源/网络。
class FakeBookSource extends BookSource {
  FakeBookSource({this.chapters = 5, this.paragraphsPerChapter = 60});

  final int chapters;
  final int paragraphsPerChapter;

  /// 这些章节的正文加载会抛错（用于测试错误/重试）。可动态增删。
  final Set<int> failing = <int>{};

  @override
  Future<BookManifest> loadManifest() async => BookManifest(
        id: 'fake-book',
        title: '测试书',
        author: '作者',
        intro: '简介',
        coverColor: const Color(0xFF808080),
        chapterTitles:
            List<String>.generate(chapters, (int i) => '第 ${i + 1} 章'),
      );

  @override
  Future<String> loadChapterBody(int index) async {
    if (failing.contains(index)) throw Exception('章节 $index 加载失败');
    return _body(index);
  }

  String _body(int index) => List<String>.filled(
        paragraphsPerChapter,
        '　　这是第 ${index + 1} 章的正文段落，用于填充足够的文字以便分页测试。',
      ).join('\n');
}
