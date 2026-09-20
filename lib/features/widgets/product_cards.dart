/// Product cards: the small tile on Home, the promotion card, and the wider
/// card used on a shop page and in search results.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/strings_buyer.dart';
import '../../core/time.dart';
import '../../data/models.dart';
import 'photo.dart';
import 'stepper.dart';

/// `−15%` on a green (or coral) pill.
class DiscountBadge extends StatelessWidget {
  const DiscountBadge({super.key, required this.pct, this.coral = false});

  final int pct;
  final bool coral;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: coral ? tok.badge : tok.accent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '−$pct%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// The price line: promo price in coral with the old price struck through.
class PriceLine extends StatelessWidget {
  const PriceLine({
    super.key,
    required this.price,
    this.regularPrice,
    this.size = 15,
    this.showOld = true,
  });

  final int price;
  final int? regularPrice;
  final double size;
  final bool showOld;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final discounted = regularPrice != null && regularPrice! > price;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            formatPrice(price),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: discounted ? tok.coral : tok.text,
            ),
          ),
        ),
        if (discounted && showOld) ...[
          const SizedBox(width: 6),
          Text(
            formatNumber(regularPrice!),
            style: TextStyle(
              fontSize: size - 2.5,
              color: tok.hint,
              decoration: TextDecoration.lineThrough,
              decorationColor: tok.hint,
            ),
          ),
        ],
      ],
    );
  }
}

/// The small tile in the Home "Mahsulotlar" grid.
class MiniProductCard extends StatelessWidget {
  const MiniProductCard({super.key, required this.hit, this.onTap});

  final ProductHit hit;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final p = hit.product;
    return Material(
      color: tok.surface,
      borderRadius: BorderRadius.circular(YRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(YRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          // No mainAxisSize.min here: the Spacer below needs the full tile.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: ProductPhoto(photo: p.photo, emoji: p.emoji),
                    ),
                    if (p.promo != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: DiscountBadge(pct: p.promo!.discountPct),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.15,
                  color: tok.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                hit.shop.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: tok.hint),
              ),
              const Spacer(),
              Text(
                formatPrice(p.price),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.promo != null ? tok.coral : tok.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The promotion card: bigger photo, coral price, shop and time left.
class PromoCard extends StatelessWidget {
  const PromoCard({
    super.key,
    required this.hit,
    required this.now,
    this.onTap,
    this.width,
  });

  final ProductHit hit;
  final int now;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final p = hit.product;
    return SizedBox(
      width: width,
      child: Material(
        color: tok.surface,
        borderRadius: BorderRadius.circular(YRadius.card),
        child: InkWell(
          borderRadius: BorderRadius.circular(YRadius.card),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: 1.25,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ProductPhoto(photo: p.photo, emoji: p.emoji),
                      ),
                      if (p.promo != null)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: DiscountBadge(
                              pct: p.promo!.discountPct, coral: true),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tok.text,
                  ),
                ),
                const SizedBox(height: 4),
                PriceLine(price: p.price, regularPrice: p.regularPrice),
                const SizedBox(height: 5),
                Text(
                  '${hit.shop.name} · ${formatKm(hit.shop.distanceKm)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: tok.hint),
                ),
                if (p.promo != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 13, color: tok.hint),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          promoTimeLeft(p.promo!.endsAt, now),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11.5, color: tok.hint),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The card used inside a shop page and in the search results: photo on top,
/// name, price and the add control (or the "sold out" note).
class ProductGridCard extends StatelessWidget {
  const ProductGridCard({
    super.key,
    required this.product,
    required this.quantity,
    required this.canOrder,
    this.shopName,
    this.onTap,
    this.onAdd,
    this.onQuantity,
  });

  final ProductView product;
  final int quantity;

  /// False when the shop is closed: the add button becomes a note.
  final bool canOrder;
  final String? shopName;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;
  final ValueChanged<int>? onQuantity;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final p = product;
    return Material(
      color: tok.surface,
      borderRadius: BorderRadius.circular(YRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(YRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.2,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: p.inStock ? 1 : 0.45,
                        child: ProductPhoto(photo: p.photo, emoji: p.emoji),
                      ),
                    ),
                    if (p.promo != null)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: DiscountBadge(pct: p.promo!.discountPct),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                p.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                  color: tok.text,
                ),
              ),
              if (shopName != null) ...[
                const SizedBox(height: 2),
                Text(
                  shopName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: tok.hint),
                ),
              ],
              const Spacer(),
              const SizedBox(height: 6),
              if (!p.inStock)
                Text(
                  t('sp.soldout'),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: tok.hint,
                  ),
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: PriceLine(
                        price: p.price,
                        regularPrice: p.regularPrice,
                        size: 14,
                        showOld: false,
                      ),
                    ),
                    if (!canOrder)
                      Text(
                        t('product.shopClosed'),
                        style: TextStyle(fontSize: 11.5, color: tok.hint),
                      )
                    else if (quantity == 0)
                      AddButton(onTap: onAdd ?? () {})
                    else
                      QtyStepper(
                        quantity: quantity,
                        compact: true,
                        onChanged: onQuantity ?? (_) {},
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
