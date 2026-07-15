import 'package:flutter/material.dart';

import '../paginator.dart';
import '../reader_config.dart';
import '../reader_labels.dart';
import '../reader_theme.dart';

/// 单页排版组件：顶部章节名 + 正文（按块渲染，含段间距/两端对齐）+ 底部信息栏。
///
/// 纯展示组件，不含任何翻页逻辑；横向翻页的正文页与边界页都复用它。
class ReaderPageFrame extends StatelessWidget {
  const ReaderPageFrame({
    super.key,
    required this.theme,
    required this.config,
    required this.chapterTitle,
    required this.page,
    required this.chapterIndex,
    required this.chapterCount,
    required this.pageIndex,
    required this.pageCount,
    required this.progress,
    this.padding = kReaderPagePadding,
  });

  final ReaderTheme theme;
  final ReaderConfig config;
  final String chapterTitle;
  final ReaderPage page;
  final int chapterIndex;
  final int chapterCount;
  final int pageIndex;
  final int pageCount;
  final double progress;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final ReaderLabels labels = ReaderLabels.of(context);
    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: kReaderHeaderHeight,
            child: Text(
              chapterTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: theme.subTextColor),
            ),
          ),
          Expanded(
            child: ReaderProse(page: page, config: config, bounded: true),
          ),
          _footer(labels),
        ],
      ),
    );
  }

  Widget _footer(ReaderLabels labels) {
    final TextStyle style = TextStyle(fontSize: 11, color: theme.subTextColor);
    return SizedBox(
      height: kReaderFooterHeight,
      child: Row(
        children: <Widget>[
          Text(
            labels.chapterProgress(chapterIndex, chapterCount),
            style: style,
          ),
          const Spacer(),
          if (pageCount > 0) Text('${pageIndex + 1}/$pageCount', style: style),
          const SizedBox(width: 12),
          Text('${(progress * 100).toStringAsFixed(1)}%', style: style),
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
