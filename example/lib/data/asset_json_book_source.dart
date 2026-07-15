import 'package:flutter_book_reader/flutter_book_reader.dart';

import 'book.dart';

/// 从 assets/books.json 读取的书籍数据源实现（app 侧，实现 package 的 [BookSource]）。
///
/// 复用 [BookRepository] 的解析与缓存；正文按章懒加载（此实现下为本地即时返回，
/// 但接口保持异步，替换成网络实现时行为一致）。
class AssetJsonBookSource extends BookSource {
  AssetJsonBookSource({required this.bookId});

  final int bookId;

  @override
  Future<BookManifest> loadManifest() async {
    final Book book = _resolve(await BookRepository.load());
    return BookManifest(
      id: book.id,
      title: book.title,
      author: book.author,
      intro: book.intro,
      coverColor: book.coverColor,
      chapterTitles:
          book.chapters.map((Chapter c) => c.title).toList(growable: false),
    );
  }

  @override
  Future<String> loadChapterBody(int chapterIndex) async {
    final Book book = _resolve(await BookRepository.load());
    return book.chapters[chapterIndex].body;
  }

  Book _resolve(List<Book> books) =>
      books.firstWhere((Book b) => b.id == bookId, orElse: () => books.first);
}
