/// 朗读来源的可用性。
enum TtsAvailability {
  /// 可用，可以朗读。
  ok,

  /// 设备没有任何可用 TTS 引擎（需去系统设置安装 / 启用）。
  noEngine,

  /// 有引擎但当前语言的语音数据未安装（需去系统设置下载）。
  languageUnavailable,
}

/// 朗读来源的抽象：听书循环只依赖它，不关心背后是系统 TTS 还是云端 TTS。
///
/// 与阅读器包一贯的「可插拔」设计一致——想换云厂商 / 离线引擎，只需再写一个实现。
abstract class TtsBackend {
  /// 朗读前的可用性预检（[bcp47] 如 `zh-CN`）。默认恒为可用（云端 TTS 不依赖设备引擎）；
  /// 系统 TTS 会真正探测引擎与语言数据。
  Future<TtsAvailability> checkAvailability(String bcp47) async =>
      TtsAvailability.ok;

  /// 设置朗读语言（BCP-47，如 `zh-CN`）。
  Future<void> setLanguage(String bcp47);

  /// 设置语速倍率（`1.0` = 常速）。各实现自行映射到其原生参数。
  Future<void> setSpeed(double multiplier);

  /// 朗读一句，**播放完成后**才返回。成功返回 true；引擎/服务不可用返回 false，
  /// 由上层据此优雅停止，避免空转。
  Future<bool> speak(String text);

  /// 停止当前朗读（用于暂停 / 换句 / 停止）。
  Future<void> stop();

  void dispose();
}
