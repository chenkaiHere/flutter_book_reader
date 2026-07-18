import 'dart:convert';

import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 使用方（App 侧）自行实现的书签持久化：把每本书的书签列表以 JSON 存入
/// SharedPreferences，按 bookId 归类。插件本身不含任何持久化实现，
/// 只依赖 [ReaderBookmarkStore] 抽象，业务方注入自己的实现即可。
class SharedPrefsBookmarkStore extends ReaderBookmarkStore {
  SharedPrefsBookmarkStore({this.keyPrefix = 'reader_bookmarks_'});

  /// 存储键前缀，避免与其它偏好项冲突。
  final String keyPrefix;

  String _key(Object bookId) => '$keyPrefix$bookId';

  @override
  Future<List<Bookmark>> load(Object bookId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(bookId));
    if (raw == null || raw.isEmpty) return const <Bookmark>[];
    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => Bookmark.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // 数据损坏时降级为空，避免影响阅读
      return const <Bookmark>[];
    }
  }

  @override
  Future<void> save(Object bookId, List<Bookmark> bookmarks) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = json.encode(
      bookmarks.map((Bookmark b) => b.toJson()).toList(),
    );
    await prefs.setString(_key(bookId), raw);
  }
}
