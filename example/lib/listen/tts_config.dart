/// Azure 认知服务 TTS 的 **demo 配置**。
///
/// ⚠️ 仅本地体验：本方案让客户端**直连 Azure**，密钥会暴露在客户端，**切勿用于上线**。
/// 生产环境请改为「走自己的后端中转」——客户端只调你的接口，密钥留在服务端。
///
/// 为避免把密钥写进源码，用 `--dart-define` 注入：
/// ```
/// flutter run --dart-define=AZURE_TTS_KEY=你的密钥 --dart-define=AZURE_TTS_REGION=eastasia
/// ```
/// 未提供密钥时 [azureEnabled] 为 false，听书自动回退到系统 TTS。
class TtsConfig {
  TtsConfig._();

  static const String azureKey =
      String.fromEnvironment('AZURE_TTS_KEY', defaultValue: '');
  static const String azureRegion =
      String.fromEnvironment('AZURE_TTS_REGION', defaultValue: 'eastasia');

  static bool get azureEnabled => azureKey.isNotEmpty;

  /// 各语言对应的 Azure 神经音色（可按需增改 / 让用户在 UI 里选）。
  static String voiceForLanguage(String code) {
    switch (code) {
      case 'zh':
        return 'zh-CN-XiaoxiaoNeural';
      case 'en':
        return 'en-US-AriaNeural';
      case 'ja':
        return 'ja-JP-NanamiNeural';
      case 'ko':
        return 'ko-KR-SunHiNeural';
      case 'es':
        return 'es-ES-ElviraNeural';
      case 'fr':
        return 'fr-FR-DeniseNeural';
      case 'pt':
        return 'pt-BR-FranciscaNeural';
      case 'ru':
        return 'ru-RU-SvetlanaNeural';
      case 'hi':
        return 'hi-IN-SwaraNeural';
      case 'ar':
        return 'ar-EG-SalmaNeural';
      case 'bn':
        return 'bn-IN-TanishaaNeural';
      case 'ur':
        return 'ur-PK-UzmaNeural';
      default:
        return 'en-US-AriaNeural';
    }
  }
}
