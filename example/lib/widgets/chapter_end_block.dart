import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';

import '../l10n/app_localizations.dart';

/// 章末组件（示例实现）：左侧「本章讨论」入口 + 右侧「送礼物」按钮。
///
/// 这是**业务方**提供给 `BookReader.chapterEndBuilder` 的 UI —— 插件只负责把它排在
/// 每章正文之后并预留高度，样式与点击行为都属于 App。礼物弹层由 [onGiftTap] 打开
/// （见 `GiftSheet`），插件完全不介入。
class ChapterEndBlock extends StatelessWidget {
  const ChapterEndBlock({
    super.key,
    required this.theme,
    required this.info,
    required this.discussionCount,
    required this.onDiscussionTap,
    required this.onGiftTap,
  });

  final ReaderTheme theme;
  final ReaderChapterEndInfo info;

  /// 本章讨论数（示例用 mock 值）。
  final int discussionCount;

  final VoidCallback onDiscussionTap;
  final VoidCallback onGiftTap;

  /// 卡片底色：在纸张色上叠一层极浅的文字色，任何主题下都自然。
  Color get _cardColor => theme.textColor.withValues(alpha: 0.06);

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 2),
      child: Row(
        children: <Widget>[
          Expanded(child: _discussionCard(l)),
          const SizedBox(width: 10),
          _giftButton(),
        ],
      ),
    );
  }

  Widget _discussionCard(AppLocalizations l) {
    return Material(
      color: _cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onDiscussionTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: <Widget>[
              Text(
                l.chapterEndDiscussion,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: theme.textColor,
                ),
              ),
              const Spacer(),
              Text(
                l.chapterEndDiscussionCount(discussionCount),
                style: TextStyle(fontSize: 13, color: theme.subTextColor),
              ),
              const SizedBox(width: 2),
              Icon(Icons.chevron_right, size: 18, color: theme.subTextColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _giftButton() {
    return Material(
      color: _cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onGiftTap,
        child: const SizedBox(
          width: 56,
          height: 52,
          child: Center(child: Text('🎁', style: TextStyle(fontSize: 26))),
        ),
      ),
    );
  }
}
