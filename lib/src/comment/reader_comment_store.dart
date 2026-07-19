import 'package:flutter/foundation.dart';

/// 一条评论 / 想法：锚定到某章及章内 [start, end) 字符区间（与书签 / 划线同一套
/// 「块长度空间」锚点，换字号后仍可精确还原）。[quote] 为被评论的原文快照，[text]
/// 为用户写下的想法；[chapterTitle] / [createdAt] 供笔记列表直接展示。
@immutable
class Comment {
  const Comment({
    required this.chapterIndex,
    required this.start,
    required this.end,
    required this.quote,
    required this.text,
    required this.chapterTitle,
    required this.createdAt,
  });

  final int chapterIndex;

  /// 章内起始字符偏移（含）。
  final int start;

  /// 章内结束字符偏移（不含）。
  final int end;

  /// 被评论的原文快照。
  final String quote;

  /// 用户写下的评论 / 想法正文。
  final String text;

  /// 章节标题（创建时快照）。
  final String chapterTitle;

  /// 创建时间（Unix 毫秒）。
  final int createdAt;

  /// 去重键：同一区间 + 同一时间只存一条（同段可有多条评论，故带上时间）。
  String get key => '$chapterIndex:$start:$end:$createdAt';

  Comment copyWith({String? quote, String? text}) => Comment(
        chapterIndex: chapterIndex,
        start: start,
        end: end,
        quote: quote ?? this.quote,
        text: text ?? this.text,
        chapterTitle: chapterTitle,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'chapterIndex': chapterIndex,
        'start': start,
        'end': end,
        'quote': quote,
        'text': text,
        'chapterTitle': chapterTitle,
        'createdAt': createdAt,
      };

  factory Comment.fromJson(Map<String, dynamic> json) => Comment(
        chapterIndex: json['chapterIndex'] as int? ?? 0,
        start: json['start'] as int? ?? 0,
        end: json['end'] as int? ?? 0,
        quote: json['quote'] as String? ?? '',
        text: json['text'] as String? ?? '',
        chapterTitle: json['chapterTitle'] as String? ?? '',
        createdAt: json['createdAt'] as int? ?? 0,
      );
}

/// 评论存储抽象。与 [ReaderBookmarkStore] / [ReaderUnderlineStore] 平行：阅读器只
/// 依赖此接口，业务方可实现基于 SharedPreferences / 数据库 / 云端的版本；默认内存实现。
abstract class ReaderCommentStore {
  const ReaderCommentStore();

  /// 读取某书的全部评论。
  Future<List<Comment>> load(Object bookId);

  /// 保存某书的全部评论（整表覆盖）。
  Future<void> save(Object bookId, List<Comment> comments);
}

/// 不持久化：仅当前会话内有效，重启后清空。
class NoopReaderCommentStore extends ReaderCommentStore {
  const NoopReaderCommentStore();

  @override
  Future<List<Comment>> load(Object bookId) async => const <Comment>[];

  @override
  Future<void> save(Object bookId, List<Comment> comments) async {}
}

/// 内存存储：进程内有效，用于演示或临时会话。
class InMemoryReaderCommentStore extends ReaderCommentStore {
  final Map<Object, List<Comment>> _store = <Object, List<Comment>>{};

  @override
  Future<List<Comment>> load(Object bookId) async =>
      List<Comment>.of(_store[bookId] ?? const <Comment>[]);

  @override
  Future<void> save(Object bookId, List<Comment> comments) async {
    _store[bookId] = List<Comment>.of(comments);
  }
}
