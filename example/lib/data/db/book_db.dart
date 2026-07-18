import '../book.dart';
import 'app_database.dart';

/// drift 数据层的 App 侧操作：首次播种内置书、导入书落库。
///
/// 正文以「按章一行」存入 [Chapters] 表，段首保留全角缩进，与旧 `Chapter.body`
/// 完全一致，保证阅读渲染不变。
class BookDb {
  const BookDb._();

  /// 首次启动把内置书（books.json + sanguo.json）播种进库；已有数据则跳过。
  static Future<void> seedBuiltIns(AppDatabase db) async {
    if (!await db.isEmpty) return;
    final List<Book> books = await BookRepository.load();
    for (int i = 0; i < books.length; i++) {
      final Book b = books[i];
      await db.upsertBook(
        id: b.id,
        title: b.title,
        author: b.author,
        intro: b.intro,
        coverColor: b.coverColor.toARGB32(),
        imported: false,
        // 三国（i=0）排最前：内置书用「-序号」，导入书用正的时间戳，故导入书恒在前。
        sortAt: -i,
        chapterRows: <ChapterInput>[
          for (final Chapter c in b.chapters)
            ChapterInput(idx: c.index, title: c.title, body: c.body),
        ],
      );
    }
  }

  /// 把解析好的书籍 JSON（[TxtBookParser] 输出）落库，返回 bookId。
  /// [nowMs] 传入当前毫秒时间戳作为排序权重（新导入的书排在最前）。
  static Future<int> importParsed(
    AppDatabase db,
    Map<String, dynamic> json, {
    required int nowMs,
  }) async {
    final int id = json['id'] as int;
    final List<dynamic> chapters = json['chapters'] as List<dynamic>;
    await db.upsertBook(
      id: id,
      title: json['title'] as String,
      author: json['author'] as String? ?? '',
      intro: json['intro'] as String? ?? '',
      coverColor: _argb(json['coverColor'] as String?),
      imported: true,
      sortAt: nowMs,
      chapterRows: <ChapterInput>[
        for (final dynamic e in chapters)
          ChapterInput(
            idx: (e as Map<String, dynamic>)['index'] as int,
            title: e['title'] as String,
            body: (e['paragraphs'] as List<dynamic>)
                .cast<String>()
                .map((String p) => '　　$p')
                .join('\n'),
          ),
      ],
    );
    return id;
  }

  /// "5B7B9A" 十六进制 → 不透明 ARGB 整数。
  static int _argb(String? hex) {
    final int rgb = int.tryParse(hex ?? '', radix: 16) ?? 0x5B7B9A;
    return 0xFF000000 | rgb;
  }
}
