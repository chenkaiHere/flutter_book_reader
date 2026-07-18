import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_book_reader_example/bookshelf_page.dart';
import 'package:flutter_book_reader_example/data/book.dart';
import 'package:flutter_book_reader_example/data/db/app_database.dart';
import 'package:flutter_book_reader_example/data/db/book_db.dart';
import 'package:flutter_book_reader_example/data/db/db_book_source.dart';
import 'package:flutter_book_reader_example/l10n/app_localizations.dart';

void main() {
  late final List<Book> books;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    // 内置书数据来自 assets，用于取期望标题（三国演义置顶）。
    books = await BookRepository.load();
  });

  AppDatabase memDb() => AppDatabase(NativeDatabase.memory());

  // 固定中文语言，使断言的中文文案生效。
  Widget app(Widget home) => MaterialApp(
    locale: const Locale('zh'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  );

  testWidgets('书架从 drift 加载并展示书籍（首次自动播种内置书）', (WidgetTester tester) async {
    final AppDatabase db = memDb();
    addTearDown(db.close);

    await tester.pumpWidget(app(BookshelfPage(database: db)));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('书架'), findsOneWidget);
    // 三国演义置顶，标题在封面 + 卡片中出现。
    expect(find.text(books.first.title), findsWidgets);
  });

  testWidgets('drift 数据源接入阅读器可正常阅读', (WidgetTester tester) async {
    final AppDatabase db = memDb();
    addTearDown(db.close);
    await BookDb.seedBuiltIns(db);
    final List<BookRow> rows = await db.listBooks();
    final BookRow target = rows.first; // 三国演义

    await tester.pumpWidget(
      app(BookReader(source: DbBookSource(db, target.id))),
    );
    await tester.pumpAndSettle();

    // 首章标题与页码可见，证明 DbBookSource 与阅读器协同正常。
    expect(find.text(books.first.chapters.first.title), findsWidgets);
    expect(find.textContaining('1/'), findsWidgets);
  });
}
