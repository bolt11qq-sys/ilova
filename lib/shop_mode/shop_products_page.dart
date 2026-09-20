/// "Mahsulotlar" in shop mode: search, three filters, a one-tap in-stock
/// switch and a price editor.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../core/search.dart';
import '../core/strings_shop.dart';
import '../data/models.dart';
import '../features/widgets/buttons.dart';
import '../features/widgets/chips.dart';
import '../features/widgets/layout.dart';
import '../features/widgets/photo.dart';
import '../features/widgets/states.dart';
import '../features/widgets/status_tag.dart';
import '../features/widgets/toast.dart';
import '../state/providers.dart';
import 'shop_sheets.dart';

enum ProductFilter { all, soldOut, onSale }

class ShopProductsPage extends ConsumerStatefulWidget {
  const ShopProductsPage({super.key});

  @override
  ConsumerState<ShopProductsPage> createState() => _ShopProductsPageState();
}

class _ShopProductsPageState extends ConsumerState<ShopProductsPage> {
  final _query = TextEditingController();
  ProductFilter _filter = ProductFilter.all;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final products = ref.watch(shopProductsOwnProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    screenPadding, 12, screenPadding, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        S.products.title,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          color: tok.text,
                        ),
                      ),
                    ),
                    YButton(
                      label: S.products.add,
                      icon: Icons.add_rounded,
                      small: true,
                      expand: false,
                      onPressed: () => context.push('/shop-add-product'),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    screenPadding, 0, screenPadding, 10),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: S.products.search,
                    prefixIcon: Icon(Icons.search_rounded, color: tok.hint),
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: screenPadding),
                  children: [
                    for (final f in ProductFilter.values) ...[
                      YChip(
                        label: switch (f) {
                          ProductFilter.all => S.products.all,
                          ProductFilter.soldOut => S.products.soldOut,
                          ProductFilter.onSale => S.products.onSale,
                        },
                        selected: _filter == f,
                        onTap: () => setState(() => _filter = f),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: AsyncView<List<ShopProduct>>(
                  value: products,
                  onRetry: () => ref.invalidate(shopProductsOwnProvider),
                  data: (all) => _list(all),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<ShopProduct> all) {
    final tok = yt(context);
    if (all.isEmpty) {
      return EmptyState(
        title: S.products.emptyTitle,
        text: S.products.emptyText,
        image: 'assets/img/so-shelf.png',
        ctaLabel: S.products.fromCatalog,
        onCta: () => context.push('/shop-add-product'),
      );
    }
    final q = _query.text.trim();
    final list = all.where((p) {
      if (q.isNotEmpty && matchScore(q, p.name) == null) return false;
      return switch (_filter) {
        ProductFilter.all => true,
        ProductFilter.soldOut => !p.inStock,
        ProductFilter.onSale => p.promo != null,
      };
    }).toList();

    if (list.isEmpty) {
      return EmptyState(title: S.products.none, icon: Icons.search_off_rounded);
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(shopProductsOwnProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            screenPadding, 0, screenPadding, 110),
        itemCount: list.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${S.products.count(list.length)} · ${S.products.info}',
                style: TextStyle(fontSize: 12.5, color: tok.hint, height: 1.3),
              ),
            );
          }
          return _ProductRow(product: list[i - 1]);
        },
      ),
    );
  }
}

class _ProductRow extends ConsumerStatefulWidget {
  const _ProductRow({required this.product});

  final ShopProduct product;

  @override
  ConsumerState<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends ConsumerState<_ProductRow> {
  bool _busy = false;

  Future<void> _toggleStock() async {
    if (_busy) return;
    setState(() => _busy = true);
    final next = !widget.product.inStock;
    await ref.read(shopApiProvider).setStock(widget.product.id, next);
    ref.invalidate(shopProductsOwnProvider);
    ref.invalidate(shopStatsProvider);
    invalidateAll(ref);
    if (!mounted) return;
    setState(() => _busy = false);
    showToast(
      context,
      next
          ? S.products.nowHave(widget.product.name)
          : S.products.nowGone(widget.product.name),
      kind: next ? ToastKind.success : ToastKind.info,
    );
  }

  Future<void> _editPrice() async {
    final value =
        await showPriceSheet(context, widget.product.name, widget.product.price);
    if (value == null || !mounted) return;
    await ref.read(shopApiProvider).setPrice(widget.product.id, value);
    ref.invalidate(shopProductsOwnProvider);
    invalidateAll(ref);
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final p = widget.product;
    return YCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Opacity(
            opacity: p.inStock ? 1 : 0.5,
            child: ProductPhoto(photo: p.photo, emoji: p.emoji, size: 48),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: p.inStock ? tok.text : tok.hint,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    GestureDetector(
                      onTap: _editPrice,
                      child: Row(
                        children: [
                          Text(
                            formatPrice(p.promo?.price ?? p.price),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: p.promo != null ? tok.coral : tok.text,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.edit_rounded, size: 13, color: tok.hint),
                        ],
                      ),
                    ),
                    if (p.promo != null) ...[
                      const SizedBox(width: 8),
                      StatusTag(
                        label: '−${p.promo!.pct}%',
                        tone: TagTone.accentSoft,
                        small: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          YButton(
            label: p.inStock ? S.products.have : S.products.gone,
            small: true,
            expand: false,
            loading: _busy,
            variant: p.inStock ? YButtonVariant.mint : YButtonVariant.grey,
            onPressed: _toggleStock,
          ),
        ],
      ),
    );
  }
}
