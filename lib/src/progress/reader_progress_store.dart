import 'package:flutter/foundation.dart';

/// 阅读位置：定位到某章及该章内的字符偏移。
@immutable
class ReadingPosition {
  const ReadingPosition({required this.chapterIndex, this.charOffset = 0});

  final int chapterIndex;
  final int charOffset;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'chapterIndex': chapterIndex,
    'charOffset': charOffset,
  };

  factory ReadingPosition.fromJson(Map<String, dynamic> json) =>
      ReadingPosition(
        chapterIndex: json['chapterIndex'] as int? ?? 0,
        charOffset: json['charOffset'] as int? ?? 0,
      );
}

/// 阅读进度存储抽象。
///
/// 阅读器通过它保存/恢复阅读位置。商用接入可实现基于
/// SharedPreferences、数据库或云端同步的版本；默认提供内存实现。
abstract class ReaderProgressStore {
  const ReaderProgressStore();

  Future<ReadingPosition?> load(Object bookId);

  Future<void> save(Object bookId, ReadingPosition position);
}

/// 不持久化：不保存也不恢复。
class NoopReaderProgressStore extends ReaderProgressStore {
  const NoopReaderProgressStore();

  @override
  Future<ReadingPosition?> load(Object bookId) async => null;

  @override
  Future<void> save(Object bookId, ReadingPosition position) async {}
}

/// 内存存储：进程内有效，用于演示或临时会话。
class InMemoryReaderProgressStore extends ReaderProgressStore {
  final Map<Object, ReadingPosition> _store = <Object, ReadingPosition>{};

  @override
  Future<ReadingPosition?> load(Object bookId) async => _store[bookId];

  @override
  Future<void> save(Object bookId, ReadingPosition position) async {
    _store[bookId] = position;
  }
}
