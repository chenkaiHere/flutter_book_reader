import 'package:flutter/material.dart';

import '../data/db/app_database.dart';
import '../theme/warm_theme.dart';
import 'book_cover.dart';
import 'warm_widgets.dart';

/// 书架列表视图中的单本书卡片（纯展示；数据来自 drift 的轻量 [BookRow]，不含正文）。
class BookCard extends StatelessWidget {
  const BookCard({
    super.key,
    required this.book,
    required this.progress,
    required this.onTap,
  });

  final BookRow book;

  /// 阅读进度 0..1（0 表示未读）。
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool started = progress > 0;
    return Material(
      color: Warm.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: Warm.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Warm.hairline),
            boxShadow: Warm.softCard,
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              BookCover(
                title: book.title,
                color: Color(book.coverColor),
                width: 66,
                height: 92,
                fontSize: 15,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            book.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Warm.serif(
                              size: 18,
                              weight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (book.imported) ...<Widget>[
                          const SizedBox(width: 8),
                          const TagChip('本地'),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${book.author} · 共 ${book.chapterCount} 章',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Warm.sans(size: 12.5, color: Warm.muted),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      book.intro,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Warm.sans(size: 13, height: 1.6, color: Warm.ink2),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: WarmProgressBar(value: progress, height: 5),
                        ),
                        const SizedBox(width: 9),
                        Text(
                          started ? '已读 ${(progress * 100).round()}%' : '未读',
                          style: Warm.sans(size: 11.5, color: Warm.muted),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
