/// "Buyurtmalar" in shop mode: Yangi · Jarayonda · Yakunlangan, with the
/// action buttons that move an order along.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../core/strings_shop.dart';
import '../core/time.dart';
import '../data/models.dart';
import '../features/orders/orders_page.dart' show callShop;
import '../features/widgets/buttons.dart';
import '../features/widgets/layout.dart';
import '../features/widgets/photo.dart';
import '../features/widgets/states.dart';
import '../features/widgets/status_tag.dart';
import '../features/widgets/toast.dart';
import '../state/providers.dart';
import 'shop_sheets.dart';

class ShopOrdersPage extends ConsumerWidget {
  const ShopOrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final orders = ref.watch(shopOrdersProvider);

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
                child: Text(
                  S.orders.title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: tok.text,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    screenPadding, 0, screenPadding, 10),
                child: Text(
                  S.orders.subtitle,
                  style: TextStyle(fontSize: 14, color: tok.hint),
                ),
              ),
              Expanded(
                child: AsyncView<List<Order>>(
                  value: orders,
                  onRetry: () => ref.invalidate(shopOrdersProvider),
                  data: (all) => _list(context, ref, all),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<Order> all) {
    final tok = yt(context);
    if (all.isEmpty) {
      return EmptyState(
        title: S.orders.emptyTitle,
        text: S.orders.emptyText,
        image: 'assets/img/so-counter.png',
        ctaLabel: S.panel.promoTitle,
        onCta: () => context.push('/shop-promo'),
      );
    }
    const inProgress = [
      OrderStatus.accepted,
      OrderStatus.preparing,
      OrderStatus.onTheWay,
      OrderStatus.ready,
      OrderStatus.confirm,
    ];
    final fresh =
        all.where((o) => o.status == OrderStatus.isNew).toList();
    final progress = all.where((o) => inProgress.contains(o.status)).toList();
    final done = all
        .where((o) =>
            !inProgress.contains(o.status) && o.status != OrderStatus.isNew)
        .toList();

    Widget heading(String text, int count) => Padding(
          padding: const EdgeInsets.fromLTRB(2, 10, 2, 8),
          child: Text(
            '$text · $count',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: tok.hint,
            ),
          ),
        );

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(shopOrdersProvider);
        ref.invalidate(shopStatsProvider);
      },
      child: ListView(
        padding: EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, bottomBarSpace(context)),
        children: [
          if (fresh.isNotEmpty) ...[
            heading(S.orders.fresh, fresh.length),
            for (final o in fresh) ...[
              ShopOrderCard(order: o, highlight: true),
              const SizedBox(height: 10),
            ],
          ],
          if (progress.isNotEmpty) ...[
            heading(S.orders.progress, progress.length),
            for (final o in progress) ...[
              ShopOrderCard(order: o),
              const SizedBox(height: 10),
            ],
          ],
          if (done.isNotEmpty) ...[
            heading(S.orders.done, done.length),
            for (final o in done) ...[
              ShopOrderCard(order: o),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class ShopOrderCard extends ConsumerStatefulWidget {
  const ShopOrderCard({super.key, required this.order, this.highlight = false});

  final Order order;
  final bool highlight;

  @override
  ConsumerState<ShopOrderCard> createState() => _ShopOrderCardState();
}

class _ShopOrderCardState extends ConsumerState<ShopOrderCard> {
  bool _busy = false;

  Future<void> _act(OrderAction action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(shopApiProvider).actOnOrder(widget.order.id, action);
      ref.invalidate(shopOrdersProvider);
      ref.invalidate(shopStatsProvider);
      ref.invalidate(ordersProvider);
      ref.invalidate(orderProvider(widget.order.id));
    } on ApiError catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reject() async {
    final choice = await showRejectSheet(context, widget.order);
    if (choice == null || !mounted) return;
    if (choice == 'availability') {
      await _availability();
      return;
    }
    await _act(RejectAction(choice));
  }

  Future<void> _availability() async {
    final available = await showAvailabilitySheet(context, widget.order);
    if (available == null || !mounted) return;
    await _act(AvailabilityAction(available));
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final order = widget.order;
    final now = DateTime.now().millisecondsSinceEpoch;
    final waited = ((now - order.createdAt) / 60000).floor();

    return YCard(
      borderColor: widget.highlight ? tok.accent : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '#${order.number}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: tok.text,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  order.buyerName ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14.5, color: tok.hint),
                ),
              ),
              if (order.status == OrderStatus.isNew)
                StatusTag(
                  label: S.orders.waitMin(waited),
                  tone: TagTone.warn,
                  small: true,
                )
              else
                StatusTag(
                  label: S.orders.status[order.status.wire] ?? '',
                  tone: orderStatusTone(order.status),
                  small: true,
                ),
            ],
          ),
          const SizedBox(height: 8),
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
                    ? S.orders.delivery
                    : S.orders.pickup,
                style: TextStyle(fontSize: 12.5, color: tok.hint),
              ),
              const SizedBox(width: 10),
              Icon(Icons.payments_rounded, size: 15, color: tok.hint),
              const SizedBox(width: 5),
              Text(
                S.orders.cash,
                style: TextStyle(fontSize: 12.5, color: tok.hint),
              ),
              const Spacer(),
              Text(
                formatOrderTime(order.createdAt, now),
                style: TextStyle(fontSize: 12.5, color: tok.hint),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in order.items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  ProductPhoto(
                      photo: item.photo, emoji: item.emoji, size: 36),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      '${item.quantity} × ${item.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: item.unavailable ? tok.hint : tok.text,
                        decoration: item.unavailable
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    formatPrice(item.price * item.quantity),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: tok.text,
                    ),
                  ),
                ],
              ),
            ),
          if (order.address != null) ...[
            const SizedBox(height: 2),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_rounded, size: 15, color: tok.hint),
                const SizedBox(width: 5),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.address!.oneLine,
                        style: TextStyle(fontSize: 12.5, color: tok.hint),
                      ),
                      if (order.address!.landmark.isNotEmpty)
                        Text(
                          S.orders.landmark(order.address!.landmark),
                          style: TextStyle(fontSize: 12.5, color: tok.hint),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
          if (order.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            YCard(
              color: tok.peach,
              shadow: false,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.chat_bubble_rounded, size: 15, color: tok.warn),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      order.comment,
                      style: TextStyle(fontSize: 13, color: tok.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Divider(height: 1, color: tok.border),
          const SizedBox(height: 10),
          Row(
            children: [
              if (order.deliveryFee > 0) ...[
                Text(
                  '${S.orders.fee} ${formatPrice(order.deliveryFee)}',
                  style: TextStyle(fontSize: 12.5, color: tok.hint),
                ),
                const Spacer(),
              ] else
                const Spacer(),
              Text(
                '${S.orders.total}: ${formatPrice(order.total)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tok.text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _actions(order),
        ],
      ),
    );
  }

  Widget _actions(Order order) {
    final tok = yt(context);
    final call = YButton(
      label: S.orders.call,
      icon: Icons.call_rounded,
      small: true,
      variant: YButtonVariant.grey,
      onPressed: order.buyerPhone == null
          ? null
          : () => callShop(context, order.buyerPhone!),
    );

    switch (order.status) {
      case OrderStatus.isNew:
        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: YButton(
                    label: S.orders.accept,
                    small: true,
                    loading: _busy,
                    onPressed: () => _act(const AcceptAction()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: YButton(
                    label: S.orders.reject,
                    small: true,
                    variant: YButtonVariant.grey,
                    onPressed: _busy ? null : _reject,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: YButton(
                    label: S.orders.missing,
                    small: true,
                    variant: YButtonVariant.mint,
                    onPressed: _busy ? null : _availability,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: call),
              ],
            ),
          ],
        );
      case OrderStatus.accepted:
        return Row(
          children: [
            Expanded(
              child: YButton(
                label: S.orders.pack,
                small: true,
                loading: _busy,
                onPressed: () => _act(const PackAction()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: call),
          ],
        );
      case OrderStatus.preparing:
        return Row(
          children: [
            Expanded(
              child: YButton(
                label: order.fulfilment == Fulfilment.delivery
                    ? S.orders.dispatch
                    : S.orders.ready,
                small: true,
                loading: _busy,
                onPressed: () => _act(const DispatchAction()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: call),
          ],
        );
      case OrderStatus.onTheWay:
      case OrderStatus.ready:
        return Row(
          children: [
            Expanded(
              child: YButton(
                label: order.fulfilment == Fulfilment.delivery
                    ? S.orders.delivered
                    : S.orders.pickedUp,
                small: true,
                loading: _busy,
                onPressed: () => _act(const CompleteAction()),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(child: call),
          ],
        );
      case OrderStatus.confirm:
        return Row(
          children: [
            Icon(Icons.hourglass_top_rounded, size: 16, color: tok.warn),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                S.orders.waitingConfirm,
                style: TextStyle(fontSize: 13, color: tok.warn),
              ),
            ),
          ],
        );
      default:
        if (order.status == OrderStatus.rejected &&
            order.rejectReason != null) {
          return Text(
            S.reject.message(order.shopName, order.rejectReason!),
            style: TextStyle(fontSize: 12.5, color: tok.hint),
          );
        }
        return const SizedBox.shrink();
    }
  }
}
