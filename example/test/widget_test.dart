import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_book_reader_example/data/asset_json_book_source.dart';
import 'package:flutter_book_reader_example/data/book.dart';
import 'package:flutter_book_reader_example/main.dart';

void main() {
  late final List<Book> books;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 预加载并缓存书籍（app 数据来自 assets/books.json）
    books = await BookRepository.load();
  });

  testWidgets('书架从 JSON 加载并展示书籍', (WidgetTester tester) async {
    await tester.pumpWidget(const ReadBookApp());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('书架'), findsOneWidget);
    expect(find.text(books.first.title), findsWidgets);
  });

  testWidgets('app 数据源接入 package 阅读器可正常阅读', (WidgetTester tester) async {
    final Book book = books.first;
    await tester.pumpWidget(
      MaterialApp(
        home: BookReader(source: AssetJsonBookSource(bookId: book.id)),
      ),
    );
    await tester.pumpAndSettle();

    // 首章标题与页码可见，证明 app 的 BookSource 实现与组件协同正常
    expect(find.text(book.chapters.first.title), findsWidgets);
    expect(find.textContaining('1/'), findsWidgets);
  });
}
