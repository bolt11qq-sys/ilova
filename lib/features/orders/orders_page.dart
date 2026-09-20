/// "Buyurtmalar": status tabs, a sort choice, and the "Faol" / "Oldingilar"
/// sections.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/strings_buyer.dart';
import '../../core/time.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../home/home_page.dart' show repeatOrder;
import '../widgets/buttons.dart';
import '../widgets/chips.dart';
import '../widgets/layout.dart';
import '../widgets/photo.dart';
import '../widgets/sheet.dart';
import '../widgets/states.dart';
import '../widgets/status_tag.dart';
import '../widgets/toast.dart';

enum OrdersTab { all, done, active, closed }

enum OrdersSort { newest, oldest, priciest }

/// Opens the dialer. Nothing is sent anywhere.
Future<void> callShop(BuildContext context, String phone) async {
  final uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
  final ok = await launchUrl(uri);
  if (!ok && context.mounted) {
    showToast(context, t('common.errorTitle'), kind: ToastKind.error);
  }
}

class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  OrdersTab _tab = OrdersTab.all;
  OrdersSort _sort = OrdersSort.newest;

  bool _matches(Order o) => switch (_tab) {
        OrdersTab.all => true,
        OrdersTab.done => o.status == OrderStatus.completed,
        OrdersTab.active => o.isActive,
        OrdersTab.closed => o.status == OrderStatus.cancelled ||
            o.status == OrderStatus.rejected ||
            o.status == OrderStatus.expired,
      };

  List<Order> _sorted(List<Order> list) {
    final out = List<Order>.from(list);
    switch (_sort) {
      case OrdersSort.newest:
        out.sort((a, b) => b.createdAt - a.createdAt);
      case OrdersSort.oldest:
        out.sort((a, b) => a.createdAt - b.createdAt);
      case OrdersSort.priciest:
        out.sort((a, b) => b.total - a.total);
    }
    return out;
  }

  String get _sortLabel => switch (_sort) {
        OrdersSort.newest => t('orders.sort.newest'),
        OrdersSort.oldest => t('orders.sort.oldest'),
        OrdersSort.priciest => t('orders.sort.priciest'),
      };

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final orders = ref.watch(ordersProvider);

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
                    screenPadding, 12, screenPadding, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        t('od.title'),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: tok.text,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.swap_vert_rounded, size: 19),
                      label: Text(_sortLabel,
                          style: const TextStyle(fontSize: 13.5)),
                      onPressed: () async {
                        final picked = await showChoiceSheet<OrdersSort>(
                          context,
                          title: t('orders.sortTitle'),
                          selected: _sort,
                          options: [
                            ChoiceOption(
                                OrdersSort.newest, t('orders.sort.newest')),
                            ChoiceOption(
                                OrdersSort.oldest, t('orders.sort.oldest')),
                            ChoiceOption(OrdersSort.priciest,
                                t('orders.sort.priciest')),
                          ],
                        );
                        if (picked != null) setState(() => _sort = picked);
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: screenPadding),
                  children: [
                    for (final tab in OrdersTab.values) ...[
                      YChip(
                        label: switch (tab) {
                          OrdersTab.all => t('orders.tab.all'),
                          OrdersTab.done => t('orders.tab.done'),
                          OrdersTab.active => t('orders.tab.active'),
                          OrdersTab.closed => t('orders.tab.closed'),
                        },
                        selected: _tab == tab,
                        onTap: () => setState(() => _tab = tab),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AsyncView<List<Order>>(
                  value: orders,
                  onRetry: () => ref.invalidate(ordersProvider),
                  data: (all) => _list(all),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<Order> all) {
    final tok = yt(context);
    if (all.isEmpty) {
      return EmptyState(
        title: t('od.emptyTitle'),
        text: t('od.emptyText'),
        image: 'assets/img/empty-orders.png',
        ctaLabel: t('od.emptyCta'),
        onCta: () => context.go('/shops'),
      );
    }
    final filtered = _sorted(all.where(_matches).toList());
    if (filtered.isEmpty) {
      return EmptyState(
        title: t('orders.emptyFiltered'),
        icon: Icons.inbox_rounded,
      );
    }
    final active = filtered.where((o) => o.isActive).toList();
    final past = filtered.where((o) => !o.isActive).toList();

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: tok.hint,
            ),
          ),
        );

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(ordersProvider),
      child: ListView(
        padding: EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, bottomBarSpace(context)),
        children: [
          if (active.isNotEmpty) ...[
            heading(t('od.active')),
            for (final o in active) ...[
              OrderCard(order: o),
              const SizedBox(height: 10),
            ],
          ],
          if (past.isNotEmpty) ...[
            heading(t('od.previous')),
            for (final o in past) ...[
              OrderCard(order: o),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class OrderCard extends ConsumerWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final now = DateTime.now().millisecondsSinceEpoch;
    final visible = order.items.take(2).toList();
    final more = order.items.length - visible.length;

    return YCard(
      onTap: () => context.push('/orders/${order.id}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 38,
                width: 38,
                decoration: BoxDecoration(
                  color: hexColor(order.shopLogoBg),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(order.shopEmoji,
                      style: const TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.shopName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: tok.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '#${order.number} · ${formatOrderTime(order.createdAt, now)}',
                      style: TextStyle(fontSize: 12.5, color: tok.hint),
                    ),
                  ],
                ),
              ),
              StatusTag(
                label: orderStatusLabel(order.status, order.fulfilment),
                tone: orderStatusTone(order.status),
                small: true,
              ),
            ],
          ),
          if (order.isActive) ...[
            const SizedBox(height: 10),
            OrderProgress(status: order.status),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              for (final item in visible) ...[
                ProductPhoto(photo: item.photo, emoji: item.emoji, size: 40),
                const SizedBox(width: 7),
              ],
              Expanded(
                child: Text(
                  [
                    order.items.map((i) => i.name).take(2).join(', '),
                    if (more > 0) t('orders.more', {'n': more}),
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.25,
                    color: tok.hint,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                order.fulfilment == Fulfilment.delivery
                    ? Icons.delivery_dining_rounded
                    : Icons.storefront_rounded,
                size: 15,
                color: tok.hint,
              ),
              const SizedBox(width: 5),
              Text(
                order.fulfilment == Fulfilment.delivery
                    ? t('cart.delivery')
                    : t('orders.pickup'),
                style: TextStyle(fontSize: 12.5, color: tok.hint),
              ),
              const Spacer(),
              Text(
                formatPrice(order.total),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tok.text,
                ),
              ),
            ],
          ),
          if (order.status == OrderStatus.rejected &&
              order.rejectReason != null) ...[
            const SizedBox(height: 6),
            Text(
              t('orders.reason', {'reason': order.rejectReason}),
              style: TextStyle(fontSize: 12.5, color: tok.danger),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              if (order.isActive)
                Expanded(
                  child: YButton(
                    label: t('orders.callShop'),
                    icon: Icons.call_rounded,
                    small: true,
                    variant: YButtonVariant.grey,
                    onPressed: () => callShop(context, order.shopPhone),
                  ),
                ),
              if (order.status == OrderStatus.isNew) ...[
                const SizedBox(width: 8),
                Expanded(
                  child: YButton(
                    label: t('orders.cancel'),
                    small: true,
                    variant: YButtonVariant.grey,
                    onPressed: () => _cancel(context, ref),
                  ),
                ),
              ],
              if (order.status == OrderStatus.completed)
                Expanded(
                  child: YButton(
                    label: t('od.repeat'),
                    icon: Icons.refresh_rounded,
                    small: true,
                    variant: YButtonVariant.mint,
                    onPressed: () => repeatOrder(context, ref, order),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmSheet(
      context,
      title: t('orders.cancelTitle'),
      text: t('orders.cancelText', {'n': order.number}),
      yesLabel: t('orders.cancelYes'),
      noLabel: t('orders.cancelNo'),
      danger: true,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(serverProvider).cancelOrder(order.id);
      ref.invalidate(ordersProvider);
      ref.invalidate(orderProvider(order.id));
      if (context.mounted) {
        showToast(context, t('orders.cancelled'), kind: ToastKind.success);
      }
    } on ApiError catch (e) {
      if (context.mounted) {
        showToast(context, e.message, kind: ToastKind.error);
      }
    }
  }
}
