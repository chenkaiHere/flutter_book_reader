import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter/material.dart';

import '../data/asset_json_book_source.dart';
import '../data/book.dart';
import '../import/memory_book_source.dart';

/// 书架中的单本书卡片：模拟封面 + 书名/作者/简介，点击进入阅读器。
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.progressStore,
    required this.bookmarkStore,
    this.imported = false,
  });

  final Book book;

  /// 全书架共享的进度存储，用于跨书记忆阅读位置
  final ReaderProgressStore progressStore;

  /// 全书架共享的书签存储
  final ReaderBookmarkStore bookmarkStore;

  /// 是否为导入的书（导入书直接用内存中的 [Book] 作为数据源）
  final bool imported;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => BookReader(
            source: imported
                ? MemoryBookSource(book)
                : AssetJsonBookSource(bookId: book.id),
            progressStore: progressStore,
            bookmarkStore: bookmarkStore,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Cover(book: book),
            const SizedBox(width: 14),
            Expanded(child: _info(context)),
          ],
        ),
      ),
    );
  }

  Widget _info(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          book.title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          '${book.author} · 共 ${book.chapterCount} 章',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        const SizedBox(height: 8),
        Text(
          book.intro,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey[700]),
        ),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 96,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            book.coverColor,
            book.coverColor.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        book.title,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}
