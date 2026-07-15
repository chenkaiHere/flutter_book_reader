import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter/material.dart';

import 'data/book.dart';
import 'widgets/book_card.dart';

/// 书架 / 书城入口页：从 JSON 资源异步加载书籍列表。
class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  late final Future<List<Book>> _future = BookRepository.load();

  /// 书架级别共享的进度存储，让各书的阅读位置在会话内被记住
  final ReaderProgressStore _progressStore = InMemoryReaderProgressStore();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('书架'), centerTitle: false),
      body: FutureBuilder<List<Book>>(
        future: _future,
        builder: (BuildContext context, AsyncSnapshot<List<Book>> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('书籍加载失败：${snapshot.error}'));
          }
          final List<Book> books = snapshot.data ?? const <Book>[];
          if (books.isEmpty) {
            return const Center(child: Text('暂无书籍'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: books.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, int i) =>
                BookCard(book: books[i], progressStore: _progressStore),
          );
        },
      ),
    );
  }
}
