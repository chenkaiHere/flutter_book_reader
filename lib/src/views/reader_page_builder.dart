import 'package:flutter/material.dart';

import '../chapter_end.dart';
import '../controller/reading_controller.dart';
import '../paginator.dart';
import '../reader_theme.dart';
import '../widgets/locked_page.dart';
import '../widgets/page_frame.dart';

/// 构建「一页正文」的唯一入口：页眉 / 正文 / 页脚的参数拼装 + 付费章首页叠加解锁块。
///
/// 三种分页视图（横向 PageView、仿真卷曲、无动画静态页）以及相邻章的边界预览页
/// 全部走这里。收敛为一处后，新增页级参数（如划线锚点、段评回溯起点）只需改这一个
/// 地方，不会漏掉某个翻页模式而出现「某模式下功能失效」的隐蔽 bug。
///
/// [paperBackground] 为 true 时在外层铺一层不透明纸张底色（仿真翻页需要它，
/// 否则折起的纸页会透出下层内容）。
Widget buildReaderPage({
  required BuildContext context,
  required ReadingController controller,
  required int chapterIndex,
  required List<ReaderPage> pages,
  required int pageIndex,
  bool paperBackground = false,
}) {
  final ReaderTheme theme = controller.config.theme;
  final ReaderPage page = (pageIndex >= 0 && pageIndex < pages.length)
      ? pages[pageIndex]
      : const <ReaderBlock>[];

  // 章末组件只出现在本章最后一页；分页已为它预留高度（chapterEndReserve），
  // 末页放不下时分页器会另起一页，因此这里无需再判断空间。
  // 未解锁付费章只放行首页，读者到不了章末，故不显示章末组件。
  final bool onLastPage =
      pageIndex == pages.length - 1 && !controller.chapterLocked(chapterIndex);
  final Widget? chapterEnd =
      (onLastPage && controller.chapterEndBuilder != null)
          ? controller.chapterEndBuilder!(
              context,
              theme,
              ReaderChapterEndInfo(
                chapterIndex: chapterIndex,
                chapterTitle: controller.chapterTitleAt(chapterIndex),
                isLastChapter: chapterIndex >= controller.chapterCount - 1,
              ),
            )
          : null;

  Widget content = ReaderPageContent(
    theme: theme,
    config: controller.config,
    bookTitle: controller.manifest.title,
    chapterTitle: controller.chapterTitleAt(chapterIndex),
    page: page,
    isChapterHead: pageIndex == 0,
    chapterIndex: chapterIndex,
    chapterCount: controller.chapterCount,
    pageIndex: pageIndex,
    pageCount: pages.length,
    progress: controller.progressFor(chapterIndex, pages, pageIndex),
    pageStartOffset: controller.startOffsetOfPageIn(pages, pageIndex),
    leadingParagraphStart: controller.leadingParagraphStartIn(pages, pageIndex),
    chapterEnd: chapterEnd,
  );

  // 未解锁付费章：首页底部叠加宿主提供的解锁块（其余页不会被展示，见 visiblePageCount）。
  if (pageIndex == 0 &&
      controller.chapterLocked(chapterIndex) &&
      controller.chapterLockBuilder != null) {
    content = ReaderLockedPage(
      theme: theme,
      lockBlock: controller.chapterLockBuilder!(
        context,
        theme,
        controller.lockInfoFor(chapterIndex),
      ),
      child: content,
    );
  }

  return paperBackground
      ? ColoredBox(color: theme.paperColor, child: content)
      : content;
}
