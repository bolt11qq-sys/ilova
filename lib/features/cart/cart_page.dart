/// "Savat" — lines, fulfilment, address, payment, comment, totals and the
/// server-side re-validation that guards the order button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/format.dart';
import '../../core/ids.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/providers.dart';
import '../sheets/address_sheet.dart';
import '../widgets/buttons.dart';
import '../widgets/layout.dart';
import '../widgets/photo.dart';
import '../widgets/states.dart';
import '../widgets/stepper.dart';
import '../widgets/toast.dart';

/// Turns a validation issue into the sentence the buyer reads.
String issueText(CartIssue issue) {
  if (issue is ShopClosedIssue) {
    return issue.opensLabel == null
        ? t('cart.issue.closed')
        : t('cart.issue.closedAt', {'time': issue.opensLabel});
  }
  if (issue is MinOrderIssue) {
    return t('cart.issue.minOrder', {'sum': formatNumber(issue.missing)});
  }
  if (issue is OutOfStockIssue) {
    return t('cart.issue.outOfStock', {'name': issue.name});
  }
  if (issue is PriceChangedIssue) {
    return t('cart.issue.priceChanged', {
      'name': issue.name,
      'from': formatPrice(issue.from),
      'to': formatPrice(issue.to),
    });
  }
  return t('cart.issue.deliveryUnavailable');
}

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _comment = TextEditingController();
  CartValidation? _validation;
  bool _validating = false;
  bool _placing = false;
  String? _idempotencyKey;
  ShopView? _shop;

  @override
  void initState() {
    super.initState();
    _comment.text = ref.read(cartProvider).comment;
    WidgetsBinding.instance.addPostFrameCallback((_) => _revalidate());
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Fulfilment _fulfilment(CartState cart) =>
      cart.fulfilment ??
      (_shop?.delivers == false ? Fulfilment.pickup : Fulfilment.delivery);

  Future<void> _revalidate() async {
    final cart = ref.read(cartProvider);
    if (cart.shopId == null || cart.isEmpty) {
      if (mounted) setState(() => _validation = null);
      return;
    }
    setState(() => _validating = true);
    final server = ref.read(serverProvider);
    final coords = ref.read(coordsProvider);
    try {
      final shop = await server.getShop(cart.shopId!, coords);
      final validation = await server.validateCart(ValidateInput(
        shopId: cart.shopId!,
        fulfilment: _fulfilmentFor(cart, shop),
        coords: coords,
        lines: [
          for (final l in cart.lines)
            ValidateLine(l.productId, l.quantity, l.priceAtAdd, l.name),
        ],
      ));
      if (!mounted) return;
      setState(() {
        _shop = shop;
        _validation = validation;
        _validating = false;
      });
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _validating = false);
      showToast(context, e.message, kind: ToastKind.error);
    }
  }

  Fulfilment _fulfilmentFor(CartState cart, ShopView shop) =>
      cart.fulfilment ?? (shop.delivers ? Fulfilment.delivery : Fulfilment.pickup);

  Future<void> _refreshCart() async {
    final fresh = _validation?.fresh;
    if (fresh == null) return;
    ref.read(appStateProvider).refreshCart(fresh);
    _idempotencyKey = null;
    await _revalidate();
    if (!mounted) return;
    showToast(context, t('cart.refreshed'), kind: ToastKind.success);
  }

  Future<void> _placeOrder() async {
    if (_placing) return;
    final cart = ref.read(cartProvider);
    final app = ref.read(appStateProvider);
    final shop = _shop;
    if (shop == null || cart.shopId == null) return;

    setState(() => _placing = true);
    final key = _idempotencyKey ??= uuid();
    try {
      final order = await ref.read(serverProvider).createOrder(
            CreateOrderInput(
              shopId: cart.shopId!,
              fulfilment: _fulfilmentFor(cart, shop),
              address: app.state.activeAddress,
              coords: ref.read(coordsProvider),
              lines: [
                for (final l in cart.lines)
                  ValidateLine(l.productId, l.quantity, l.priceAtAdd, l.name),
              ],
              comment: _comment.text,
              buyerName: app.state.user.firstName,
              buyerPhone: app.state.user.phone,
            ),
            key,
          );
      if (!mounted) return;
      app.clearCart();
      _idempotencyKey = null;
      showToast(context, t('cart.placed', {'n': order.number}),
          kind: ToastKind.success);
      ref.invalidate(ordersProvider);
      context.push('/orders/${order.id}');
    } on ApiError catch (e) {
      if (!mounted) return;
      setState(() => _placing = false);
      showToast(context, e.message, kind: ToastKind.error);
      await _revalidate();
    } finally {
      if (mounted && _placing) setState(() => _placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    // Re-checking with the server touches setState, so it is always deferred to
    // after the current frame.
    void scheduleRevalidate() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _revalidate();
      });
    }

    ref.listen(cartProvider, (prev, next) {
      if (prev?.lines.length != next.lines.length ||
          prev?.fulfilment != next.fulfilment ||
          prev?.shopId != next.shopId) {
        _idempotencyKey = null;
        scheduleRevalidate();
      }
    });
    ref.listen(activeAddressProvider, (_, __) => scheduleRevalidate());

    if (cart.isEmpty) return const _EmptyCart();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppBar(title: Text(t('sv.title'))),
              Expanded(child: _body(cart)),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottom(cart),
    );
  }

  Widget _bottom(CartState cart) {
    final blocked = _validation != null && !_validation!.ok;
    final total = cart.itemsTotal + _deliveryFee(cart);
    return BottomActionBar(
      child: YButton(
        label: t('sv.order', {'sum': formatPrice(total)}),
        loading: _placing,
        onPressed: blocked || _validating || _validation == null
            ? null
            : _placeOrder,
      ),
    );
  }

  int _deliveryFee(CartState cart) {
    final shop = _shop;
    if (shop == null) return 0;
    return _fulfilmentFor(cart, shop) == Fulfilment.delivery
        ? shop.deliveryFee
        : 0;
  }

  Widget _body(CartState cart) {
    final tok = yt(context);
    final app = ref.watch(appStateProvider);
    final shop = _shop;
    final address = ref.watch(activeAddressProvider);
    final fulfilment = shop == null ? _fulfilment(cart) : _fulfilmentFor(cart, shop);
    final issues = _validation?.issues ?? const <CartIssue>[];

    return ListView(
      padding:
          const EdgeInsets.fromLTRB(screenPadding, 4, screenPadding, 24),
      children: [
        YCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.storefront_rounded, size: 21, color: tok.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cart.shopName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: tok.text,
                  ),
                ),
              ),
              if (shop != null)
                TextButton(
                  onPressed: () => context.push('/shop/${shop.id}'),
                  child: Text(t('sp.all')),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        for (final line in cart.lines) ...[
          _Line(
            line: line,
            onChanged: (v) => app.setQuantity(line.productId, v),
          ),
          const SizedBox(height: 10),
        ],
        if (issues.isNotEmpty) ...[
          const SizedBox(height: 4),
          YCard(
            color: tok.peach,
            shadow: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_rounded, size: 19, color: tok.warn),
                    const SizedBox(width: 8),
                    Text(
                      t('cart.cannotOrder'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tok.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final issue in issues)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '• ${issueText(issue)}',
                      style: TextStyle(
                          fontSize: 13.5, color: tok.text, height: 1.35),
                    ),
                  ),
                const SizedBox(height: 8),
                YButton(
                  label: t('cart.refresh'),
                  small: true,
                  variant: YButtonVariant.grey,
                  onPressed: _refreshCart,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          t('sv.how'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: tok.text,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _Segment(
                label: t('sv.delivery'),
                icon: Icons.delivery_dining_rounded,
                selected: fulfilment == Fulfilment.delivery,
                enabled: shop?.delivers ?? true,
                onTap: () => app.setFulfilment(Fulfilment.delivery),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _Segment(
                label: t('sv.pickup'),
                icon: Icons.storefront_rounded,
                selected: fulfilment == Fulfilment.pickup,
                onTap: () => app.setFulfilment(Fulfilment.pickup),
              ),
            ),
          ],
        ),
        if (shop != null && !shop.delivers) ...[
          const SizedBox(height: 8),
          Text(t('cart.noDelivery'),
              style: TextStyle(fontSize: 13, color: tok.hint)),
        ] else if (shop != null &&
            !shop.canDeliverHere &&
            fulfilment == Fulfilment.delivery) ...[
          const SizedBox(height: 8),
          Text(t('cart.outOfRadius'),
              style: TextStyle(fontSize: 13, color: tok.danger)),
        ],
        const SizedBox(height: 16),
        if (fulfilment == Fulfilment.delivery)
          YCard(
            onTap: () => showAddressSheet(context, ref),
            child: Row(
              children: [
                Icon(Icons.place_rounded, size: 21, color: tok.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('sv.addr'),
                        style: TextStyle(fontSize: 12.5, color: tok.hint),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address?.oneLine ?? t('home.noAddress'),
                        maxLines: 2,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: tok.text,
                        ),
                      ),
                      if (address != null && address.landmark.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          t('sv.landmark', {'v': address.landmark}),
                          style: TextStyle(fontSize: 12.5, color: tok.hint),
                        ),
                      ],
                    ],
                  ),
                ),
                Text(
                  t('cart.change'),
                  style: TextStyle(
                    fontSize: 13.5,
                    color: tok.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else if (shop != null)
          YCard(
            child: Row(
              children: [
                Icon(Icons.store_mall_directory_rounded,
                    size: 21, color: tok.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('trk.pickupWhere'),
                        style: TextStyle(fontSize: 12.5, color: tok.hint),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shop.address,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: tok.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 12),
        YCard(
          child: Row(
            children: [
              Icon(Icons.payments_rounded, size: 21, color: tok.accent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t('sv.cash'),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tok.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fulfilment == Fulfilment.delivery
                          ? t('sv.cashDelivery')
                          : t('sv.cashPickup'),
                      style: TextStyle(fontSize: 12.5, color: tok.hint),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      t('sv.cardSoon'),
                      style: TextStyle(fontSize: 12, color: tok.hint),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle_rounded, size: 20, color: tok.accent),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _comment,
          maxLength: maxCommentLength,
          maxLines: 3,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: t('sv.note')),
          onChanged: (v) => ref.read(appStateProvider).setComment(v),
        ),
        const SizedBox(height: 4),
        YCard(
          child: Column(
            children: [
              TotalRow(
                label: t('sv.items'),
                value: formatPrice(cart.itemsTotal),
              ),
              if (cart.savings > 0)
                TotalRow(
                  label: t('sv.saving'),
                  value: '−${formatPrice(cart.savings)}',
                  valueColor: tok.coral,
                ),
              if (fulfilment == Fulfilment.delivery)
                TotalRow(
                  label: t('sv.fee'),
                  value: _deliveryFee(cart) == 0
                      ? t('sv.free')
                      : formatPrice(_deliveryFee(cart)),
                ),
              Divider(height: 18, color: tok.border),
              TotalRow(
                label: t('sv.total'),
                value: formatPrice(cart.itemsTotal + _deliveryFee(cart)),
                strong: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Center(
          child: Text(
            t('co.safe'),
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: tok.hint),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.line, required this.onChanged});

  final CartLine line;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return YCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          ProductPhoto(photo: line.photo, emoji: line.emoji, size: 56),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  line.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                    color: tok.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPrice(line.priceAtAdd),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: line.regularPrice > line.priceAtAdd
                        ? tok.coral
                        : tok.text,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          QtyStepper(quantity: line.quantity, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected ? tok.accentSoft : tok.surface,
        borderRadius: BorderRadius.circular(YRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(YRadius.button),
          onTap: enabled ? onTap : null,
          child: Container(
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(YRadius.button),
              border: Border.all(color: selected ? tok.accent : tok.border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 19, color: selected ? tok.accentInk : tok.hint),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: selected ? tok.accentInk : tok.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCart extends ConsumerWidget {
  const _EmptyCart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final promos = ref.watch(homePromotionsProvider).valueOrNull;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          child: EmptyState(
            title: t('sv.emptyTitle'),
            text: t('sv.emptyText'),
            image: 'assets/img/empty-cart.png',
            ctaLabel: t('sv.emptyCta'),
            onCta: () => context.go('/shops'),
            extra: promos == null || promos.isEmpty
                ? null
                : Text(
                    t('sv.emptyPromos', {'n': promos.length}),
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: tok.accentInk,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
