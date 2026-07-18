import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../data/book.dart';
import 'txt_parser.dart';

/// 导入书籍的落库管理（App 侧）：解析后的书籍 JSON 存到应用内部存储，便于后续阅读。
///
/// 目录：`<应用文档目录>/imported_books/<bookId>.json`，一书一文件；重复导入同一
/// 文件（同名同长度）得到相同 id，会覆盖旧文件。持久化完全在 App 侧，插件不参与。
class ImportedBookStore {
  ImportedBookStore({Directory? baseDir}) : _baseDir = baseDir;

  static const String _dirName = 'imported_books';

  /// 测试可注入的根目录；为空时用 path_provider 的应用文档目录。
  final Directory? _baseDir;

  Future<Directory> _dir() async {
    final Directory base = _baseDir ?? await getApplicationDocumentsDirectory();
    final Directory dir = Directory('${base.path}/$_dirName');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  /// 导入一个本地 txt：后台解析 → 写入 JSON → 返回解析出的 [Book]。
  Future<Book> importTxt(String txtPath) async {
    final Map<String, dynamic> json = await TxtBookParser.parseFile(txtPath);
    return _persist(json);
  }

  /// 直接导入一段文本（如从 asset 读取的示例），便于无文件选择器时演示。
  Future<Book> importText(String text, {String fileName = ''}) async {
    final Map<String, dynamic> json = TxtBookParser.parseText(
      text,
      fileName: fileName,
    );
    return _persist(json);
  }

  /// 导入一段 txt 字节（文件选择器在 Web 上只提供 bytes 时用）。
  Future<Book> importBytes(Uint8List bytes, {String fileName = ''}) async {
    final Map<String, dynamic> json = await TxtBookParser.parseBytes(
      bytes,
      fileName: fileName,
    );
    return _persist(json);
  }

  Future<Book> _persist(Map<String, dynamic> json) async {
    final Directory dir = await _dir();
    final Object id = json['id'] as Object;
    File('${dir.path}/$id.json').writeAsStringSync(jsonEncode(json));
    return Book.fromJson(json);
  }

  /// 列出所有已导入书籍（读目录下全部 JSON）。
  Future<List<Book>> listImported() async {
    final Directory dir = await _dir();
    final List<Book> books = <Book>[];
    for (final FileSystemEntity e in dir.listSync()) {
      if (e is File && e.path.endsWith('.json')) {
        try {
          books.add(
            Book.fromJson(
              jsonDecode(e.readAsStringSync()) as Map<String, dynamic>,
            ),
          );
        } catch (_) {
          // 跳过损坏文件
        }
      }
    }
    return books;
  }

  /// 读取某本已导入书籍；不存在返回 null。
  Future<Book?> loadImported(int id) async {
    final Directory dir = await _dir();
    final File f = File('${dir.path}/$id.json');
    if (!f.existsSync()) return null;
    return Book.fromJson(
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>,
    );
  }

  /// 删除某本已导入书籍。
  Future<void> deleteImported(int id) async {
    final Directory dir = await _dir();
    final File f = File('${dir.path}/$id.json');
    if (f.existsSync()) f.deleteSync();
  }
}
