import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/warm_theme.dart';

/// 一件可送出的礼物（示例用 mock 数据；真实业务应来自服务端商品列表）。
@immutable
class Gift {
  const Gift({required this.id, required this.emoji, required this.price});

  final String id;
  final String emoji;

  /// 价格（点数）。
  final int price;

  /// 本地化名称。
  String nameOf(AppLocalizations l) => switch (id) {
        'fireworks' => l.giftFireworks,
        'drumstick' => l.giftDrumstick,
        'flowers' => l.giftFlowers,
        'coffee' => l.giftCoffee,
        'rocket' => l.giftRocket,
        _ => l.giftDiamond,
      };
}

/// 礼物列表（mock）：价格随手定的几档，从便宜到贵。
const List<Gift> kMockGifts = <Gift>[
  Gift(id: 'flowers', emoji: '💐', price: 5),
  Gift(id: 'coffee', emoji: '☕️', price: 12),
  Gift(id: 'drumstick', emoji: '🍗', price: 30),
  Gift(id: 'fireworks', emoji: '🎆', price: 66),
  Gift(id: 'rocket', emoji: '🚀', price: 188),
  Gift(id: 'diamond', emoji: '💎', price: 520),
];

/// 送礼物弹窗（**由业务方创建**）。
///
/// 插件只负责在章末显示入口组件；这个弹层完全属于 App：选中一件礼物后点「支持作者」，
/// 返回被送出的礼物（取消则返回 null）。
class GiftSheet {
  const GiftSheet._();

  static Future<Gift?> show(BuildContext context) {
    return showModalBottomSheet<Gift>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext ctx) => const _GiftSheetBody(),
    );
  }
}

class _GiftSheetBody extends StatefulWidget {
  const _GiftSheetBody();

  @override
  State<_GiftSheetBody> createState() => _GiftSheetBodyState();
}

class _GiftSheetBodyState extends State<_GiftSheetBody> {
  Gift? _selected;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Warm.sheet,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 11, bottom: 4),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0x40785A3C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 14),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(l.giftSheetTitle, style: Warm.serif(size: 20)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 0.95,
                children: kMockGifts
                    .map((Gift g) => _tile(l, g))
                    .toList(growable: false),
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _selected == null
                      ? null
                      : () => Navigator.of(context).pop(_selected),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Warm.accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Warm.track,
                    disabledForegroundColor: Warm.muted,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    _selected == null
                        ? l.giftPickFirst
                        : '${l.giftSupportAuthor} · '
                            '${l.giftPrice(_selected!.price)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(AppLocalizations l, Gift g) {
    final bool active = _selected?.id == g.id;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: active ? Warm.accent.withValues(alpha: 0.10) : Warm.card,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selected = g),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: active ? Warm.accent : Warm.hairline,
                width: active ? 1.6 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(g.emoji, style: const TextStyle(fontSize: 30)),
                const SizedBox(height: 6),
                Text(
                  g.nameOf(l),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Warm.sans(size: 13, weight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  l.giftPrice(g.price),
                  style: Warm.sans(size: 12, color: Warm.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
