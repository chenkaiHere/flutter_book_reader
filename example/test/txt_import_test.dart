import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:enough_convert/big5.dart';
import 'package:enough_convert/gbk.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:flutter_book_reader_example/data/db/app_database.dart';
import 'package:flutter_book_reader_example/data/db/book_db.dart';
import 'package:flutter_book_reader_example/data/db/db_book_source.dart';
import 'package:flutter_book_reader_example/import/txt_parser.dart';
import 'package:flutter_test/flutter_test.dart';

const String _sample = '''
《山海孤旅》 作者：云中鹤

内容简介
少年离乡，跨越山海。
这是第二行简介。

第一章　启程
　　海风从礁石间穿过，带着咸涩的气息。
少年抬起头，望向天边那一线光。

第二章 故人
灯笼在风里摇晃，昏黄的光晕忽明忽暗。

第三章 归途
段落一上半，
下半接上一段。

这是第二段。
''';

void main() {
  // 自动编码检测：同一份中文文本用不同编码写成字节，parseBytes 都应正确解码。
  group('TxtBookParser 编码自动检测（parseBytes）', () {
    const String cn = '《测试书》 作者：无名\n\n第一章 开端\n　　滚滚长江东逝水，浪花淘尽英雄。\n你好，世界！';
    const String tw = // 繁体样本，用于验证 Big5 分支
        '《測試書》 作者：無名\n\n第一章 開端\n　　這是繁體中文，關於編碼偵測。\n「你好」，世界！';

    test('UTF-8（无 BOM）', () async {
      final json = await TxtBookParser.parseBytes(
        Uint8List.fromList(utf8.encode(cn)),
      );
      expect(json['title'], '测试书');
      expect(
        (json['chapters'][0] as Map)['paragraphs'].first,
        '滚滚长江东逝水，浪花淘尽英雄。',
      );
    });

    test('UTF-8 BOM', () async {
      final json = await TxtBookParser.parseBytes(
        Uint8List.fromList(<int>[0xEF, 0xBB, 0xBF, ...utf8.encode(cn)]),
      );
      expect(json['title'], '测试书');
    });

    test('UTF-16 LE BOM', () async {
      final List<int> bytes = <int>[0xFF, 0xFE];
      for (final int u in cn.codeUnits) {
        bytes
          ..add(u & 0xFF)
          ..add((u >> 8) & 0xFF);
      }
      final json = await TxtBookParser.parseBytes(Uint8List.fromList(bytes));
      expect(json['title'], '测试书');
    });

    test('GBK（简体，无 BOM）', () async {
      final json = await TxtBookParser.parseBytes(
        Uint8List.fromList(const GbkCodec().encode(cn)),
      );
      expect(json['title'], '测试书');
      expect(
        (json['chapters'][0] as Map)['paragraphs'].first,
        '滚滚长江东逝水，浪花淘尽英雄。',
      );
    });

    test('Big5（繁体，无 BOM）', () async {
      final json = await TxtBookParser.parseBytes(
        Uint8List.fromList(const Big5Codec().encode(tw)),
      );
      expect(json['title'], '測試書');
      expect(
        (json['chapters'][0] as Map)['paragraphs'].first,
        '這是繁體中文，關於編碼偵測。',
      );
    });
  });

  group('TxtBookParser.parseText', () {
    final Map<String, dynamic> json = TxtBookParser.parseText(_sample);

    test('识别书名 / 作者 / 简介', () {
      expect(json['title'], '山海孤旅');
      expect(json['author'], '云中鹤');
      expect(json['intro'], '少年离乡，跨越山海。\n这是第二行简介。');
    });

    test('切分出全部章节及标题', () {
      final List<dynamic> chapters = json['chapters'] as List<dynamic>;
      expect(chapters.length, 3);
      expect((chapters[0] as Map<String, dynamic>)['title'], '第一章　启程');
      expect((chapters[1] as Map<String, dynamic>)['title'], '第二章 故人');
      expect((chapters[2] as Map<String, dynamic>)['title'], '第三章 归途');
    });

    test('章内一行一段（无内部空行）', () {
      final List<dynamic> p0 =
          (json['chapters'][0] as Map<String, dynamic>)['paragraphs']
              as List<dynamic>;
      expect(p0.length, 2);
      expect(p0.first, '海风从礁石间穿过，带着咸涩的气息。'); // 行首全角空格已去
      expect(p0[1], '少年抬起头，望向天边那一线光。');
    });

    test('章内空行分隔 + 硬换行合并为一段', () {
      final List<dynamic> p2 =
          (json['chapters'][2] as Map<String, dynamic>)['paragraphs']
              as List<dynamic>;
      expect(p2.length, 2);
      expect(p2.first, '段落一上半，下半接上一段。'); // 两行硬换行合并
      expect(p2[1], '这是第二段。');
    });

    test('coverColor 为 6 位十六进制；id 稳定可复现', () {
      expect(json['coverColor'], matches(RegExp(r'^[0-9A-Fa-f]{6}$')));
      final Map<String, dynamic> again = TxtBookParser.parseText(_sample);
      expect(again['id'], json['id']);
    });

    test('无章节标记时按字数切成合成章节', () {
      final String plain = List<String>.generate(
        50,
        (int i) => '这是第 $i 段的内容。' * 20,
      ).join('\n');
      final Map<String, dynamic> r = TxtBookParser.parseText(
        plain,
        fileName: '散文.txt',
      );
      expect(r['title'], '散文');
      expect((r['chapters'] as List<dynamic>).length, greaterThan(1));
    });
  });

  test('导入落库到 drift，列表只读信息、正文按章读回', () async {
    final AppDatabase db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final Map<String, dynamic> json = TxtBookParser.parseText(
      _sample,
      fileName: '山海孤旅.txt',
    );
    final int id = await BookDb.importParsed(db, json, nowMs: 1000);

    // 列表：只含书籍信息（标题/作者/章节数/来源），不含正文。
    final List<BookRow> rows = await db.listBooks();
    expect(rows.length, 1);
    expect(rows.first.title, '山海孤旅');
    expect(rows.first.chapterCount, 3);
    expect(rows.first.imported, isTrue);

    // 目录：只取章节标题。
    final List<String> titles = await db.chapterTitles(id);
    expect(titles.length, 3);

    // 数据源：按章懒读正文。
    final DbBookSource src = DbBookSource(db, id);
    final BookManifest m = await src.loadManifest();
    expect(m.title, '山海孤旅');
    expect(m.chapterTitles.length, 3);
    final String body0 = await src.loadChapterBody(0);
    expect(body0.contains('海风从礁石间穿过'), isTrue);

    // 删除：书与章节一并移除。
    await db.deleteBook(id);
    expect((await db.listBooks()).isEmpty, isTrue);
    expect(await db.chapterBody(id, 0), isNull);
  });
}
