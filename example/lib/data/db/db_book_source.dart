import 'package:flutter/material.dart' show Color;
import 'package:flutter_book_reader/flutter_book_reader.dart';

import 'app_database.dart';

/// 基于 drift 的 [BookSource]：目录只取章节标题，正文按章号单条懒读，
/// 全程不把整本书装进内存。内置书与导入书统一走此实现。
class DbBookSource extends BookSource {
  DbBookSource(this.db, this.bookId);

  final AppDatabase db;
  final int bookId;

  @override
  Future<BookManifest> loadManifest() async {
    final BookRow? row = await db.bookById(bookId);
    if (row == null) {
      throw StateError('书籍不存在: $bookId');
    }
    final List<String> titles = await db.chapterTitles(bookId);
    return BookManifest(
      id: row.id,
      title: row.title,
      author: row.author,
      intro: row.intro,
      coverColor: Color(row.coverColor),
      chapterTitles: titles,
    );
  }

  @override
  Future<String> loadChapterBody(int chapterIndex) async =>
      await db.chapterBody(bookId, chapterIndex) ?? '';
}
