/// One shop: header, facts, promotions strip, category chips, the product
/// grid, and the floating cart bar.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../sheets/cart_sheets.dart';
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/icons.dart';
import '../widgets/layout.dart';
import '../widgets/photo.dart';
import '../widgets/product_cards.dart';
import '../widgets/states.dart';
import '../widgets/status_tag.dart';

class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key, required this.shopId});

  final String shopId;

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final shop = ref.watch(shopProvider(widget.shopId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: AsyncView<ShopView>(
          value: shop,
          onRetry: () => ref.invalidate(shopProvider(widget.shopId)),
          loading: const SafeArea(child: SkeletonList(count: 5)),
          data: (s) => _body(s),
        ),
      ),
      bottomNavigationBar: _CartBar(shopId: widget.shopId),
    );
  }

  Widget _body(ShopView shop) {
    final tok = yt(context);
    final products = ref.watch(shopProductsProvider(
        (shopId: widget.shopId, categoryId: _category)));

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: tok.isDark ? tok.bg : tok.gradientTop,
            title: Text(shop.name),
            leading: const BackButton(),
          ),
          SliverToBoxAdapter(child: _ShopHeader(shop: shop)),
          if (!shop.isOpen)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    screenPadding, 0, screenPadding, 12),
                child: YCard(
                  color: tok.peach,
                  shadow: false,
                  child: Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 19, color: tok.warn),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          shop.opensLabel == null
                              ? t('shop.closedBannerNoTime')
                              : t('shop.closedBanner',
                                  {'time': shop.opensLabel}),
                          style: TextStyle(fontSize: 13.5, color: tok.text),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CategoryChips(
                selected: _category,
                allowed: shop.categories,
                onSelect: (c) => setState(() => _category = c),
              ),
            ),
          ),
          products.when(
            loading: () => const SliverToBoxAdapter(
                child: SkeletonList(count: 3, height: 180)),
            error: (e, _) => SliverToBoxAdapter(
              child: ErrorStateView(
                onRetry: () => ref.invalidate(shopProductsProvider(
                    (shopId: widget.shopId, categoryId: _category))),
              ),
            ),
            data: (list) {
              if (list.isEmpty) {
                return SliverToBoxAdapter(
                  child: EmptyState(
                    title: t('shop.noProducts'),
                    icon: Icons.inventory_2_rounded,
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                    screenPadding, 0, screenPadding, 120),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _card(list[i], shop),
                    childCount: list.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _card(ProductView p, ShopView shop) {
    final app = ref.watch(appStateProvider);
    final cart = app.state.cart;
    final qty = cart.shopId == shop.id ? app.quantityOf(p.id) : 0;
    return ProductGridCard(
      product: p,
      quantity: qty,
      canOrder: shop.isOpen,
      onTap: () => showProductSheet(
        context,
        ref,
        product: p,
        shopName: shop.name,
        shopOpen: shop.isOpen,
        showShopLink: false,
      ),
      onAdd: () => addProductToCart(context, ref, p, shop.name),
      onQuantity: (v) => app.setQuantity(p.id, v),
    );
  }
}

class _ShopHeader extends StatelessWidget {
  const _ShopHeader({required this.shop});

  final ShopView shop;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);

    Widget fact(IconData icon, String label, String value) => Expanded(
          child: Column(
            children: [
              Icon(icon, size: 19, color: tok.accent),
              const SizedBox(height: 5),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: tok.text,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: tok.hint),
              ),
            ],
          ),
        );

    return Padding(
      padding:
          const EdgeInsets.fromLTRB(screenPadding, 4, screenPadding, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ShopAvatar(
                color: hexColor(shop.logoBg),
                icon: shopIcon(shop.icon),
                photo: shop.photo,
                size: 64,
                dimmed: !shop.isOpen,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shop.name,
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: tok.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      shop.type,
                      style: TextStyle(fontSize: 13.5, color: tok.hint),
                    ),
                    const SizedBox(height: 7),
                    StatusTag(
                      // A 24/7 shop has no closing time to name.
                      label: shop.isOpen
                          ? (shop.hoursLabel.contains('–')
                              ? t('sp.until',
                                  {'time': shop.hoursLabel.split('–').last})
                              : '${t('shop.open')} · ${shop.hoursLabel}')
                          : (shop.opensLabel == null
                              ? t('shop.closed')
                              : t('shop.closedOpens',
                                  {'time': shop.opensLabel})),
                      tone: shop.isOpen ? TagTone.success : TagTone.neutral,
                      icon: shop.isOpen
                          ? Icons.check_circle_rounded
                          : Icons.schedule_rounded,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          YCard(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                fact(Icons.place_rounded, t('shop.distance'),
                    formatKm(shop.distanceKm)),
                if (shop.delivers) ...[
                  fact(Icons.schedule_rounded, t('shop.time'),
                      shop.deliveryTimeText),
                  fact(
                    Icons.delivery_dining_rounded,
                    t('shop.fee'),
                    shop.deliveryFee == 0
                        ? t('shop.free')
                        : formatPrice(shop.deliveryFee),
                  ),
                ] else
                  fact(Icons.storefront_rounded, t('shop.fee'),
                      t('sp.pickupOnly')),
              ],
            ),
          ),
          if (shop.delivers && shop.minOrder > 0) ...[
            const SizedBox(height: 8),
            Text(
              t('sp.min', {'sum': formatPrice(shop.minOrder)}),
              style: TextStyle(fontSize: 13, color: tok.hint),
            ),
          ],
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 15, color: tok.hint),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  shop.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.5, color: tok.hint),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// "Savat · N ta" floating above the safe area while the cart holds goods of
/// this shop.
class _CartBar extends ConsumerWidget {
  const _CartBar({required this.shopId});

  final String shopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    if (cart.shopId != shopId || cart.isEmpty) return const SizedBox.shrink();
    return BottomActionBar(
      child: YButton(
        label: '${t('sp.cartLine', {'n': cart.count})} · '
            '${formatPrice(cart.itemsTotal)}',
        icon: Icons.shopping_cart_rounded,
        onPressed: () => context.go('/cart'),
      ),
    );
  }
}
