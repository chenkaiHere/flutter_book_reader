import 'package:flutter/material.dart';

import '../l10n/app_locales.dart';
import '../l10n/app_localizations.dart';
import '../theme/warm_theme.dart';

/// 语言选择弹窗：从底部弹出，列出前十主流语言，点击即切换并持久化。
class LanguageSheet {
  const LanguageSheet._();

  static Future<void> show(BuildContext context) {
    final Locale current =
        LocaleController.notifier.value ?? Localizations.localeOf(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      // 底部弹窗最高占竖屏 70%，内容超出则内部滚动，不铺满全屏。
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      builder: (BuildContext ctx) {
        final String title = AppLocalizations.of(ctx).languageSheetTitle;
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
                    child: Text(title, style: Warm.serif(size: 20)),
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.only(bottom: 8),
                    itemCount: kAppLanguages.length,
                    itemBuilder: (BuildContext _, int i) {
                      final AppLanguage lang = kAppLanguages[i];
                      final bool active =
                          lang.locale.languageCode == current.languageCode;
                      return InkWell(
                        onTap: () async {
                          await LocaleController.set(lang.locale);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 14,
                          ),
                          child: Row(
                            children: <Widget>[
                              Text(
                                lang.flag,
                                style: const TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      lang.nativeName,
                                      style: Warm.sans(
                                        size: 16,
                                        weight: active
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: active ? Warm.accent : Warm.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      lang.englishName,
                                      style: Warm.sans(
                                        size: 12,
                                        color: Warm.muted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (active)
                                const Icon(
                                  Icons.check_circle,
                                  size: 20,
                                  color: Warm.accent,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
