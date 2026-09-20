/// "Aksiya qoʻshish": pick a product, set a lower price, choose how long it
/// runs, see what the buyer will see, publish.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../core/strings_shop.dart';
import '../core/time.dart';
import '../data/mock_shop_api.dart';
import '../data/models.dart';
import '../features/widgets/buttons.dart';
import '../features/widgets/layout.dart';
import '../features/widgets/photo.dart';
import '../features/widgets/product_cards.dart';
import '../features/widgets/sheet.dart';
import '../features/widgets/states.dart';
import '../features/widgets/toast.dart';
import '../state/providers.dart';

class ShopPromoPage extends ConsumerStatefulWidget {
  const ShopPromoPage({super.key});

  @override
  ConsumerState<ShopPromoPage> createState() => _ShopPromoPageState();
}

class _ShopPromoPageState extends ConsumerState<ShopPromoPage> {
  ShopProduct? _product;
  final _price = TextEditingController();
  PromoDuration _duration = PromoDuration.today;
  int? _customEnd;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  int get _promoPrice =>
      int.tryParse(_price.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  int get _endsAt =>
      _customEnd ?? ref.read(shopApiProvider).promoEnd(_duration);

  Future<void> _pick(List<ShopProduct> products) async {
    final chosen = await showChoiceSheet<String>(
      context,
      title: S.promo.chooseProduct,
      selected: _product?.id,
      options: [
        for (final p in products.where((p) => p.inStock))
          ChoiceOption(p.id, p.name, subtitle: formatPrice(p.price)),
      ],
    );
    if (chosen == null) return;
    setState(() {
      _product = products.firstWhere((p) => p.id == chosen);
      _price.text = '${(_product!.price * 0.85).round()}';
      _error = null;
    });
  }

  Future<void> _publish() async {
    final product = _product;
    if (product == null) return;
    if (_promoPrice <= 0 || _promoPrice >= product.price) {
      setState(() => _error = S.promo.invalid);
      return;
    }
    setState(() => _busy = true);
    try {
      await ref
          .read(shopApiProvider)
          .createPromo(product.id, _promoPrice, _endsAt);
      ref.invalidate(shopProductsOwnProvider);
      ref.invalidate(shopStatsProvider);
      invalidateAll(ref);
      if (!mounted) return;
      showToast(context, S.promo.published, kind: ToastKind.success);
      Navigator.of(context).maybePop();
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.message;
      });
    }
  }

  Future<void> _end(ShopProduct product) async {
    await ref.read(shopApiProvider).endPromo(product.id);
    ref.invalidate(shopProductsOwnProvider);
    invalidateAll(ref);
    if (!mounted) return;
    showToast(context, S.promo.end, kind: ToastKind.info);
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(shopProductsOwnProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppBar(title: Text(S.promo.title)),
              Expanded(
                child: AsyncView<List<ShopProduct>>(
                  value: products,
                  onRetry: () => ref.invalidate(shopProductsOwnProvider),
                  data: (list) => list.isEmpty
                      ? EmptyState(
                          title: S.promo.noProducts,
                          icon: Icons.local_offer_rounded,
                        )
                      : _form(list),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _product == null
          ? null
          : BottomActionBar(
              note: Text(
                S.promo.live,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: yt(context).hint),
              ),
              child: YButton(
                label: S.promo.publish,
                loading: _busy,
                onPressed: _publish,
              ),
            ),
    );
  }

  Widget _form(List<ShopProduct> products) {
    final tok = yt(context);
    final product = _product;
    final active = products.where((p) => p.promo != null).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(screenPadding, 4, screenPadding, 30),
      children: [
        Text(S.promo.product,
            style: TextStyle(fontSize: 13.5, color: tok.hint)),
        const SizedBox(height: 6),
        YCard(
          onTap: () => _pick(products),
          child: Row(
            children: [
              if (product == null)
                Icon(Icons.add_shopping_cart_rounded,
                    size: 22, color: tok.hint)
              else
                ProductPhoto(
                    photo: product.photo, emoji: product.emoji, size: 44),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product?.name ?? S.promo.chooseProduct,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: tok.text,
                      ),
                    ),
                    if (product != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        S.promo.regular(formatPrice(product.price)),
                        style: TextStyle(fontSize: 12.5, color: tok.hint),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                product == null ? '' : S.promo.change,
                style: TextStyle(
                  fontSize: 13,
                  color: tok.accent,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (product != null) ...[
          const SizedBox(height: 16),
          Text(S.promo.price,
              style: TextStyle(fontSize: 13.5, color: tok.hint)),
          const SizedBox(height: 6),
          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              suffixText: S.common.som,
              errorText: _error,
            ),
            onChanged: (_) => setState(() => _error = null),
          ),
          if (_promoPrice > 0 && _promoPrice < product.price) ...[
            const SizedBox(height: 8),
            Text(
              S.promo.discount(
                formatPrice(product.price - _promoPrice),
                discountPct(product.price, _promoPrice),
              ),
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: tok.accentInk,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Text(S.promo.duration,
              style: TextStyle(fontSize: 13.5, color: tok.hint)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final d in PromoDuration.values)
                ChoiceChip(
                  label: Text(switch (d) {
                    PromoDuration.today => S.promo.today,
                    PromoDuration.threeDays => S.promo.d3,
                    PromoDuration.oneWeek => S.promo.w1,
                  }),
                  selected: _customEnd == null && _duration == d,
                  onSelected: (_) => setState(() {
                    _duration = d;
                    _customEnd = null;
                  }),
                ),
              ChoiceChip(
                label: Text(S.promo.pick),
                selected: _customEnd != null,
                onSelected: (_) => _pickDate(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _customEnd != null || _duration != PromoDuration.today
                ? S.promo.endsOn(longDate(_endsAt))
                : S.promo.endsToday(hhmm(_endsAt)),
            style: TextStyle(fontSize: 12.5, color: tok.hint),
          ),
          const SizedBox(height: 20),
          Text(
            S.promo.preview,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: tok.text,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: SizedBox(
              width: 180,
              child: PromoCard(
                now: DateTime.now().millisecondsSinceEpoch,
                hit: ProductHit(
                  ProductView(
                    id: product.id,
                    shopId: '',
                    name: product.name,
                    unit: product.unit,
                    categoryId: product.categoryId,
                    emoji: product.emoji,
                    description: '',
                    inStock: true,
                    photo: product.photo,
                    regularPrice: product.price,
                    price: _promoPrice > 0 ? _promoPrice : product.price,
                    promo: _promoPrice > 0 && _promoPrice < product.price
                        ? PromoInfo(
                            promoPrice: _promoPrice,
                            regularPrice: product.price,
                            discountPct:
                                discountPct(product.price, _promoPrice),
                            endsAt: _endsAt,
                          )
                        : null,
                  ),
                  ShopSummary('', '', 0, true),
                ),
              ),
            ),
          ),
        ],
        if (active.isNotEmpty) ...[
          const SizedBox(height: 26),
          Text(
            S.panel.promosLabel,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: tok.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            S.promo.endHint,
            style: TextStyle(fontSize: 12.5, color: tok.hint, height: 1.3),
          ),
          const SizedBox(height: 10),
          for (final p in active)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: YCard(
                padding: const EdgeInsets.all(10),
                child: Row(
                  children: [
                    ProductPhoto(photo: p.photo, emoji: p.emoji, size: 40),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tok.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatPrice(p.promo!.price)} · '
                            '${promoTimeLeft(p.promo!.endsAt, DateTime.now().millisecondsSinceEpoch)}',
                            style: TextStyle(fontSize: 12, color: tok.hint),
                          ),
                        ],
                      ),
                    ),
                    YButton(
                      label: S.promo.end,
                      small: true,
                      expand: false,
                      variant: YButtonVariant.grey,
                      onPressed: () => _end(p),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      initialDate: now.add(const Duration(days: 3)),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _customEnd = DateTime(picked.year, picked.month, picked.day, 23)
          .millisecondsSinceEpoch;
    });
  }
}
