import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../listen/tts_backend.dart';

/// 系统 TTS 不可用时的友好引导弹窗：说明原因，并（Android 上）提供一键跳系统「文字转语音」
/// 设置 / 触发下载语音数据的按钮。
Future<void> showTtsUnavailableDialog(
  BuildContext context,
  TtsAvailability reason,
) async {
  final AppLocalizations l = AppLocalizations.of(context);
  final bool noEngine = reason == TtsAvailability.noEngine;
  // 只有 Android 才能用系统 TTS 设置 Intent。
  final bool canOpen =
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  await showDialog<void>(
    context: context,
    builder: (BuildContext ctx) => AlertDialog(
      title: Text(l.ttsUnavailableTitle),
      content: Text(
        noEngine ? l.ttsNoEngineMessage : l.ttsLanguageUnavailableMessage,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(l.cancel),
        ),
        if (canOpen)
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _openSystemTts(installVoiceData: !noEngine);
            },
            child: Text(noEngine ? l.ttsOpenSettings : l.ttsDownloadVoice),
          ),
      ],
    ),
  );
}

/// 打开系统「文字转语音」设置；[installVoiceData] 为 true 时优先触发"下载语音数据"。
Future<void> _openSystemTts({required bool installVoiceData}) async {
  const String ttsSettings = 'com.android.settings.TTS_SETTINGS';
  const String installData = 'android.speech.tts.engine.INSTALL_TTS_DATA';
  final AndroidIntent primary =
      AndroidIntent(action: installVoiceData ? installData : ttsSettings);
  try {
    await primary.launch();
  } catch (_) {
    // 部分 ROM 不支持 INSTALL_TTS_DATA：退回通用 TTS 设置页。
    try {
      await AndroidIntent(action: ttsSettings).launch();
    } catch (_) {}
  }
}
