import 'package:flutter/material.dart';

/// 书籍清单：书籍元信息 + 目录（仅章节标题，轻量）。
///
/// 章节正文不在清单内，按需通过 [BookSource.loadChapterBody] 拉取。
@immutable
class BookManifest {
  const BookManifest({
    required this.id,
    required this.title,
    required this.author,
    required this.intro,
    required this.coverColor,
    required this.chapterTitles,
  });

  final Object id;
  final String title;
  final String author;
  final String intro;
  final Color coverColor;
  final List<String> chapterTitles;

  int get chapterCount => chapterTitles.length;
}

/// 书籍数据源抽象。
///
/// 阅读器只依赖这个接口，不关心数据来自 JSON 资源、网络还是数据库。
/// 商用接入时实现自己的 [BookSource]（如 `HttpBookSource`、`DbBookSource`）即可，
/// 无需改动阅读器本身。约定：
/// - [loadManifest] 返回书籍信息与目录，通常一次调用；
/// - [loadChapterBody] 按章号懒加载正文，允许耗时（网络/IO），阅读器会显示加载态。
abstract class BookSource {
  const BookSource();

  Future<BookManifest> loadManifest();

  Future<String> loadChapterBody(int chapterIndex);
}
