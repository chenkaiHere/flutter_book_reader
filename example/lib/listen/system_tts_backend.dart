import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import 'tts_backend.dart';

/// 系统 TTS 实现：包裹 [FlutterTts]，作为默认 / 兜底朗读来源（Web 也走这里）。
///
/// 处理了 Android「引擎异步绑定、首次 speak 可能未绑定」导致的卡死问题：判断 speak 返回值，
/// 失败短暂重试几次，始终失败才返回 false。
class SystemTtsBackend implements TtsBackend {
  final FlutterTts _tts = FlutterTts();
  bool _handlersSet = false;
  Completer<void>? _utterance;
  int _epoch = 0; // stop 时自增，令重试循环退出

  void _ensureHandlers() {
    if (_handlersSet) return;
    _handlersSet = true;
    _tts.setCompletionHandler(_finish);
    _tts.setCancelHandler(_finish);
    _tts.setErrorHandler((dynamic _) => _finish());
  }

  void _finish() {
    if (_utterance != null && !_utterance!.isCompleted) _utterance!.complete();
  }

  @override
  Future<TtsAvailability> checkAvailability(String bcp47) async {
    _ensureHandlers();
    if (kIsWeb) return TtsAvailability.ok; // Web 由浏览器语音合成，另行处理
    try {
      final dynamic engines = await _tts.getEngines;
      if (engines is List && engines.isEmpty) return TtsAvailability.noEngine;
    } catch (_) {
      // 拿引擎列表失败通常意味着根本没绑定到引擎。
      return TtsAvailability.noEngine;
    }
    try {
      final dynamic ok = await _tts.isLanguageAvailable(bcp47);
      if (ok == false) return TtsAvailability.languageUnavailable;
    } catch (_) {
      // 探测失败不武断判为缺语言，交给实际 speak 的重试兜底。
    }
    return TtsAvailability.ok;
  }

  @override
  Future<void> setLanguage(String bcp47) async {
    _ensureHandlers();
    try {
      await _tts.setLanguage(bcp47);
    } catch (_) {}
  }

  @override
  Future<void> setSpeed(double multiplier) async {
    // rate 量纲各平台不同：Web 上 1.0=常速；移动端约 0.5=常速。
    try {
      await _tts.setSpeechRate(kIsWeb ? multiplier : multiplier * 0.5);
    } catch (_) {}
  }

  @override
  Future<bool> speak(String text) async {
    _ensureHandlers();
    if (kIsWeb) {
      final Completer<void> c = Completer<void>();
      _utterance = c;
      try {
        await _tts.speak(text);
      } catch (_) {}
      await c.future;
      return true;
    }
    final int epoch = _epoch;
    for (int attempt = 0; attempt < 5; attempt++) {
      if (epoch != _epoch) return true;
      final Completer<void> c = Completer<void>();
      _utterance = c;
      dynamic result;
      try {
        result = await _tts.speak(text);
      } catch (_) {
        result = 0;
      }
      if (result == 1) {
        await c.future; // 由完成 / 取消 / 错误回调结束
        return true;
      }
      // 引擎未绑定 / 调用失败：等一会再试，给系统 TTS 绑定留时间。
      _utterance = null;
      await Future<void>.delayed(const Duration(milliseconds: 350));
    }
    return false;
  }

  @override
  Future<void> stop() async {
    _epoch++;
    _finish();
    try {
      await _tts.stop();
    } catch (_) {}
  }

  @override
  void dispose() {}
}
