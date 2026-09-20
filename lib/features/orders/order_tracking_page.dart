/// "Buyurtma kuzatuvi": the status headline, the four-step tracker, the ETA,
/// the shop, the address, the goods and the totals.
///
/// The page refreshes itself every second so the partial-fulfilment countdown
/// and the demo timeline stay live while it is open.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/strings_buyer.dart';
import '../../core/time.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../sheets/cart_sheets.dart';
import '../sheets/support_sheet.dart';
import '../widgets/buttons.dart';
import '../widgets/layout.dart';
import '../widgets/photo.dart';
import '../widgets/sheet.dart';
import '../widgets/states.dart';
import '../widgets/status_tag.dart';
import '../widgets/toast.dart';
import 'orders_page.dart' show callShop;

class OrderTrackingPage extends ConsumerStatefulWidget {
  const OrderTrackingPage({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderTrackingPage> createState() => _OrderTrackingPageState();
}

class _OrderTrackingPageState extends ConsumerState<OrderTrackingPage> {
  Timer? _tick;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _seconds++);
      // The demo timeline moves in 10–80 s steps; re-read every 3 s.
      if (_seconds % 3 == 0) {
        ref.invalidate(orderProvider(widget.orderId));
        ref.invalidate(ordersProvider);
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = ref.watch(orderProvider(widget.orderId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: AsyncView<Order>(
            value: order,
            onRetry: () => ref.invalidate(orderProvider(widget.orderId)),
            loading: const SkeletonList(count: 4),
            data: (o) => _body(o),
          ),
        ),
      ),
    );
  }

  Widget _body(Order order) {
    final tok = yt(context);
    final headline = _headline(order);

    return Column(
      children: [
        AppBar(
          title: Text(t('ot.title', {'n': order.number})),
          actions: [
            TextButton(
              onPressed: () => showSupportSheet(context),
              child: Text(t('ot.help')),
            ),
          ],
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                screenPadding, 4, screenPadding, 40),
            children: [
              YCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            headline.$1,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                              color: tok.text,
                            ),
                          ),
                        ),
                        StatusTag(
                          label:
                              orderStatusLabel(order.status, order.fulfilment),
                          tone: orderStatusTone(order.status),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      headline.$2,
                      style:
                          TextStyle(fontSize: 14.5, color: tok.hint, height: 1.35),
                    ),
                    if (order.status == OrderStatus.rejected &&
                        order.rejectReason != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        t('orders.reason', {'reason': order.rejectReason}),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: tok.danger,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    OrderProgress(status: order.status, height: 6),
                    const SizedBox(height: 12),
                    _Steps(order: order),
                    if (order.etaAt != null &&
                        order.fulfilment == Fulfilment.delivery &&
                        order.isActive) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded,
                              size: 17, color: tok.accent),
                          const SizedBox(width: 6),
                          Text(
                            t('od.eta', {
                              'a': hhmm(order.etaAt! - 10 * 60000),
                              'b': hhmm(order.etaAt!),
                            }),
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: tok.accentInk,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (order.status == OrderStatus.confirm) ...[
                const SizedBox(height: 12),
                PartialConfirmCard(
                  order: order,
                  onDone: () {
                    ref.invalidate(orderProvider(widget.orderId));
                    ref.invalidate(ordersProvider);
                  },
                ),
              ],
              const SizedBox(height: 12),
              YCard(
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: hexColor(order.shopLogoBg),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(order.shopEmoji,
                            style: const TextStyle(fontSize: 21)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.shopName,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: tok.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.fulfilment == Fulfilment.delivery
                                ? t('ot.deliverBy')
                                : t('ot.pickupAt'),
                            style: TextStyle(fontSize: 12.5, color: tok.hint),
                          ),
                        ],
                      ),
                    ),
                    YButton(
                      label: t('ot.call'),
                      icon: Icons.call_rounded,
                      small: true,
                      expand: false,
                      variant: YButtonVariant.mint,
                      onPressed: () => callShop(context, order.shopPhone),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              YCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      order.fulfilment == Fulfilment.delivery
                          ? Icons.place_rounded
                          : Icons.store_mall_directory_rounded,
                      size: 20,
                      color: tok.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.fulfilment == Fulfilment.delivery
                                ? t('ot.address')
                                : t('trk.pickupWhere'),
                            style: TextStyle(fontSize: 12.5, color: tok.hint),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.fulfilment == Fulfilment.delivery
                                ? (order.address?.oneLine ?? '—')
                                : order.shopAddress,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: tok.text,
                            ),
                          ),
                          if (order.fulfilment == Fulfilment.delivery &&
                              (order.address?.landmark ?? '').isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              t('sv.landmark', {'v': order.address!.landmark}),
                              style:
                                  TextStyle(fontSize: 12.5, color: tok.hint),
                            ),
                          ],
                          if (order.comment.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              order.comment,
                              style: TextStyle(
                                  fontSize: 13, color: tok.hint, height: 1.3),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              YCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('ot.items'),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: tok.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    for (final item in order.items) ...[
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            ProductPhoto(
                                photo: item.photo, emoji: item.emoji, size: 42),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14.5,
                                      fontWeight: FontWeight.w600,
                                      color: item.unavailable
                                          ? tok.hint
                                          : tok.text,
                                      decoration: item.unavailable
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${item.quantity} × ${formatPrice(item.price)}',
                                    style: TextStyle(
                                        fontSize: 12.5, color: tok.hint),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              formatPrice(item.price * item.quantity),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: tok.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Divider(height: 10, color: tok.border),
                    const SizedBox(height: 6),
                    TotalRow(
                      label: t('sv.items'),
                      value: formatPrice(order.itemsTotal),
                    ),
                    if (order.fulfilment == Fulfilment.delivery)
                      TotalRow(
                        label: t('sv.fee'),
                        value: order.deliveryFee == 0
                            ? t('sv.free')
                            : formatPrice(order.deliveryFee),
                      ),
                    TotalRow(
                      label: t('sv.total'),
                      value: formatPrice(order.total),
                      strong: true,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.payments_rounded, size: 16, color: tok.hint),
                        const SizedBox(width: 6),
                        Text(
                          order.fulfilment == Fulfilment.delivery
                              ? t('ot.cashDelivery')
                              : t('ot.cashPickup'),
                          style: TextStyle(fontSize: 12.5, color: tok.hint),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (order.status == OrderStatus.isNew)
                YButton(
                  label: t('orders.cancel'),
                  variant: YButtonVariant.grey,
                  onPressed: () => _cancel(order),
                ),
              if (order.status == OrderStatus.completed)
                YButton(
                  label: t('od.repeat'),
                  icon: Icons.refresh_rounded,
                  variant: YButtonVariant.mint,
                  onPressed: () => repeatOrderFromTracking(context, ref, order),
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _cancel(Order order) async {
    final ok = await showConfirmSheet(
      context,
      title: t('orders.cancelTitle'),
      text: t('orders.cancelText', {'n': order.number}),
      yesLabel: t('orders.cancelYes'),
      noLabel: t('orders.cancelNo'),
      danger: true,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(serverProvider).cancelOrder(order.id);
      ref.invalidate(orderProvider(widget.orderId));
      ref.invalidate(ordersProvider);
      if (mounted) {
        showToast(context, t('orders.cancelled'), kind: ToastKind.success);
      }
    } on ApiError catch (e) {
      if (mounted) showToast(context, e.message, kind: ToastKind.error);
    }
  }

  /// Headline title and text for the current status.
  (String, String) _headline(Order order) {
    switch (order.status) {
      case OrderStatus.isNew:
        return (t('trk.msg.new.title'), t('trk.msg.new.text'));
      case OrderStatus.confirm:
        return (t('trk.msg.confirm.title'), t('trk.msg.confirm.text'));
      case OrderStatus.accepted:
        return (t('trk.msg.accepted.title'), t('trk.msg.accepted.text'));
      case OrderStatus.preparing:
        return (t('trk.msg.preparing.title'), t('trk.msg.preparing.text'));
      case OrderStatus.onTheWay:
        return (t('trk.msg.on_the_way.title'), t('trk.msg.on_the_way.text'));
      case OrderStatus.ready:
        return (t('trk.msg.ready.title'), t('trk.msg.ready.text'));
      case OrderStatus.completed:
        return (t('trk.msg.completed.title'), t('trk.msg.completed.text'));
      case OrderStatus.rejected:
        return (
          t('trk.msg.rejected.title'),
          t('trk.msg.cancelled.text'),
        );
      case OrderStatus.cancelled:
        return (t('trk.msg.cancelled.title'), t('trk.msg.cancelled.text'));
      case OrderStatus.expired:
        return (t('trk.msg.expired.title'), t('trk.msg.expired.text'));
    }
  }
}

/// The vertical four-step tracker with the time each step happened.
class _Steps extends StatelessWidget {
  const _Steps({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final delivery = order.fulfilment == Fulfilment.delivery;
    final steps = <(String, OrderStatus)>[
      (t('ot.step.accepted'), OrderStatus.accepted),
      (t('ot.step.preparing'), OrderStatus.preparing),
      (
        delivery ? t('ot.step.on_the_way') : t('ot.step.ready'),
        delivery ? OrderStatus.onTheWay : OrderStatus.ready
      ),
      (
        delivery ? t('ot.step.delivered') : t('ot.step.pickedUp'),
        OrderStatus.completed
      ),
    ];
    final reached = OrderProgress.stepOf(order.status);

    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Container(
                    height: 20,
                    width: 20,
                    decoration: BoxDecoration(
                      color: i < reached ? tok.accent : tok.card,
                      shape: BoxShape.circle,
                    ),
                    child: i < reached
                        ? Icon(Icons.check_rounded,
                            size: 13, color: tok.accentText)
                        : null,
                  ),
                  if (i < steps.length - 1)
                    Container(
                      width: 2,
                      height: 22,
                      color: i < reached - 1 ? tok.accent : tok.card,
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 1, bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          steps[i].$1,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: i < reached
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: i < reached ? tok.text : tok.hint,
                          ),
                        ),
                      ),
                      Builder(builder: (context) {
                        final at = order.stampAt(steps[i].$2);
                        return Text(
                          at == null ? '' : hhmm(at),
                          style: TextStyle(fontSize: 12.5, color: tok.hint),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// "Takrorlash" from the tracking page.
Future<void> repeatOrderFromTracking(
    BuildContext context, WidgetRef ref, Order order) async {
  final current = await ref
      .read(serverProvider)
      .getProducts(order.items.map((i) => i.productId).toList());
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
        : t('orders.repeatedPartial', {'n': result.added, 'm': result.missing}),
    kind: ToastKind.success,
  );
  context.go('/cart');
}
