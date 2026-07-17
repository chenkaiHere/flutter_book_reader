import 'package:flutter/material.dart';

import '../paginator.dart';
import '../reader_config.dart';
import '../reader_labels.dart';
import '../reader_theme.dart';

/// 顶部小标题栏：章首显示书名、非章首显示章节标题；横向 / 纵向模式共用。
class ReaderHeaderBar extends StatelessWidget {
  const ReaderHeaderBar({super.key, required this.title, required this.theme});

  final String title;
  final ReaderTheme theme;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kReaderHeaderHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: theme.subTextColor),
        ),
      ),
    );
  }
}

/// 底部信息栏：章号 / 页码 / 进度。作为固定 chrome，不随翻页滑动。
class ReaderFooterBar extends StatelessWidget {
  const ReaderFooterBar({
    super.key,
    required this.theme,
    required this.chapterIndex,
    required this.chapterCount,
    required this.pageIndex,
    required this.pageCount,
    required this.progress,
  });

  final ReaderTheme theme;
  final int chapterIndex;
  final int chapterCount;
  final int pageIndex;
  final int pageCount;
  final double progress;

  @override
  Widget build(BuildContext context) {
    final ReaderLabels labels = ReaderLabels.of(context);
    final TextStyle style = TextStyle(fontSize: 11, color: theme.subTextColor);
    return SizedBox(
      height: kReaderFooterHeight,
      child: Row(
        children: <Widget>[
          Text(labels.chapterProgress(chapterIndex, chapterCount),
              style: style),
          const Spacer(),
          if (pageCount > 0) Text('${pageIndex + 1}/$pageCount', style: style),
          const SizedBox(width: 12),
          Text('${(progress * 100).toStringAsFixed(1)}%', style: style),
        ],
      ),
    );
  }
}

/// 单页完整内容：顶部小标题 +（章首）大标题 + 正文 + 底部信息栏。
///
/// 顶/底信息栏都随本页一起翻页/滚动（不是固定 chrome）。
/// 顶部小标题：本章第一页（[isChapterHead]）显示 [bookTitle]，其余页显示 [chapterTitle]。
class ReaderPageContent extends StatelessWidget {
  const ReaderPageContent({
    super.key,
    required this.theme,
    required this.config,
    required this.bookTitle,
    required this.chapterTitle,
    required this.page,
    required this.isChapterHead,
    required this.chapterIndex,
    required this.chapterCount,
    required this.pageIndex,
    required this.pageCount,
    required this.progress,
    this.padding = kReaderPagePadding,
  });

  final ReaderTheme theme;
  final ReaderConfig config;
  final String bookTitle;
  final String chapterTitle;
  final ReaderPage page;
  final bool isChapterHead;
  final int chapterIndex;
  final int chapterCount;
  final int pageIndex;
  final int pageCount;
  final double progress;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReaderHeaderBar(
            title: isChapterHead ? bookTitle : chapterTitle,
            theme: theme,
          ),
          if (isChapterHead) ...<Widget>[
            const SizedBox(height: kReaderHeadingGapTop),
            Text(chapterTitle, style: config.headingStyle),
            const SizedBox(height: kReaderHeadingGapBottom),
          ],
          Expanded(
            child: ReaderProse(page: page, config: config, bounded: true),
          ),
          ReaderFooterBar(
            theme: theme,
            chapterIndex: chapterIndex,
            chapterCount: chapterCount,
            pageIndex: pageIndex,
            pageCount: pageCount,
            progress: progress,
          ),
        ],
      ),
    );
  }
}

/// 按文本块渲染一页正文：段落起始块之上加段间距，正文按配置对齐。
///
/// [bounded] 为 true（分页模式，处于固定高度容器中）时，用 ClipRect + OverflowBox
/// 让正文以自然高度排布、末尾多余空白被裁剪，绝不触发 RenderFlex 溢出断言；
/// 为 false（纵向连续滚动，处于无界高度的列表中）时用普通 Column。
class ReaderProse extends StatelessWidget {
  const ReaderProse({
    super.key,
    required this.page,
    required this.config,
    this.bounded = false,
  });

  final ReaderPage page;
  final ReaderConfig config;
  final bool bounded;

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < page.length; i++) {
      final ReaderBlock block = page[i];
      if (i > 0 && block.isParagraphStart) {
        children.add(SizedBox(height: config.paragraphSpacing));
      }
      children.add(
        Text(block.text, style: config.textStyle, textAlign: config.textAlign),
      );
    }
    final Column column = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    if (!bounded) return column;
    // 分页模式：文字已由分页保证落在可视高度内（见 kReaderContentSafety），
    // 裁掉的只会是末尾空白，不会是文字。
    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.topCenter,
        minHeight: 0,
        maxHeight: double.infinity,
        child: column,
      ),
    );
  }
}
