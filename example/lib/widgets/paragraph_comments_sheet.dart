import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';

import '../theme/warm_theme.dart';

/// 「段评」评论列表弹层（App 侧）。
///
/// 阅读器点段尾数字角标时把段落信息回调给 App，App 据此筛出该段评论并调用
/// [ParagraphCommentsSheet.show] 弹出本列表（插件不弹）。样式参考主流阅读器段评：
/// 头像 + 昵称 + 评论正文 + 相对时间 + 点赞。这里的评论是 demo 内本地保存的想法。
class ParagraphCommentsSheet extends StatelessWidget {
  const ParagraphCommentsSheet({
    super.key,
    required this.comments,
    required this.labels,
    required this.scrollController,
  });

  final List<Comment> comments;
  final ReaderLabels labels;
  final ScrollController scrollController;

  static Future<void> show(
    BuildContext context, {
    required List<Comment> comments,
    required ReaderLabels labels,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (BuildContext ctx, ScrollController controller) => ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: ColoredBox(
            color: Warm.sheet,
            child: ParagraphCommentsSheet(
              comments: comments,
              labels: labels,
              scrollController: controller,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 新的在上。
    final List<Comment> list = List<Comment>.of(comments)
      ..sort((Comment a, Comment b) => b.createdAt.compareTo(a.createdAt));
    return SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _grabber(),
          _header(context, list.length),
          const Divider(height: 1, color: Color(0x14000000)),
          Expanded(
            child: ListView.separated(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 26, color: Color(0x0F000000)),
              itemBuilder: (BuildContext context, int i) => _item(list[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grabber() => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0x33000000),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  Widget _header(BuildContext context, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 12, 12),
      child: Row(
        children: <Widget>[
          Text(
            labels.segmentCommentsTitle(count),
            style: Warm.serif(size: 17, weight: FontWeight.w700),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.close, size: 20, color: Warm.muted),
          ),
        ],
      ),
    );
  }

  Widget _item(Comment c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _avatar(c),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Text(
                    labels.commentAuthorSelf,
                    style: Warm.sans(size: 13, color: Warm.muted2),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Warm.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      labels.segmentTagLabel,
                      style: Warm.sans(size: 10, color: Warm.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                c.text,
                style: Warm.sans(size: 15, height: 1.5, color: Warm.ink),
              ),
              if (c.quote.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
                  decoration: const BoxDecoration(
                    color: Color(0x0A000000),
                    borderRadius: BorderRadius.all(Radius.circular(6)),
                  ),
                  child: Text(
                    labels.commentQuote(c.quote),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Warm.sans(size: 12, height: 1.4, color: Warm.muted2),
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  Text(
                    labels.relativeTime(c.createdAt),
                    style: Warm.sans(size: 12, color: Warm.muted),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.favorite_border,
                    size: 16,
                    color: Warm.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    labels.commentLike,
                    style: Warm.sans(size: 12, color: Warm.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _avatar(Comment c) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        gradient: Warm.coverGradient(Warm.accent),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.person, size: 20, color: Colors.white),
    );
  }
}
