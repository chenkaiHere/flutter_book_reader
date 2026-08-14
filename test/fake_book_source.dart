import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter/material.dart';

/// 测试用假数据源：证明阅读器只依赖 [BookSource] 抽象，无需真实资源/网络。
class FakeBookSource extends BookSource {
  FakeBookSource({this.chapters = 5, this.paragraphsPerChapter = 60});

  final int chapters;
  final int paragraphsPerChapter;

  /// 这些章节的正文加载会抛错（用于测试错误/重试）。可动态增删。
  final Set<int> failing = <int>{};

  /// 正文被真正请求的次数：用于断言缓存 / 去重生效（fake 优于 mock，见 CLAUDE.md §7.3）。
  int bodyLoadCount = 0;

  /// 每章正文请求各被调用的次数。
  final Map<int, int> bodyLoadCountByChapter = <int, int>{};

  @override
  Future<BookManifest> loadManifest() async => BookManifest(
        id: 'fake-book',
        title: '测试书',
        author: '作者',
        intro: '这是一本用于测试的书籍简介。',
        coverColor: const Color(0xFF808080),
        chapterTitles:
            List<String>.generate(chapters, (int i) => '第 ${i + 1} 章'),
      );

  @override
  Future<String> loadChapterBody(int index) async {
    bodyLoadCount++;
    bodyLoadCountByChapter.update(index, (int n) => n + 1, ifAbsent: () => 1);
    if (failing.contains(index)) throw Exception('章节 $index 加载失败');
    return _body(index);
  }

  /// 每段文字都带章号 + 段号，因此**互不相同** —— 跟读定位、段落锚点等用例需要
  /// 能唯一命中某一段；若各段文字相同，`indexOf` 永远命中第一处，测不出真实行为。
  String _body(int index) => List<String>.generate(
        paragraphsPerChapter,
        (int i) => '　　这是第 ${index + 1} 章第 ${i + 1} 段的正文，'
            '用于填充足够的文字以便分页测试。',
      ).join('\n');
}
