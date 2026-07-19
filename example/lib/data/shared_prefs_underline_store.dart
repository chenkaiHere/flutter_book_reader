import 'dart:convert';

import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App 侧划线持久化：把每本书的划线列表以 JSON 存入 SharedPreferences，按 bookId 归类。
/// 与 [SharedPrefsBookmarkStore] 平行；插件只依赖 [ReaderUnderlineStore] 抽象。
class SharedPrefsUnderlineStore extends ReaderUnderlineStore {
  SharedPrefsUnderlineStore({this.keyPrefix = 'reader_underlines_'});

  final String keyPrefix;

  String _key(Object bookId) => '$keyPrefix$bookId';

  @override
  Future<List<Underline>> load(Object bookId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(bookId));
    if (raw == null || raw.isEmpty) return const <Underline>[];
    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => Underline.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <Underline>[];
    }
  }

  @override
  Future<void> save(Object bookId, List<Underline> underlines) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = json.encode(
      underlines.map((Underline u) => u.toJson()).toList(),
    );
    await prefs.setString(_key(bookId), raw);
  }
}
