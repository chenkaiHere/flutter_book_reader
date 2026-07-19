import 'package:flutter/foundation.dart';

/// 一条划线：锚定到某章及章内 [start, end) 字符区间（与书签同一套「块长度空间」锚点，
/// 换字号后仍可精确还原）。[text] 为创建时的文字快照，[chapterTitle] / [createdAt]
/// 供笔记列表直接展示，无需再加载章节。
@immutable
class Underline {
  const Underline({
    required this.chapterIndex,
    required this.start,
    required this.end,
    required this.text,
    required this.chapterTitle,
    required this.createdAt,
  });

  final int chapterIndex;

  /// 章内起始字符偏移（含）。
  final int start;

  /// 章内结束字符偏移（不含）。
  final int end;

  /// 划线文字快照。
  final String text;

  /// 章节标题（创建时快照）。
  final String chapterTitle;

  /// 创建时间（Unix 毫秒）。
  final int createdAt;

  /// 去重键：同一区间只存一条。
  String get key => '$chapterIndex:$start:$end';

  /// 与另一区间在同章内是否有重叠。
  bool overlaps(int chapterIdx, int s, int e) =>
      chapterIdx == chapterIndex && s < end && e > start;

  Underline copyWith({int? start, int? end, String? text}) => Underline(
        chapterIndex: chapterIndex,
        start: start ?? this.start,
        end: end ?? this.end,
        text: text ?? this.text,
        chapterTitle: chapterTitle,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'chapterIndex': chapterIndex,
        'start': start,
        'end': end,
        'text': text,
        'chapterTitle': chapterTitle,
        'createdAt': createdAt,
      };

  factory Underline.fromJson(Map<String, dynamic> json) => Underline(
        chapterIndex: json['chapterIndex'] as int? ?? 0,
        start: json['start'] as int? ?? 0,
        end: json['end'] as int? ?? 0,
        text: json['text'] as String? ?? '',
        chapterTitle: json['chapterTitle'] as String? ?? '',
        createdAt: json['createdAt'] as int? ?? 0,
      );
}

/// 划线存储抽象。与 [ReaderBookmarkStore] 平行：阅读器只依赖此接口，业务方可实现基于
/// SharedPreferences / 数据库 / 云端的版本；默认提供内存实现。
abstract class ReaderUnderlineStore {
  const ReaderUnderlineStore();

  /// 读取某书的全部划线。
  Future<List<Underline>> load(Object bookId);

  /// 保存某书的全部划线（整表覆盖）。
  Future<void> save(Object bookId, List<Underline> underlines);
}

/// 不持久化：仅当前会话内有效，重启后清空。
class NoopReaderUnderlineStore extends ReaderUnderlineStore {
  const NoopReaderUnderlineStore();

  @override
  Future<List<Underline>> load(Object bookId) async => const <Underline>[];

  @override
  Future<void> save(Object bookId, List<Underline> underlines) async {}
}

/// 内存存储：进程内有效，用于演示或临时会话。
class InMemoryReaderUnderlineStore extends ReaderUnderlineStore {
  final Map<Object, List<Underline>> _store = <Object, List<Underline>>{};

  @override
  Future<List<Underline>> load(Object bookId) async =>
      List<Underline>.of(_store[bookId] ?? const <Underline>[]);

  @override
  Future<void> save(Object bookId, List<Underline> underlines) async {
    _store[bookId] = List<Underline>.of(underlines);
  }
}
