import 'dart:convert';

import 'package:flutter_book_reader/flutter_book_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App 侧评论持久化：把每本书的评论列表以 JSON 存入 SharedPreferences，按 bookId 归类。
/// 与 [SharedPrefsUnderlineStore] 平行；插件只依赖 [ReaderCommentStore] 抽象。
class SharedPrefsCommentStore extends ReaderCommentStore {
  SharedPrefsCommentStore({this.keyPrefix = 'reader_comments_'});

  final String keyPrefix;

  String _key(Object bookId) => '$keyPrefix$bookId';

  @override
  Future<List<Comment>> load(Object bookId) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? raw = prefs.getString(_key(bookId));
    if (raw == null || raw.isEmpty) return const <Comment>[];
    try {
      final List<dynamic> list = json.decode(raw) as List<dynamic>;
      return list
          .map((dynamic e) => Comment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const <Comment>[];
    }
  }

  @override
  Future<void> save(Object bookId, List<Comment> comments) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String raw = json.encode(
      comments.map((Comment c) => c.toJson()).toList(),
    );
    await prefs.setString(_key(bookId), raw);
  }
}
