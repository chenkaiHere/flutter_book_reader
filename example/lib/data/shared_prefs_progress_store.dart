import 'dart:convert';

import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App 侧的阅读进度持久化：把每本书的阅读位置以 JSON 存入 SharedPreferences，
/// 并记录「最近阅读的书」，供书架的「继续阅读」卡片与在读统计使用。
///
/// 插件只依赖 [ReaderProgressStore] 抽象；此实现由业务方注入。
class SharedPrefsProgressStore extends ReaderProgressStore {
  SharedPrefsProgressStore({this.keyPrefix = 'reader_progress_'});

  final String keyPrefix;

  static const String _lastReadKey = 'reader_last_read_book_id';

  String _key(Object bookId) => '$keyPrefix$bookId';

  @override
  Future<ReadingPosition?> load(Object bookId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(bookId));
    if (raw == null || raw.isEmpty) return null;
    try {
      return ReadingPosition.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> save(Object bookId, ReadingPosition position) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(bookId), json.encode(position.toJson()));
    await prefs.setString(_lastReadKey, '$bookId');
  }

  /// 一次性读回所有给定书籍的进度（书架用），返回 bookId → 位置。
  Future<Map<int, ReadingPosition>> loadAll(Iterable<int> bookIds) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final Map<int, ReadingPosition> out = <int, ReadingPosition>{};
    for (final int id in bookIds) {
      final String? raw = prefs.getString(_key(id));
      if (raw == null || raw.isEmpty) continue;
      try {
        out[id] = ReadingPosition.fromJson(
          json.decode(raw) as Map<String, dynamic>,
        );
      } catch (_) {
        // 跳过损坏项
      }
    }
    return out;
  }

  /// 最近阅读的书 id；无则返回 null。
  Future<int?> lastReadBookId() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? v = prefs.getString(_lastReadKey);
    return v == null ? null : int.tryParse(v);
  }

  /// 主动标记「最近阅读」（例如从书架点开某本书时）。
  Future<void> markLastRead(Object bookId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastReadKey, '$bookId');
  }

  /// 删除某本书的进度（导入书被删除时清理）。
  Future<void> clear(Object bookId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key(bookId));
  }
}
