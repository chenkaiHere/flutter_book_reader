import 'dart:async';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:http/http.dart' as http;

import 'tts_backend.dart';
import 'tts_config.dart';

/// 云端 TTS 实现：调用 Azure 认知服务的 REST 合成接口，把每句合成成 MP3 后本地播放。
///
/// 逐句「合成 → 播放 → 播完返回」，与听书循环的分句节奏天然契合。摆脱设备语音引擎差异，
/// 音色/自然度更好。⚠️ demo 直连、密钥在客户端，勿上线，见 [TtsConfig]。
class AzureTtsBackend implements TtsBackend {
  AzureTtsBackend() {
    _completeSub = _player.onPlayerComplete.listen((_) {
      if (_current != null && !_current!.isCompleted) _current!.complete();
    });
  }

  final AudioPlayer _player = AudioPlayer();
  StreamSubscription<void>? _completeSub;

  String _voice = TtsConfig.voiceForLanguage('en');
  int _ratePercent = 0; // SSML prosody rate：相对常速的百分比
  Completer<void>? _current;
  int _epoch = 0; // stop 时自增，令进行中的合成 / 播放放弃

  @override
  Future<TtsAvailability> checkAvailability(String bcp47) async =>
      TtsAvailability.ok; // 云端不依赖设备引擎

  @override
  Future<void> setLanguage(String bcp47) async {
    _voice = TtsConfig.voiceForLanguage(bcp47.split('-').first);
  }

  @override
  Future<void> setSpeed(double multiplier) async {
    _ratePercent = ((multiplier - 1) * 100).round();
  }

  /// 从音色名（如 `zh-CN-XiaoxiaoNeural`）取出 BCP-47 语言（`zh-CN`）。
  String _localeOfVoice() {
    final int first = _voice.indexOf('-');
    if (first < 0) return _voice;
    final int second = _voice.indexOf('-', first + 1);
    return second < 0 ? _voice : _voice.substring(0, second);
  }

  String _ssml(String text) {
    final String rate = _ratePercent >= 0 ? '+$_ratePercent%' : '$_ratePercent%';
    final String esc = text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
    return '<speak version="1.0" xml:lang="${_localeOfVoice()}">'
        '<voice name="$_voice"><prosody rate="$rate">$esc</prosody></voice>'
        '</speak>';
  }

  @override
  Future<bool> speak(String text) async {
    final int epoch = _epoch;
    Uint8List bytes;
    try {
      final http.Response resp = await http.post(
        Uri.parse(
          'https://${TtsConfig.azureRegion}.tts.speech.microsoft.com'
          '/cognitiveservices/v1',
        ),
        headers: <String, String>{
          'Ocp-Apim-Subscription-Key': TtsConfig.azureKey,
          'Content-Type': 'application/ssml+xml',
          'X-Microsoft-OutputFormat': 'audio-24khz-48kbitrate-mono-mp3',
          'User-Agent': 'flutter_book_reader_example',
        },
        body: _ssml(text),
      );
      if (resp.statusCode != 200) return false;
      bytes = resp.bodyBytes;
    } catch (_) {
      return false; // 网络 / 鉴权失败：上层据此优雅停止
    }
    if (epoch != _epoch) return true; // 合成期间被停止

    final Completer<void> c = Completer<void>();
    _current = c;
    try {
      await _player.stop();
      await _player.play(BytesSource(bytes, mimeType: 'audio/mpeg'));
    } catch (_) {
      if (!c.isCompleted) c.complete();
      return false;
    }
    await c.future; // 由 onPlayerComplete 或 stop() 结束
    return true;
  }

  @override
  Future<void> stop() async {
    _epoch++;
    if (_current != null && !_current!.isCompleted) _current!.complete();
    try {
      await _player.stop();
    } catch (_) {}
  }

  @override
  void dispose() {
    _completeSub?.cancel();
    _player.dispose();
  }
}
