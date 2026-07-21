import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/warm_theme.dart';
import 'book_cover.dart';

/// 「摘录卡片」分享弹层（App 侧）。
///
/// 阅读器气泡菜单点「分享」时回调给 App，由 App 调用 [ShareCardSheet.show] 弹出本弹层：
/// 顶部书封 + 书名/章节，中部大引号包住摘录文字，底部品牌与日期。点「分享图片」把整张
/// 卡片渲染成 PNG，交给 share_plus 分享（Web 走 Web Share API，移动端走系统分享面板）。
class ShareCardSheet extends StatefulWidget {
  const ShareCardSheet({
    super.key,
    required this.bookTitle,
    required this.author,
    required this.coverColor,
    required this.chapterTitle,
    required this.quote,
    required this.nowText,
  });

  final String bookTitle;
  final String author;
  final Color coverColor;
  final String chapterTitle;
  final String quote;

  /// 「摘录于 yyyy/MM/dd」的日期文案（由调用方传入，便于测试与本地化）。
  final String nowText;

  static Future<void> show(
    BuildContext context, {
    required String bookTitle,
    required String author,
    required Color coverColor,
    required String chapterTitle,
    required String quote,
  }) {
    final DateTime now = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final String nowText = '${now.year}/${two(now.month)}/${two(now.day)}';
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareCardSheet(
        bookTitle: bookTitle,
        author: author,
        coverColor: coverColor,
        chapterTitle: chapterTitle,
        quote: quote,
        nowText: nowText,
      ),
    );
  }

  @override
  State<ShareCardSheet> createState() => _ShareCardSheetState();
}

class _ShareCardSheetState extends State<ShareCardSheet> {
  final GlobalKey _cardKey = GlobalKey();
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final RenderObject? ro = _cardKey.currentContext?.findRenderObject();
      if (ro is! RenderRepaintBoundary) return;
      // pixelRatio 3：导出高清图，避免分享出去发糊。
      final ui.Image image = await ro.toImage(pixelRatio: 3);
      final ByteData? data = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      image.dispose();
      if (data == null) return;
      final Uint8List bytes = data.buffer.asUint8List();
      final XFile file = XFile.fromData(
        bytes,
        mimeType: 'image/png',
        name: 'quote.png',
      );
      await SharePlus.instance.share(
        ShareParams(files: <XFile>[file], text: widget.quote),
      );
      if (mounted) Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 自适应宽度，避免窄屏（可用宽度 < 340）时水平溢出。
    final double width = (MediaQuery.of(context).size.width - 32).clamp(
      0.0,
      340.0,
    );
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // 卡片本体：用 RepaintBoundary 包住，供截图。
            RepaintBoundary(key: _cardKey, child: _card(width)),
            const SizedBox(height: 20),
            _actions(width),
          ],
        ),
      ),
    );
  }

  Widget _card(double width) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFBF6EC), Color(0xFFF2E8D6)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _header(),
            const SizedBox(height: 34),
            _quote(),
            const SizedBox(height: 34),
            _footer(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        BookCover(
          title: widget.bookTitle,
          color: widget.coverColor,
          width: 52,
          height: 72,
          fontSize: 12,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '《${widget.bookTitle}》· ${widget.chapterTitle}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Warm.serif(
                  size: 15,
                  weight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.author} 著',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Warm.sans(size: 12, color: Warm.muted2),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _quote() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '“',
            style: TextStyle(
              fontFamilyFallback: const <String>['Georgia', 'serif'],
              fontSize: 52,
              height: 0.9,
              fontWeight: FontWeight.w700,
              color: Warm.accent.withValues(alpha: 0.28),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            widget.quote,
            textAlign: TextAlign.center,
            style: Warm.serif(
              size: 19,
              weight: FontWeight.w600,
              height: 1.7,
            ).copyWith(color: Warm.ink),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '”',
            style: TextStyle(
              fontFamilyFallback: const <String>['Georgia', 'serif'],
              fontSize: 52,
              height: 0.4,
              fontWeight: FontWeight.w700,
              color: Warm.accent.withValues(alpha: 0.28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _footer() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Divider(color: Warm.ink.withValues(alpha: 0.1), height: 1),
        const SizedBox(height: 14),
        Row(
          children: <Widget>[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: Warm.accent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 19,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'ReadBook 阅读',
                  style: Warm.serif(size: 13, weight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  '摘录于 ${widget.nowText}',
                  style: Warm.sans(size: 11, color: Warm.muted2),
                ),
              ],
            ),
            const Spacer(),
            // 简单的品牌角标（占位「扫码阅读」的位置，避免额外引入二维码依赖）。
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Warm.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '长按分享 · 好书共读',
                style: Warm.sans(
                  size: 11,
                  weight: FontWeight.w600,
                  color: Warm.accent,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _actions(double width) {
    return SizedBox(
      width: width,
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Warm.card,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  '取消',
                  style: Warm.sans(
                    size: 15,
                    weight: FontWeight.w600,
                    color: Warm.ink2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _busy ? null : _share,
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _busy
                      ? Warm.accent.withValues(alpha: 0.5)
                      : Warm.accent,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(
                            Icons.ios_share_rounded,
                            size: 18,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '分享图片',
                            style: Warm.sans(
                              size: 15,
                              weight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
