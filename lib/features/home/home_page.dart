/// Home — the screen the reference `newhome.png` shows.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import '../../data/seed.dart';
import '../../state/providers.dart';
import '../sheets/address_sheet.dart';
import '../sheets/cart_sheets.dart';
import '../widgets/buttons.dart';
import '../widgets/icons.dart';
import '../widgets/layout.dart';
import '../widgets/photo.dart';
import '../widgets/product_cards.dart';
import '../widgets/sheet.dart';
import '../widgets/shop_widgets.dart';
import '../widgets/states.dart';
import '../widgets/status_tag.dart';
import '../widgets/toast.dart';
import 'banner_carousel.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inArea = ref.watch(inServiceAreaProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async => invalidateAll(ref),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _Header()),
                if (!inArea)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _OutsideArea(),
                  )
                else ...[
                  const SliverToBoxAdapter(child: _ActiveOrders()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: BannerCarousel(onTap: (route) => context.push(route)),
                    ),
                  ),
                  const SliverToBoxAdapter(child: _ShopsStrip()),
                  const SliverToBoxAdapter(child: _PopularGrid()),
                  const SliverToBoxAdapter(child: _PromotionsStrip()),
                  const SliverToBoxAdapter(child: _RepeatCard()),
                  SliverToBoxAdapter(child: SizedBox(height: bottomBarSpace(context))),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final address = ref.watch(activeAddressProvider);
    return Padding(
      padding: const EdgeInsets.fromLTRB(screenPadding, 8, screenPadding, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t('h.hello'),
            style: TextStyle(fontSize: 15, color: tok.hint),
          ),
          const SizedBox(height: 2),
          Text(
            t('h.title'),
            style: TextStyle(
              fontSize: 23,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: tok.text,
            ),
          ),
          const SizedBox(height: 10),
          InkWell(
            borderRadius: BorderRadius.circular(YRadius.smallButton),
            onTap: () => showAddressSheet(context, ref),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.place_rounded, size: 19, color: tok.accent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      address?.oneLine ?? t('home.noAddress'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        color: tok.hint,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.expand_more_rounded, size: 20, color: tok.hint),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _SearchBox(),
        ],
      ),
    );
  }
}

class _SearchBox extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: tok.surface,
        borderRadius: BorderRadius.circular(YRadius.bigCard),
        boxShadow: tok.shadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(YRadius.bigCard),
              onTap: () => context.push('/search'),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Icon(Icons.search_rounded, size: 22, color: tok.hint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t('h.search'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 15, color: tok.hint),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: t('home.filter'),
            icon: Icon(Icons.tune_rounded, size: 22, color: tok.text),
            onPressed: () async {
              final picked = await showChoiceSheet<String>(
                context,
                title: t('h.cats'),
                options: [
                  for (final c in categories)
                    ChoiceOption(c.id, c.name, icon: categoryIcon(c.id)),
                ],
              );
              if (picked != null && context.mounted) {
                context.push('/category/$picked');
              }
            },
          ),
        ],
      ),
    );
  }
}

class _OutsideArea extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmptyState(
      title: t('out.title'),
      text: t('out.text'),
      image: 'assets/img/outside.png',
      ctaLabel: t('out.pick'),
      onCta: () => showAddressSheet(context, ref),
    );
  }
}

/// The live-order card: accent border, pulsing icon, four-segment progress.
class _ActiveOrders extends ConsumerWidget {
  const _ActiveOrders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final orders = ref.watch(ordersProvider).valueOrNull ?? const <Order>[];
    final active = orders.where((o) => o.isActive).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    final first = active.first;

    return Padding(
      padding: const EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, 12),
      child: YCard(
        borderColor: tok.accent,
        onTap: () => context.push('/orders/${first.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Pulse(color: tok.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${t('h.activeOrder', {'n': first.number})} · '
                    '${orderStatusLabel(first.status, first.fulfilment)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tok.text,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, size: 21, color: tok.hint),
              ],
            ),
            const SizedBox(height: 10),
            OrderProgress(status: first.status),
            if (active.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                t('h.moreOrders', {'n': active.length - 1}),
                style: TextStyle(fontSize: 12.5, color: tok.hint),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.color});

  final Color color;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: widget.color.withAlpha((40 + 60 * _c.value).round()),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.local_shipping_rounded,
            size: 18, color: widget.color),
      ),
    );
  }
}

class _ShopsStrip extends ConsumerWidget {
  const _ShopsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shops = ref.watch(shopsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: sectionGap),
        SectionHeader(
          title: t('h.shopsTitle'),
          action: t('home.seeAll'),
          onAction: () => context.go('/shops'),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 110,
          child: shops.when(
            loading: () => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: screenPadding),
              children: const [
                _CircleSkeleton(),
                _CircleSkeleton(),
                _CircleSkeleton(),
                _CircleSkeleton(),
              ],
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: screenPadding),
              child: Text(t('home.noShops'),
                  style: TextStyle(color: yt(context).hint)),
            ),
            data: (list) {
              if (list.isEmpty) {
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: screenPadding),
                  child: Text(t('home.noShops'),
                      style: TextStyle(color: yt(context).hint)),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: screenPadding - 2),
                itemCount: list.length + 1,
                itemBuilder: (context, i) {
                  if (i == list.length) {
                    return ShopCircle(
                      label: t('h.catOther'),
                      color: yt(context).card,
                      icon: Icons.grid_view_rounded,
                      onTap: () => context.go('/shops'),
                    );
                  }
                  final s = list[i];
                  return ShopCircle(
                    label: s.name,
                    color: hexColor(s.logoBg),
                    icon: shopIcon(s.icon),
                    photo: s.photo,
                    dimmed: !s.isOpen,
                    onTap: () => context.push('/shop/${s.id}'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CircleSkeleton extends StatelessWidget {
  const _CircleSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Column(
        children: [
          Skeleton(height: 58, width: 58, radius: 29),
          SizedBox(height: 8),
          Skeleton(height: 10, width: 56),
        ],
      ),
    );
  }
}

class _PopularGrid extends ConsumerWidget {
  const _PopularGrid();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final popular = ref.watch(popularProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: sectionGap),
        SectionHeader(
          title: t('h.products'),
          action: t('h.allProducts'),
          onAction: () => context.go('/shops'),
        ),
        const SizedBox(height: 8),
        popular.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(horizontal: screenPadding),
            child: Skeleton(height: 190, radius: YRadius.card),
          ),
          error: (e, _) => const SizedBox.shrink(),
          data: (hits) {
            if (hits.isEmpty) return const SizedBox.shrink();
            // Three per row: four made the cards too small to read.
            final shown = hits.length > 6 ? hits.sublist(0, 6) : hits;
            return GridView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: screenPadding),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.66,
              ),
              itemCount: shown.length,
              itemBuilder: (context, i) => MiniProductCard(
                hit: shown[i],
                onTap: () => showProductSheet(
                  context,
                  ref,
                  product: shown[i].product,
                  shopName: shown[i].shop.name,
                  shopOpen: shown[i].shop.isOpen,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _PromotionsStrip extends ConsumerWidget {
  const _PromotionsStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promos = ref.watch(homePromotionsProvider).valueOrNull;
    if (promos == null || promos.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now().millisecondsSinceEpoch;
    final shown = promos.length > 8 ? promos.sublist(0, 8) : promos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: sectionGap),
        SectionHeader(
          title: t('home.todayPromos'),
          action: t('home.seeAll'),
          onAction: () => context.push('/promotions'),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 244,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            itemCount: shown.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => PromoCard(
              hit: shown[i],
              now: now,
              width: 164,
              onTap: () => showProductSheet(
                context,
                ref,
                product: shown[i].product,
                shopName: shown[i].shop.name,
                shopOpen: shown[i].shop.isOpen,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// "Yana shuni buyurtma qilasizmi?" — only when the last order is finished and
/// nothing is running.
class _RepeatCard extends ConsumerWidget {
  const _RepeatCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final orders = ref.watch(ordersProvider).valueOrNull ?? const <Order>[];
    if (orders.any((o) => o.isActive)) return const SizedBox.shrink();
    Order? last;
    for (final o in orders) {
      if (o.status == OrderStatus.completed) {
        last = o;
        break;
      }
    }
    if (last == null) return const SizedBox.shrink();
    final order = last;
    final names = order.items.map((i) => i.name).take(2).join(', ');

    return Padding(
      padding: const EdgeInsets.fromLTRB(screenPadding, 20, screenPadding, 0),
      child: YCard(
        color: tok.mint,
        shadow: false,
        child: Row(
          children: [
            ProductPhoto(
              photo: order.items.first.photo,
              emoji: order.items.first.emoji,
              size: 52,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('h.repeatTitle'),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: tok.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    t('h.repeatSub', {'shop': order.shopName, 'items': names}),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12.5, color: tok.hint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            YButton(
              label: t('h.repeatCta'),
              small: true,
              expand: false,
              onPressed: () => repeatOrder(context, ref, order),
            ),
          ],
        ),
      ),
    );
  }
}

/// Puts a completed order's still-available goods back into the cart.
Future<void> repeatOrder(
    BuildContext context, WidgetRef ref, Order order) async {
  final server = ref.read(serverProvider);
  final current =
      await server.getProducts(order.items.map((i) => i.productId).toList());
  if (!context.mounted) return;
  final result = ref.read(appStateProvider).repeatOrder(order, current);
  if (result.added == 0) {
    showToast(context, t('orders.repeatNone'), kind: ToastKind.error);
    return;
  }
  showToast(
    context,
    result.missing == 0
        ? t('orders.repeated', {'n': result.added})
        : t('orders.repeatedPartial',
            {'n': result.added, 'm': result.missing}),
    kind: ToastKind.success,
  );
  context.go('/cart');
}
