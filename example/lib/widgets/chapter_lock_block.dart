import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';

import '../l10n/app_localizations.dart';

/// 付费章首页底部的「订阅本章」解锁块（示例实现）。
///
/// 这是**业务方**提供给 [BookReader.chapterLockBuilder] 的 UI：阅读器只负责把它叠在
/// 首页底部并加渐变蒙层，样式、文案、点击后的下单/解锁流程都由 App 自行决定。
/// 此处 [onUnlock] 直接把该章标记为已解锁并触发 lockRefresh 以演示效果。
class ChapterLockBlock extends StatelessWidget {
  const ChapterLockBlock({
    super.key,
    required this.theme,
    required this.info,
    required this.onUnlock,
  });

  final ReaderTheme theme;
  final ReaderLockInfo info;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final Color sub = theme.subTextColor;
    final AppLocalizations l = AppLocalizations.of(context);
    // 分页模式：顶部留半屏，把按钮顶到页面底部并留出渐隐区；
    // 上下滚动模式：解锁块直接跟在预览正文后面，无需大留白。
    final double topGap =
        info.isScrollMode ? 8 : MediaQuery.sizeOf(context).height / 2;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, topGap, 20, 22),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.radio_button_unchecked, size: 15, color: sub),
              const SizedBox(width: 6),
              Text(l.lockAutoSubscribe,
                  style: TextStyle(fontSize: 12, color: sub)),
              const Spacer(),
              Text(l.lockWordCount(info.wordCount),
                  style: TextStyle(fontSize: 12, color: sub)),
              const SizedBox(width: 12),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onUnlock,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Text(
                l.lockSubscribeAction,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
