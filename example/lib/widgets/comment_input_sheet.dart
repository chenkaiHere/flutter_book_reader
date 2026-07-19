import 'package:flutter/material.dart';
import 'package:flutter_book_reader/flutter_book_reader.dart';

import '../theme/warm_theme.dart';

/// 「评论 / 想法」底部输入弹层（App 侧）。
///
/// 阅读器气泡菜单点「评论」时不再由插件弹层处理，而是回调给 App，由 App 调用
/// [CommentInputSheet.show] 弹出本弹层；返回用户输入的文字（取消返回 null）。
class CommentInputSheet extends StatefulWidget {
  const CommentInputSheet({
    super.key,
    required this.labels,
    required this.quote,
  });

  /// 复用插件文案（标题 / 占位 / 发送），避免 App 侧重复维护多语言。
  final ReaderLabels labels;

  /// 被评论的原文，作为引用展示在输入框上方。
  final String quote;

  /// 弹出输入层，返回输入文字（发送）或 null（取消 / 关闭）。
  static Future<String?> show(
    BuildContext context, {
    required ReaderLabels labels,
    required String quote,
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CommentInputSheet(labels: labels, quote: quote),
    );
  }

  @override
  State<CommentInputSheet> createState() => _CommentInputSheetState();
}

class _CommentInputSheetState extends State<CommentInputSheet> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
    _ctrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _submit() {
    final String text = _ctrl.text.trim();
    if (text.isEmpty) return;
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    final bool canSend = _ctrl.text.trim().isNotEmpty;
    final double keyboard = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboard),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: Warm.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Color(0x24140C04),
              blurRadius: 24,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Text(
                      widget.labels.commentTitle,
                      style: Warm.serif(size: 16, weight: FontWeight.w700),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Warm.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 原文引用：左侧强调色竖条 + 灰字，最多两行。
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  decoration: const BoxDecoration(
                    color: Warm.card,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                    border: Border(
                      left: BorderSide(color: Warm.accent, width: 3),
                    ),
                  ),
                  child: Text(
                    widget.quote,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Warm.sans(size: 13, height: 1.5, color: Warm.muted2),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _ctrl,
                  focusNode: _focus,
                  maxLines: 4,
                  minLines: 3,
                  textInputAction: TextInputAction.newline,
                  style: Warm.sans(size: 15, height: 1.5, color: Warm.ink),
                  cursorColor: Warm.accent,
                  decoration: InputDecoration(
                    hintText: widget.labels.commentHint,
                    hintStyle: Warm.sans(size: 15, color: Warm.muted),
                    filled: true,
                    fillColor: Warm.card,
                    contentPadding: const EdgeInsets.all(12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: canSend ? _submit : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: canSend
                            ? Warm.accent
                            : Warm.accent.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        widget.labels.commentSend,
                        style: Warm.sans(
                          size: 15,
                          weight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
