import 'package:flutter/material.dart';

import '../reader_labels.dart';
import '../reader_theme.dart';

/// 章节目录抽屉。点击某章返回其序号。仅依赖标题列表，不耦合具体数据模型。
class CatalogSheet extends StatefulWidget {
  const CatalogSheet({
    super.key,
    required this.bookTitle,
    required this.chapterTitles,
    required this.currentIndex,
    required this.theme,
  });

  final String bookTitle;
  final List<String> chapterTitles;
  final int currentIndex;
  final ReaderTheme theme;

  @override
  State<CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<CatalogSheet> {
  static const double _itemExtent = 52;
  late final ScrollController _controller = ScrollController(
    // 打开目录时大致定位到当前章
    initialScrollOffset: (widget.currentIndex * _itemExtent - 200).clamp(
      0,
      double.infinity,
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ReaderLabels labels = ReaderLabels.of(context);
    final Color text = widget.theme.textColor;
    final Color accent = widget.theme.accentColor;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              children: <Widget>[
                Text(
                  widget.bookTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: text,
                  ),
                ),
                const Spacer(),
                Text(
                  labels.chapterTotal(widget.chapterTitles.length),
                  style: TextStyle(
                    fontSize: 13,
                    color: widget.theme.subTextColor,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: text.withValues(alpha: 0.08)),
          Expanded(
            child: ListView.builder(
              controller: _controller,
              itemCount: widget.chapterTitles.length,
              itemExtent: _itemExtent,
              itemBuilder: (BuildContext context, int i) {
                final bool active = i == widget.currentIndex;
                return InkWell(
                  onTap: () => Navigator.of(context).pop(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            widget.chapterTitles[i],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              color: active
                                  ? accent
                                  : text.withValues(alpha: 0.85),
                              fontWeight:
                                  active ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (active)
                          Icon(
                            Icons.play_arrow_rounded,
                            size: 18,
                            color: accent,
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
    );
  }
}
