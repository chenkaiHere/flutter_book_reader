import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

/// 单个章节
class Chapter {
  Chapter({
    required this.id,
    required this.index,
    required this.title,
    required this.paragraphs,
  });

  final int id;

  /// 在书中的序号，从 0 开始
  final int index;
  final String title;

  /// 段落列表（未经排版，纯文本）
  final List<String> paragraphs;

  /// 用于排版的整章正文：段落之间用换行分隔，段首缩进两个全角空格
  String get body => paragraphs.map((String p) => '　　$p').join('\n');

  factory Chapter.fromJson(Map<String, dynamic> json) => Chapter(
        id: json['id'] as int,
        index: json['index'] as int,
        title: json['title'] as String,
        paragraphs: (json['paragraphs'] as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList(),
      );
}

/// 一本书
class Book {
  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.intro,
    required this.coverColor,
    required this.chapters,
  });

  final int id;
  final String title;
  final String author;
  final String intro;

  /// 封面主色
  final Color coverColor;
  final List<Chapter> chapters;

  int get chapterCount => chapters.length;

  factory Book.fromJson(Map<String, dynamic> json) => Book(
        id: json['id'] as int,
        title: json['title'] as String,
        author: json['author'] as String,
        intro: json['intro'] as String,
        coverColor: _parseColor(json['coverColor'] as String?),
        chapters: (json['chapters'] as List<dynamic>)
            .map((dynamic e) => Chapter.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// 解析 "5B7B9A" 这样的 RGB 十六进制字符串为不透明 Color
  static Color _parseColor(String? hex) {
    if (hex == null || hex.isEmpty) return const Color(0xFF5B7B9A);
    final int rgb = int.tryParse(hex, radix: 16) ?? 0x5B7B9A;
    return Color(0xFF000000 | rgb);
  }
}

/// 书籍仓库：从 assets/books.json 异步加载并缓存书籍数据。
///
/// 书籍内容不再硬编码在代码里，而是外置为 JSON 资源，运行时读取解析。
/// 需要调整内容时重新运行 `dart run tool/gen_books.dart` 生成 JSON 即可。
class BookRepository {
  BookRepository._();

  static const String assetPath = 'assets/books.json';

  static List<Book>? _cache;

  /// 已加载的书籍（未加载时为空列表）。加载请用 [load]。
  static List<Book> get books => _cache ?? const <Book>[];

  /// 从 JSON 资源加载书籍（带缓存，重复调用直接返回缓存）。
  static Future<List<Book>> load() async {
    if (_cache != null) return _cache!;
    final String raw = await rootBundle.loadString(assetPath);
    _cache = parse(raw);
    return _cache!;
  }

  /// 解析 JSON 字符串为书籍列表（纯函数，便于测试）。
  static List<Book> parse(String raw) {
    final Map<String, dynamic> data = json.decode(raw) as Map<String, dynamic>;
    return (data['books'] as List<dynamic>)
        .map((dynamic e) => Book.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Book bookById(int id) =>
      books.firstWhere((Book b) => b.id == id, orElse: () => books.first);
}
