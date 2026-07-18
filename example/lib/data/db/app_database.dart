import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// 一本书的轻量信息（不含正文）。数据类命名为 [BookRow]，避免与 App 的 `Book` 冲突。
@DataClassName('BookRow')
class Books extends Table {
  IntColumn get id => integer()();
  TextColumn get title => text()();
  TextColumn get author => text().withDefault(const Constant(''))();
  TextColumn get intro => text().withDefault(const Constant(''))();

  /// 封面色（ARGB 整数）
  IntColumn get coverColor => integer()();
  IntColumn get chapterCount => integer().withDefault(const Constant(0))();

  /// 是否用户导入（区分内置书）
  BoolColumn get imported => boolean().withDefault(const Constant(false))();

  /// 排序权重：导入书用时间戳（越新越大），内置书用「-序号」（三国=0 最大）。
  IntColumn get sortAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

/// 章节：正文 [body] 按需单条读取，不随书籍列表加载。
@DataClassName('ChapterRow')
class Chapters extends Table {
  IntColumn get bookId => integer()();
  IntColumn get idx => integer()();
  TextColumn get title => text()();
  TextColumn get body => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{bookId, idx};
}

/// 待插入的章节行（导入 / 播种时用）。
class ChapterInput {
  const ChapterInput({
    required this.idx,
    required this.title,
    required this.body,
  });
  final int idx;
  final String title;
  final String body;
}

@DriftDatabase(tables: <Type>[Books, Chapters])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _open());

  /// 原生：应用文档目录下的 sqlite 文件；Web：WASM sqlite3 + worker（见 web/）。
  static QueryExecutor _open() => driftDatabase(
    name: 'readbook',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );

  @override
  int get schemaVersion => 1;

  /// 是否一本书都没有（用于首次播种判断）。
  Future<bool> get isEmpty async =>
      await (select(books)..limit(1)).getSingleOrNull() == null;

  /// 书架列表：只取书籍信息，不含任何正文。
  Future<List<BookRow>> listBooks() {
    return (select(books)..orderBy(<OrderClauseGenerator<$BooksTable>>[
          ($BooksTable t) => OrderingTerm.desc(t.imported),
          ($BooksTable t) => OrderingTerm.desc(t.sortAt),
        ]))
        .get();
  }

  Future<BookRow?> bookById(int id) => (select(
    books,
  )..where(($BooksTable t) => t.id.equals(id))).getSingleOrNull();

  /// 某本书的章节标题（目录用，不含正文）。
  Future<List<String>> chapterTitles(int bookId) async {
    final List<ChapterRow> rows =
        await (select(chapters)
              ..where(($ChaptersTable t) => t.bookId.equals(bookId))
              ..orderBy(<OrderClauseGenerator<$ChaptersTable>>[
                ($ChaptersTable t) => OrderingTerm.asc(t.idx),
              ]))
            .get();
    return rows.map((ChapterRow r) => r.title).toList();
  }

  /// 单章正文（阅读时按需读取）。
  Future<String?> chapterBody(int bookId, int idx) async {
    final ChapterRow? row =
        await (select(chapters)..where(
              ($ChaptersTable t) => t.bookId.equals(bookId) & t.idx.equals(idx),
            ))
            .getSingleOrNull();
    return row?.body;
  }

  /// 落库一本书（含全部章节）；已存在同 id 则整本覆盖。事务保证一致。
  Future<void> upsertBook({
    required int id,
    required String title,
    required String author,
    required String intro,
    required int coverColor,
    required bool imported,
    required int sortAt,
    required List<ChapterInput> chapterRows,
  }) async {
    await transaction(() async {
      await into(books).insertOnConflictUpdate(
        BooksCompanion.insert(
          id: Value<int>(id),
          title: title,
          author: Value<String>(author),
          intro: Value<String>(intro),
          coverColor: coverColor,
          chapterCount: Value<int>(chapterRows.length),
          imported: Value<bool>(imported),
          sortAt: Value<int>(sortAt),
        ),
      );
      await (delete(
        chapters,
      )..where(($ChaptersTable t) => t.bookId.equals(id))).go();
      await batch((Batch b) {
        for (final ChapterInput c in chapterRows) {
          b.insert(
            chapters,
            ChaptersCompanion.insert(
              bookId: id,
              idx: c.idx,
              title: c.title,
              body: c.body,
            ),
          );
        }
      });
    });
  }

  /// 删除一本书及其章节。
  Future<void> deleteBook(int id) async {
    await transaction(() async {
      await (delete(
        chapters,
      )..where(($ChaptersTable t) => t.bookId.equals(id))).go();
      await (delete(books)..where(($BooksTable t) => t.id.equals(id))).go();
    });
  }
}
