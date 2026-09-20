/// Shop rows and the round shop tiles on Home.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import 'icons.dart';
import 'photo.dart';
import 'status_tag.dart';

/// A full-width row in "Doʻkonlar".
class ShopRow extends StatelessWidget {
  const ShopRow({super.key, required this.shop, this.onTap});

  final ShopView shop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);

    /// A small icon + label pill, so the facts wrap instead of being cut off.
    Widget fact(IconData icon, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: tok.hint),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: tok.hint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        );

    return Material(
      color: tok.surface,
      borderRadius: BorderRadius.circular(YRadius.card),
      child: InkWell(
        borderRadius: BorderRadius.circular(YRadius.card),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShopAvatar(
                color: hexColor(shop.logoBg),
                icon: shopIcon(shop.icon),
                photo: shop.photo,
                size: 56,
                dimmed: !shop.isOpen,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            shop.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 16.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: tok.text,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusTag(
                          label:
                              shop.isOpen ? t('shop.open') : t('shop.closed'),
                          tone: shop.isOpen ? TagTone.success : TagTone.neutral,
                          small: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${shop.type} · ${formatKm(shop.distanceKm)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: tok.hint),
                    ),
                    if (!shop.isOpen && shop.opensLabel != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        shop.opensLabel!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: tok.warn,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 14,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (shop.delivers)
                          fact(
                            Icons.delivery_dining_rounded,
                            shop.deliveryFee == 0
                                ? t('shop.free')
                                : formatPrice(shop.deliveryFee),
                          )
                        else
                          fact(Icons.storefront_rounded, t('shop.pickupOnly')),
                        if (shop.delivers && shop.deliveryTimeText.isNotEmpty)
                          fact(Icons.schedule_rounded, shop.deliveryTimeText),
                        if (shop.delivers && shop.minOrder > 0)
                          fact(Icons.shopping_basket_rounded,
                              t('sp.min', {'sum': formatPrice(shop.minOrder)})),
                        if (shop.promoCount > 0)
                          StatusTag(
                            label: t('shops.promos', {'n': shop.promoCount}),
                            tone: TagTone.accentSoft,
                            small: true,
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

/// The 48 dp coloured circle with a two-line label used in the Home
/// "Doʻkonlar" strip.
class ShopCircle extends StatelessWidget {
  const ShopCircle({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
    this.photo,
    this.dimmed = false,
    this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final String? photo;
  final bool dimmed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return InkWell(
      borderRadius: BorderRadius.circular(YRadius.card),
      onTap: onTap,
      child: SizedBox(
        width: 78,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ShopAvatar(
                color: color,
                icon: icon,
                photo: photo,
                size: 58,
                dimmed: dimmed,
              ),
              const SizedBox(height: 7),
              Text(
                label,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.2,
                  fontWeight: FontWeight.w500,
                  color: dimmed ? tok.hint : tok.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
