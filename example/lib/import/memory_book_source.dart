import 'package:flutter_book_reader/flutter_book_reader.dart';

import '../data/book.dart';

/// 基于内存中一本已解析 [Book] 的数据源，用于阅读导入的 txt。
///
/// 与 [AssetJsonBookSource] 一样实现插件的 [BookSource] 抽象，只是数据来自
/// 已导入并解析好的 [Book]（而非 assets）。正文按章即时返回。
class MemoryBookSource extends BookSource {
  MemoryBookSource(this.book);

  final Book book;

  @override
  Future<BookManifest> loadManifest() async => BookManifest(
    id: book.id,
    title: book.title,
    author: book.author,
    intro: book.intro,
    coverColor: book.coverColor,
    chapterTitles: book.chapters
        .map((Chapter c) => c.title)
        .toList(growable: false),
  );

  @override
  Future<String> loadChapterBody(int chapterIndex) async =>
      book.chapters[chapterIndex].body;
}
