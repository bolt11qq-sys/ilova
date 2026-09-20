/// Cart-related sheets: the product sheet, the "replace the cart?" confirm and
/// the partial-fulfilment confirm.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/strings_buyer.dart';
import '../../core/time.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/providers.dart';
import '../widgets/buttons.dart';
import '../widgets/layout.dart';
import '../widgets/photo.dart';
import '../widgets/product_cards.dart';
import '../widgets/sheet.dart';
import '../widgets/stepper.dart';
import '../widgets/toast.dart';

/// Asks whether the cart of another shop may be thrown away.
Future<bool> confirmReplaceCart(BuildContext context, CartState cart) async {
  final result = await showYSheet<bool>(
    context: context,
    builder: (context) => SheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: t('cf.title'),
            subtitle: t('cf.text', {
              'shop': cart.shopName,
              'n': cart.count,
              'sum': formatPrice(cart.itemsTotal),
            }),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                screenPadding, 4, screenPadding, screenPadding),
            child: Column(
              children: [
                YButton(
                  label: t('cf.yes'),
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 10),
                YButton(
                  label: t('cf.no'),
                  variant: YButtonVariant.grey,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}

/// Adds a product to the cart, asking first when the cart belongs to another
/// shop. Returns true when something was added.
Future<bool> addProductToCart(
  BuildContext context,
  WidgetRef ref,
  ProductView product,
  String shopName, {
  int quantity = 1,
}) async {
  final app = ref.read(appStateProvider);
  var result = app.addToCart(product, shopName, quantity: quantity);
  if (result == AddToCartResult.needsReplace) {
    final ok = await confirmReplaceCart(context, app.state.cart);
    if (!ok) return false;
    result = app.addToCart(product, shopName, quantity: quantity, replace: true);
  }
  return result == AddToCartResult.added;
}

/// The product sheet: photo, price, description, stepper and the add button.
Future<void> showProductSheet(
  BuildContext context,
  WidgetRef ref, {
  required ProductView product,
  required String shopName,
  required bool shopOpen,
  bool showShopLink = true,
}) {
  return showYSheet<void>(
    context: context,
    builder: (context) => _ProductSheet(
      product: product,
      shopName: shopName,
      shopOpen: shopOpen,
      showShopLink: showShopLink,
    ),
  );
}

class _ProductSheet extends ConsumerStatefulWidget {
  const _ProductSheet({
    required this.product,
    required this.shopName,
    required this.shopOpen,
    required this.showShopLink,
  });

  final ProductView product;
  final String shopName;
  final bool shopOpen;
  final bool showShopLink;

  @override
  ConsumerState<_ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends ConsumerState<_ProductSheet> {
  int _qty = 1;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final p = widget.product;
    final canOrder = p.inStock && widget.shopOpen;

    return SheetBody(
      bottom: canOrder
          ? YButton(
              label: t('ps.add', {'sum': formatPrice(p.price * _qty)}),
              onPressed: () async {
                final added = await addProductToCart(
                  context,
                  ref,
                  p,
                  widget.shopName,
                  quantity: _qty,
                );
                if (!context.mounted) return;
                Navigator.of(context).pop();
                if (added) {
                  showToast(context, t('h.inCart', {'n': ref.read(cartCountProvider)}),
                      kind: ToastKind.success);
                }
              },
            )
          : YButton(
              label: p.inStock
                  ? t('product.shopClosed')
                  : t('product.outOfStock'),
              variant: YButtonVariant.grey,
              onPressed: null,
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            child: AspectRatio(
              aspectRatio: 1.6,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductPhoto(
                      photo: p.photo,
                      emoji: p.emoji,
                      radius: YRadius.bigCard,
                      emojiScale: 0.35,
                    ),
                  ),
                  if (p.promo != null)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: DiscountBadge(
                          pct: p.promo!.discountPct, coral: true),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: tok.text,
                  ),
                ),
                const SizedBox(height: 8),
                PriceLine(
                    price: p.price, regularPrice: p.regularPrice, size: 18),
                if (p.promo != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 15, color: tok.coral),
                      const SizedBox(width: 5),
                      Text(
                        t('ps.promoUntil', {
                          'when': promoTimeLeft(
                              p.promo!.endsAt, DateTime.now().millisecondsSinceEpoch),
                        }),
                        style: TextStyle(
                          fontSize: 13,
                          color: tok.coral,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
                if (p.description.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    t('ps.about'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tok.text,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    p.description,
                    style: TextStyle(fontSize: 14.5, color: tok.hint, height: 1.4),
                  ),
                ],
                const SizedBox(height: 16),
                YCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  color: tok.card,
                  shadow: false,
                  onTap: widget.showShopLink
                      ? () {
                          Navigator.of(context).pop();
                          context.push('/shop/${p.shopId}');
                        }
                      : null,
                  child: Row(
                    children: [
                      Icon(Icons.storefront_rounded, size: 20, color: tok.hint),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.shopName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: tok.text,
                          ),
                        ),
                      ),
                      if (widget.showShopLink)
                        Text(
                          t('ps.goShop'),
                          style: TextStyle(
                            fontSize: 13.5,
                            color: tok.accent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (canOrder) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        t('ps.qty'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: tok.text,
                        ),
                      ),
                      QtyStepper(
                        quantity: _qty,
                        min: 1,
                        max: maxLineQuantity,
                        onChanged: (v) => setState(() => _qty = v),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Baʼzi mahsulotlar tugagan" — the buyer accepts the new total or cancels.
class PartialConfirmCard extends ConsumerStatefulWidget {
  const PartialConfirmCard({super.key, required this.order, this.onDone});

  final Order order;
  final VoidCallback? onDone;

  @override
  ConsumerState<PartialConfirmCard> createState() => _PartialConfirmCardState();
}

class _PartialConfirmCardState extends ConsumerState<PartialConfirmCard> {
  bool _busy = false;

  Future<void> _answer(bool accept) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(serverProvider).confirmChanges(widget.order.id, accept);
      if (!mounted) return;
      widget.onDone?.call();
    } on ApiError catch (e) {
      if (!mounted) return;
      showToast(context, e.message, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final changes = widget.order.changes;
    if (changes == null) return const SizedBox.shrink();
    final left = changes.deadline - DateTime.now().millisecondsSinceEpoch;

    return YCard(
      borderColor: tok.warn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_rounded, size: 20, color: tok.warn),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('pc.title'),
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: tok.text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            t('pc.text', {'shop': widget.order.shopName}),
            style: TextStyle(fontSize: 14, color: tok.hint, height: 1.35),
          ),
          const SizedBox(height: 12),
          for (final item in widget.order.items)
            if (item.unavailable)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    ProductPhoto(
                        photo: item.photo, emoji: item.emoji, size: 34),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          color: tok.hint,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                    Text(
                      t('pc.soldout'),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: tok.danger,
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 6),
          TotalRow(
            label: t('pc.old'),
            value: formatPrice(changes.oldTotal),
          ),
          TotalRow(
            label: t('pc.new'),
            value: formatPrice(changes.newTotal),
            strong: true,
            valueColor: tok.accentInk,
          ),
          const SizedBox(height: 10),
          Text(
            t('pc.left', {'t': countdown(left)}),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: tok.warn,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            t('pc.hint'),
            style: TextStyle(fontSize: 12.5, color: tok.hint),
          ),
          const SizedBox(height: 12),
          YButton(
            label: t('pc.confirm', {'sum': formatPrice(changes.newTotal)}),
            loading: _busy,
            onPressed: () => _answer(true),
          ),
          const SizedBox(height: 8),
          YButton(
            label: t('pc.cancel'),
            variant: YButtonVariant.grey,
            onPressed: _busy ? null : () => _answer(false),
          ),
        ],
      ),
    );
  }
}
