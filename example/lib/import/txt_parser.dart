import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:enough_convert/big5.dart';
import 'package:enough_convert/gbk.dart';

/// 本地 txt 小说解析工具（App 侧）。
///
/// 在后台 isolate 中把一个 txt 文件解析成「书籍 JSON」（结构与 books.json 中单本一致：
/// id / title / author / intro / coverColor / chapters[{id,index,title,paragraphs}]），
/// 便于随后落库（见 ImportedBookStore）与阅读。解析尽量识别：书名、作者、简介、
/// 章节标题、章节正文与分段。
///
/// 编码：自动检测常见小说编码——UTF-8 / UTF-8-BOM / UTF-16(LE/BE) /
/// GBK(含 GB2312) / Big5，不假设固定编码（见 [_decode]）。
class TxtBookParser {
  const TxtBookParser._();

  /// 后台解析一个 txt 文件，返回书籍 JSON（不写盘）。
  static Future<Map<String, dynamic>> parseFile(String path) =>
      Isolate.run(() => _parseFileSync(path));

  /// 后台解析一段 txt 字节（如文件选择器在 Web 上只给 bytes 时用）。
  static Future<Map<String, dynamic>> parseBytes(
    Uint8List bytes, {
    String fileName = '',
  }) => Isolate.run(() => parseText(_decode(bytes), fileName: fileName));

  static Map<String, dynamic> _parseFileSync(String path) {
    final Uint8List bytes = File(path).readAsBytesSync();
    final String name = path.split(Platform.pathSeparator).last;
    return parseText(_decode(bytes), fileName: name);
  }

  // ————————————————————— 解码 —————————————————————

  /// 自动检测编码并解码。顺序：BOM → 严格 UTF-8 → 传统中文编码（GBK / Big5）打分择优。
  static String _decode(Uint8List b) {
    // 1) BOM：最可靠的判据。
    if (b.length >= 3 && b[0] == 0xEF && b[1] == 0xBB && b[2] == 0xBF) {
      return utf8.decode(b.sublist(3), allowMalformed: true); // UTF-8 BOM
    }
    if (b.length >= 2 && b[0] == 0xFF && b[1] == 0xFE) {
      return _decodeUtf16(b.sublist(2), endian: Endian.little); // UTF-16 LE
    }
    if (b.length >= 2 && b[0] == 0xFE && b[1] == 0xFF) {
      return _decodeUtf16(b.sublist(2), endian: Endian.big); // UTF-16 BE
    }

    // 2) 无 BOM：严格 UTF-8 能通过即判为 UTF-8。真实中文 GBK/Big5 字节极难
    //    恰好构成合法 UTF-8，故「严格解码成功」是可靠的 UTF-8 信号。
    try {
      return utf8.decode(b); // 严格模式：遇非法字节抛异常
    } catch (_) {
      // 3) 传统中文编码：分别按 GBK 与 Big5 容错解码，按「像中文正文」的程度
      //    打分（汉字/中文标点多、替换符少者胜），取高分者。GBK 覆盖简体（含
      //    GB2312），Big5 覆盖繁体，涵盖绝大多数中文 txt。
      final String gbk = const GbkCodec(allowInvalid: true).decode(b);
      final String big5 = const Big5Codec(allowInvalid: true).decode(b);
      return _cjkScore(gbk) >= _cjkScore(big5) ? gbk : big5;
    }
  }

  /// 「像中文正文」的打分：汉字与中文标点计正分，解码失败的替换符(�)计负分，
  /// 归一化到 [-2, 1]。用于在 GBK / Big5 之间择优。
  static double _cjkScore(String s) {
    int total = 0;
    int good = 0;
    int bad = 0;
    for (final int c in s.runes) {
      total++;
      if ((c >= 0x4E00 && c <= 0x9FFF) || // CJK 统一汉字
          (c >= 0x3000 && c <= 0x303F) || // CJK 标点符号
          (c >= 0xFF00 && c <= 0xFFEF)) {
        // 全角 ASCII/标点
        good++;
      } else if (c == 0xFFFD) {
        bad++; // 解码失败的替换符
      }
    }
    return total == 0 ? 0 : (good - bad * 2) / total;
  }

  static String _decodeUtf16(Uint8List b, {required Endian endian}) {
    final ByteData d = ByteData.sublistView(b);
    final StringBuffer sb = StringBuffer();
    for (int i = 0; i + 1 < b.length; i += 2) {
      sb.writeCharCode(d.getUint16(i, endian));
    }
    return sb.toString();
  }

  // ————————————————————— 结构化 —————————————————————

  static final RegExp _leadIndent = RegExp(r'^[　\s]+');

  /// 章节标题正则：第X章/回/节/卷/集/部/篇（含大写数字），及序章/楔子/番外/Chapter N 等。
  static final RegExp _heading = RegExp(
    r'^\s*('
    r'第[0-9零〇一二三四五六七八九十百千两]{1,8}[章回节卷集部篇]'
    r'|序[章言]?|楔\s*子|引\s*子|前\s*言|后\s*记|尾\s*声|番\s*外.{0,20}'
    r'|Chapter\s+\d+.*'
    r')\s*(.*)$',
    caseSensitive: false,
  );

  /// 每章大致目标字数（无章节标记时按此切分成合成章节）。
  static const int _syntheticChapterChars = 3000;

  /// 解析纯文本为书籍 JSON（也可直接用于从 asset 读取的示例文本）。[fileName] 兜底书名。
  static Map<String, dynamic> parseText(String text, {String fileName = ''}) {
    final List<String> lines = text.replaceAll('\r\n', '\n').split('\n');

    // 1) 找到首个章节标题所在行；之前为「书籍信息区」。
    int firstHeading = -1;
    for (int i = 0; i < lines.length; i++) {
      if (_isHeading(lines[i])) {
        firstHeading = i;
        break;
      }
    }

    final List<String> headerLines = lines.sublist(
      0,
      firstHeading < 0 ? lines.length : firstHeading,
    );

    // 2) 书名 / 作者 / 简介。
    final String fallbackTitle = fileName
        .replaceAll(RegExp(r'\.txt$', caseSensitive: false), '')
        .trim();
    final _Meta meta = _extractMeta(headerLines, fallbackTitle);

    // 3) 章节。
    final List<_Chapter> chapters = firstHeading < 0
        ? _splitBySize(lines) // 无章节标记：按字数切成合成章节
        : _splitByHeading(lines, firstHeading);

    final String title = meta.title.isNotEmpty
        ? meta.title
        : (fallbackTitle.isNotEmpty ? fallbackTitle : '未命名');

    return <String, dynamic>{
      'id': _stableId(title, text.length),
      'title': title,
      'author': meta.author,
      'intro': meta.intro,
      'coverColor': _coverColor(title),
      'chapters': <Map<String, dynamic>>[
        for (int i = 0; i < chapters.length; i++)
          <String, dynamic>{
            'id': _stableId(title, text.length) * 1000 + i,
            'index': i,
            'title': chapters[i].title,
            'paragraphs': chapters[i].paragraphs,
          },
      ],
    };
  }

  static bool _isHeading(String line) {
    final String t = line.trim();
    if (t.isEmpty || t.length > 40) return false; // 标题一般较短，避免误判长段落
    return _heading.hasMatch(t);
  }

  static _Meta _extractMeta(List<String> header, String fallbackTitle) {
    String title = '';
    String author = '';
    String intro = '';

    final List<String> nonEmpty = header
        .map((String l) => l.trim())
        .where((String l) => l.isNotEmpty)
        .toList();

    for (int i = 0; i < nonEmpty.length && i < 30; i++) {
      final String l = nonEmpty[i];
      // 《书名》作者 / 《书名》
      final RegExpMatch? m = RegExp(r'《(.+?)》\s*(.*)').firstMatch(l);
      if (m != null) {
        if (title.isEmpty) title = m.group(1)!.trim();
        final String rest = (m.group(2) ?? '')
            .replaceFirst(RegExp(r'^作者[:：]?\s*'), '')
            .trim();
        if (author.isEmpty && rest.isNotEmpty) author = rest;
        continue;
      }
      final RegExpMatch? tm = RegExp(r'^书名[:：]\s*(.+)').firstMatch(l);
      if (tm != null && title.isEmpty) title = tm.group(1)!.trim();
      final RegExpMatch? am = RegExp(r'^作者[:：]\s*(.+)').firstMatch(l);
      if (am != null && author.isEmpty) author = am.group(1)!.trim();
    }

    // 简介：出现在「简介 / 内容简介 / 内容介绍」标题之后，直到空行或书籍信息区结束。
    for (int i = 0; i < header.length; i++) {
      if (RegExp(r'^\s*(内容)?(简介|简\s*介|内容介绍)\s*[:：]?\s*$').hasMatch(header[i])) {
        final StringBuffer sb = StringBuffer();
        for (int j = i + 1; j < header.length; j++) {
          final String t = header[j].trim();
          if (t.isEmpty) {
            if (sb.isNotEmpty) break;
            continue;
          }
          if (sb.isNotEmpty) sb.write('\n');
          sb.write(t);
          if (sb.length > 400) break;
        }
        intro = sb.toString();
        break;
      }
    }

    return _Meta(
      title: title.isEmpty ? fallbackTitle : title,
      author: author,
      intro: intro,
    );
  }

  static List<_Chapter> _splitByHeading(List<String> lines, int firstHeading) {
    final List<_Chapter> result = <_Chapter>[];
    String? curTitle;
    List<String> buf = <String>[];
    void flush() {
      final String? t = curTitle;
      if (t != null) {
        result.add(_Chapter(t, _paragraphs(buf)));
      }
      buf = <String>[];
    }

    for (int i = firstHeading; i < lines.length; i++) {
      if (_isHeading(lines[i])) {
        flush();
        curTitle = lines[i].trim();
      } else {
        buf.add(lines[i]);
      }
    }
    flush();
    return result;
  }

  /// 无章节标记：把全文（去空行后）按目标字数切成「第 N 章」。
  static List<_Chapter> _splitBySize(List<String> lines) {
    final List<String> paras = _paragraphs(lines);
    if (paras.isEmpty) return <_Chapter>[_Chapter('正文', <String>[])];
    final List<_Chapter> result = <_Chapter>[];
    List<String> buf = <String>[];
    int count = 0;
    for (final String p in paras) {
      buf.add(p);
      count += p.length;
      if (count >= _syntheticChapterChars) {
        result.add(_Chapter('第 ${result.length + 1} 章', buf));
        buf = <String>[];
        count = 0;
      }
    }
    if (buf.isNotEmpty) result.add(_Chapter('第 ${result.length + 1} 章', buf));
    return result;
  }

  /// 把若干原始行整理成段落：
  /// - 若「内部」存在空行分隔：按空行切块，块内多行（硬换行）合并为一段；
  /// - 若内部无空行：每个非空行即一段。
  ///
  /// 先去掉首尾空行，避免章节结尾的一个空行误判为「空行分隔」格式。
  static List<String> _paragraphs(List<String> raw) {
    int s = 0;
    int e = raw.length;
    while (s < e && raw[s].trim().isEmpty) {
      s++;
    }
    while (e > s && raw[e - 1].trim().isEmpty) {
      e--;
    }
    final List<String> lines = raw.sublist(s, e);
    if (lines.isEmpty) return <String>[];

    final bool hasBlank = lines.any((String l) => l.trim().isEmpty);
    final List<String> out = <String>[];
    if (hasBlank) {
      final StringBuffer sb = StringBuffer();
      void flush() {
        final String p = _clean(sb.toString());
        if (p.isNotEmpty) out.add(p);
        sb.clear();
      }

      for (final String l in lines) {
        if (l.trim().isEmpty) {
          flush();
        } else {
          sb.write(l.trim());
        }
      }
      flush();
    } else {
      for (final String l in lines) {
        final String p = _clean(l);
        if (p.isNotEmpty) out.add(p);
      }
    }
    return out;
  }

  static String _clean(String s) => s.replaceFirst(_leadIndent, '').trimRight();

  // ————————————————————— 杂项 —————————————————————

  static const List<String> _palette = <String>[
    '5B7B9A',
    '8A5B6B',
    '5B8A6B',
    '3F5B78',
    '6B7E8A',
    '8B6B3A',
    '6B5B8A',
  ];

  static String _coverColor(String title) =>
      _palette[_fnv1a(title) % _palette.length];

  /// 由书名 + 长度得到稳定 id（重复导入同一文件得到同一 id，便于覆盖去重）。
  static int _stableId(String title, int textLen) => _fnv1a('$title|$textLen');

  /// 32 位 FNV-1a（跨运行稳定，避免用不保证稳定的 String.hashCode）。
  static int _fnv1a(String s) {
    int hash = 0x811c9dc5;
    for (final int c in s.codeUnits) {
      hash ^= c;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    return hash;
  }
}

class _Meta {
  const _Meta({required this.title, required this.author, required this.intro});
  final String title;
  final String author;
  final String intro;
}

class _Chapter {
  _Chapter(this.title, this.paragraphs);
  final String title;
  final List<String> paragraphs;
}
