import 'package:flutter/material.dart';

import '../data/demo_settings.dart';
import '../l10n/app_localizations.dart';
import '../theme/warm_theme.dart';

/// 演示设置弹窗：从底部弹出，与 [LanguageSheet] 同款外观。
///
/// 目前只有「章节解锁（付费章）」一个开关：关闭时阅读不受打断、目录也不显示锁 icon；
/// 开启后即演示付费章效果（前若干章免费，其余需订阅解锁）。
class SettingsSheet {
  const SettingsSheet._();

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (BuildContext ctx) {
        final AppLocalizations l = AppLocalizations.of(ctx);
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Warm.sheet,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 11, bottom: 4),
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0x40785A3C),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 22, 6),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(l.settingsSheetTitle,
                        style: Warm.serif(size: 20)),
                  ),
                ),
                _ChapterLockSwitch(labels: l),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 「章节解锁」开关行：标题 + 说明 + Switch。
class _ChapterLockSwitch extends StatelessWidget {
  const _ChapterLockSwitch({required this.labels});

  final AppLocalizations labels;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: DemoSettings.chapterLockEnabled,
      builder: (BuildContext context, bool on, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    labels.settingsChapterLock,
                    style: Warm.sans(size: 16, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    labels.settingsChapterLockHint,
                    style: Warm.sans(size: 12, color: Warm.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Switch(
              value: on,
              activeThumbColor: Warm.accent,
              onChanged: DemoSettings.setChapterLockEnabled,
            ),
          ],
        ),
      ),
    );
  }
}
