import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';

import 'azure_tts_backend.dart';
import 'system_tts_backend.dart';
import 'tts_backend.dart';
import 'tts_config.dart';

/// 全局听书服务单例：TTS 播放独立于阅读页存在，退出阅读页也继续，mini 气泡随之常驻。
final ListenService listenService = ListenService();

class _Speed {
  const _Speed(this.label, this.multiplier);
  final String label;
  final double multiplier; // 语速倍率（1.0 = 常速），由 backend 映射到各自参数
}

/// 全局听书引擎：直接按「章」从 [BookSource] 读取正文交给 [TtsBackend]，逐句朗读、读完
/// 自动进入下一章，与阅读器分页解耦——因此可脱离阅读页在全局持续播放。
///
/// 朗读来源经 [TtsBackend] 抽象：配置了 Azure 密钥且非 Web → 云端音色（[AzureTtsBackend]），
/// 否则用系统 TTS（[SystemTtsBackend]）兜底。
class ListenService extends ChangeNotifier {
  // 填了 Azure 密钥且非 Web 就用云端音色，否则回退系统 TTS。
  late final TtsBackend _backend = (TtsConfig.azureEnabled && !kIsWeb)
      ? AzureTtsBackend()
      : SystemTtsBackend();

  static const List<_Speed> _speeds = <_Speed>[
    _Speed('0.8×', 0.8),
    _Speed('1.0×', 1.0),
    _Speed('1.25×', 1.25),
    _Speed('1.5×', 1.5),
    _Speed('2.0×', 2.0),
  ];
  int _speedIdx = 1;

  /// 是否正在使用云端音色（供 UI 展示，可选）。
  bool get usingCloudVoice => _backend is AzureTtsBackend;

  bool _active = false;
  bool _playing = false;
  bool _expanded = false; // 是否处于「完整播放条」态（阅读页内展示）
  bool _inReader = false; // 当前是否在阅读页前台

  Object? _bookId;
  String _bookTitle = '';
  BookSource? _source;
  String _localeCode = 'en';
  List<String> _chapterTitles = const <String>[];
  int _chapterCount = 0;
  int _chapterIndex = 0;

  List<String> _frags = const <String>[];
  int _fragIdx = 0;
  String _currentFragment = ''; // 正在朗读的分句（供阅读页跟读高亮）
  String? _startProbe; // 起始定位探针：首章分句后跳到含此句的分句开始
  bool _restart = false;
  int _session = 0; // 会话号：换书 / 停止时自增，令旧朗读循环退出

  /// 由 App（书架）注册：请求打开某本书的阅读页。mini 在非阅读页被点击时触发。
  void Function(Object bookId, int chapterIndex)? onOpenReaderRequested;

  bool get active => _active;
  bool get playing => _playing;
  bool get expanded => _expanded;
  bool get inReader => _inReader;
  Object? get bookId => _bookId;
  String get bookTitle => _bookTitle;
  int get chapterIndex => _chapterIndex;
  String get currentFragment => _currentFragment;
  String get speedLabel => _speeds[_speedIdx].label;
  String get chapterTitle =>
      (_chapterIndex >= 0 && _chapterIndex < _chapterTitles.length)
      ? _chapterTitles[_chapterIndex]
      : '';

  void setInReader(bool v) {
    if (_inReader == v) return;
    _inReader = v;
    notifyListeners();
  }

  void setExpanded(bool v) {
    if (_expanded == v) return;
    _expanded = v;
    notifyListeners();
  }

  /// 请求跳转到当前听书这本书的阅读页（并展开为完整条）。非阅读页点 mini 时用。
  void requestOpenReader() {
    final Object? id = _bookId;
    if (id == null) return;
    _expanded = true;
    notifyListeners();
    onOpenReaderRequested?.call(id, _chapterIndex);
  }

  String _lang() => bcp47ForLocale(_localeCode);

  static String bcp47ForLocale(String code) {
    switch (code) {
      case 'zh':
        return 'zh-CN';
      case 'en':
        return 'en-US';
      case 'ja':
        return 'ja-JP';
      case 'ko':
        return 'ko-KR';
      default:
        return code;
    }
  }

  /// 朗读前的可用性预检；UI 据此在缺引擎 / 缺语言时弹出友好引导。
  Future<TtsAvailability> checkAvailability(String localeCode) =>
      _backend.checkAvailability(bcp47ForLocale(localeCode));

  /// 开始 / 恢复听书。同一本书已在听 → 只展开为完整条；否则换书重开。
  Future<void> start({
    required Object bookId,
    required String bookTitle,
    required BookSource source,
    required int startChapter,
    required String localeCode,
    String? startText,
  }) async {
    if (_active && _bookId == bookId) {
      setExpanded(true);
      return;
    }
    await _backend.stop();
    final int session = ++_session;
    _bookId = bookId;
    _bookTitle = bookTitle;
    _source = source;
    _localeCode = localeCode;
    _chapterIndex = startChapter;
    _frags = const <String>[];
    _fragIdx = 0;
    // 从「当前页第一句」开始，而非整章开头。
    _startProbe = (startText == null) ? null : _firstSentence(startText);
    _active = true;
    _playing = true;
    _expanded = true;
    notifyListeners();

    try {
      final BookManifest m = await source.loadManifest();
      _chapterTitles = m.chapterTitles;
      _chapterCount = m.chapterCount;
    } catch (_) {
      _chapterTitles = const <String>[];
      _chapterCount = 0;
    }
    if (session != _session) return;
    await _backend.setLanguage(_lang());
    await _backend.setSpeed(_speeds[_speedIdx].multiplier);
    notifyListeners();
    await _loop(session);
  }

  /// 取一段文字里第一句（去掉行首缩进 / 空白，截到首个断句标点），用作起始定位探针。
  String _firstSentence(String text) {
    const String breaks = '。！？!?；;，,、：:…\n';
    final String t = text.replaceFirst(RegExp(r'^[\s　]+'), '');
    final StringBuffer buf = StringBuffer();
    for (final int r in t.runes) {
      final String ch = String.fromCharCode(r);
      if (breaks.contains(ch)) break;
      buf.write(ch);
    }
    return buf.toString().trim();
  }

  List<String> _split(String text) {
    const String breaks = '。！？!?；;，,、：:…\n';
    final List<String> res = <String>[];
    final StringBuffer buf = StringBuffer();
    for (final int r in text.runes) {
      final String ch = String.fromCharCode(r);
      buf.write(ch);
      if (breaks.contains(ch)) {
        final String s = buf.toString().trim();
        if (s.isNotEmpty) res.add(s);
        buf.clear();
      }
    }
    final String tail = buf.toString().trim();
    if (tail.isNotEmpty) res.add(tail);
    return res;
  }

  Future<void> _loop(int session) async {
    final BookSource? src = _source;
    if (src == null) return;
    while (_active && _playing && session == _session) {
      if (_frags.isEmpty) {
        String body = '';
        try {
          body = await src.loadChapterBody(_chapterIndex);
        } catch (_) {
          body = '';
        }
        if (session != _session) return;
        _frags = _split(body);
        _fragIdx = 0;
        // 首章：跳到「当前页第一句」所在的分句再开始。
        final String? probe = _startProbe;
        _startProbe = null;
        if (probe != null && probe.isNotEmpty) {
          for (int i = 0; i < _frags.length; i++) {
            final String f = _frags[i].trim();
            if (f.contains(probe) || probe.contains(f)) {
              _fragIdx = i;
              break;
            }
          }
        }
      }
      while (_active &&
          _playing &&
          session == _session &&
          _fragIdx < _frags.length) {
        // 广播当前朗读句：阅读页据此跟读高亮 + 自动翻页。
        _currentFragment = _frags[_fragIdx];
        notifyListeners();
        final bool ok = await _backend.speak(_frags[_fragIdx]);
        if (!_active || !_playing || session != _session) return;
        if (!ok) {
          // 引擎/服务不可用（设备未装 TTS、或云端鉴权/网络失败）：停止播放，避免空转卡死。
          _playing = false;
          notifyListeners();
          return;
        }
        if (_restart) {
          _restart = false; // 调速：同一句用新语速重读
          continue;
        }
        _fragIdx++;
      }
      if (!_active || !_playing || session != _session) return;
      if (_chapterIndex >= _chapterCount - 1) {
        _playing = false;
        notifyListeners();
        return;
      }
      _chapterIndex++;
      _frags = const <String>[];
      _fragIdx = 0;
      notifyListeners();
    }
  }

  Future<void> togglePlay() async {
    if (!_active) return;
    if (_playing) {
      _playing = false;
      notifyListeners();
      await _backend.stop();
    } else {
      _playing = true;
      notifyListeners();
      await _loop(_session);
    }
  }

  Future<void> cycleSpeed() async {
    _speedIdx = (_speedIdx + 1) % _speeds.length;
    notifyListeners();
    await _backend.setSpeed(_speeds[_speedIdx].multiplier);
    if (_playing) {
      _restart = true;
      await _backend.stop();
    }
  }

  Future<void> stop() async {
    _session++;
    _active = false;
    _playing = false;
    _expanded = false;
    notifyListeners();
    await _backend.stop();
  }

  @override
  void dispose() {
    _backend.dispose();
    super.dispose();
  }
}
