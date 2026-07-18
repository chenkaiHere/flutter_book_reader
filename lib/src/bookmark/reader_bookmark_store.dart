import 'package:flutter/foundation.dart';

/// 一条书签：锚定到某章及章内字符偏移（与阅读进度同一套锚点，换字号后仍可精确还原）。
///
/// [charOffset] 取加书签时当前页的起始偏移；[chapterTitle] 与 [createdAt] 为展示用快照。
@immutable
class Bookmark {
  const Bookmark({
    required this.chapterIndex,
    required this.charOffset,
    required this.chapterTitle,
    required this.createdAt,
  });

  final int chapterIndex;
  final int charOffset;

  /// 章节标题（创建时快照，列表直接展示，无需再加载章节）
  final String chapterTitle;

  /// 创建时间（Unix 毫秒）
  final int createdAt;

  /// 去重键：同一位置只存一条，实现"再次点击即取消"。
  String get key => '$chapterIndex:$charOffset';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'chapterIndex': chapterIndex,
        'charOffset': charOffset,
        'chapterTitle': chapterTitle,
        'createdAt': createdAt,
      };

  factory Bookmark.fromJson(Map<String, dynamic> json) => Bookmark(
        chapterIndex: json['chapterIndex'] as int? ?? 0,
        charOffset: json['charOffset'] as int? ?? 0,
        chapterTitle: json['chapterTitle'] as String? ?? '',
        createdAt: json['createdAt'] as int? ?? 0,
      );
}

/// 书签存储抽象。与 [ReaderProgressStore] 平行：阅读器只依赖此接口，
/// 业务方可实现基于 SharedPreferences / 数据库 / 云端的版本；默认提供内存实现。
abstract class ReaderBookmarkStore {
  const ReaderBookmarkStore();

  /// 读取某书的全部书签。
  Future<List<Bookmark>> load(Object bookId);

  /// 保存某书的全部书签（整表覆盖，简单可靠）。
  Future<void> save(Object bookId, List<Bookmark> bookmarks);
}

/// 不持久化：仅当前会话内（由阅读器内部状态维持），重启后清空。
class NoopReaderBookmarkStore extends ReaderBookmarkStore {
  const NoopReaderBookmarkStore();

  @override
  Future<List<Bookmark>> load(Object bookId) async => const <Bookmark>[];

  @override
  Future<void> save(Object bookId, List<Bookmark> bookmarks) async {}
}

/// 内存存储：进程内有效，用于演示或临时会话。
class InMemoryReaderBookmarkStore extends ReaderBookmarkStore {
  final Map<Object, List<Bookmark>> _store = <Object, List<Bookmark>>{};

  @override
  Future<List<Bookmark>> load(Object bookId) async =>
      List<Bookmark>.of(_store[bookId] ?? const <Bookmark>[]);

  @override
  Future<void> save(Object bookId, List<Bookmark> bookmarks) async {
    _store[bookId] = List<Bookmark>.of(bookmarks);
  }
}
