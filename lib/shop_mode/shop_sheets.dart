/// Shop-side sheets: reject with a reason, the "Nechta bor?" availability
/// sheet, the price editor and the staff invite.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../core/strings_shop.dart';
import '../core/time.dart';
import '../data/models.dart';
import '../features/widgets/buttons.dart';
import '../features/widgets/layout.dart';
import '../features/widgets/photo.dart';
import '../features/widgets/sheet.dart';
import '../features/widgets/stepper.dart';
import '../features/widgets/toast.dart';
import '../state/providers.dart';

/// "Nega rad etasiz?" — four preset reasons plus a preview of what the buyer
/// will read. Returns the chosen reason, or `'availability'` when the shop
/// switches to the per-line sheet instead.
Future<String?> showRejectSheet(BuildContext context, Order order) {
  return showYSheet<String>(
    context: context,
    builder: (context) => _RejectSheet(order: order),
  );
}

class _RejectSheet extends StatefulWidget {
  const _RejectSheet({required this.order});

  final Order order;

  @override
  State<_RejectSheet> createState() => _RejectSheetState();
}

class _RejectSheetState extends State<_RejectSheet> {
  String _reason = S.reject.reasons.first;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return SheetBody(
      bottom: YButton(
        label: S.reject.submit,
        variant: YButtonVariant.danger,
        onPressed: () => Navigator.of(context).pop(_reason),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: S.reject.title),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final r in S.reject.reasons)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      _reason == r
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: _reason == r ? tok.accent : tok.hint,
                    ),
                    title: Text(
                      r,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight:
                            _reason == r ? FontWeight.w600 : FontWeight.w400,
                        color: tok.text,
                      ),
                    ),
                    onTap: () => setState(() => _reason = r),
                  ),
                const SizedBox(height: 8),
                YCard(
                  color: tok.accentSoft,
                  shadow: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.reject.tipTitle,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: tok.text,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        S.reject.tipText,
                        style: TextStyle(
                            fontSize: 13, color: tok.hint, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      YButton(
                        label: S.reject.tipCta,
                        small: true,
                        variant: YButtonVariant.mint,
                        onPressed: () =>
                            Navigator.of(context).pop('availability'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  S.reject.preview,
                  style: TextStyle(fontSize: 13, color: tok.hint),
                ),
                const SizedBox(height: 6),
                YCard(
                  color: tok.card,
                  shadow: false,
                  child: Text(
                    S.reject.message(widget.order.shopName, _reason),
                    style: TextStyle(
                        fontSize: 13.5, color: tok.text, height: 1.35),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "Nechta bor?" — a stepper per line; returns productId → available quantity.
Future<Map<String, int>?> showAvailabilitySheet(
    BuildContext context, Order order) {
  return showYSheet<Map<String, int>>(
    context: context,
    builder: (context) => _AvailabilitySheet(order: order),
  );
}

class _AvailabilitySheet extends StatefulWidget {
  const _AvailabilitySheet({required this.order});

  final Order order;

  @override
  State<_AvailabilitySheet> createState() => _AvailabilitySheetState();
}

class _AvailabilitySheetState extends State<_AvailabilitySheet> {
  late final Map<String, int> _available = {
    for (final i in widget.order.items) i.productId: i.quantity,
  };

  int get _newItemsTotal => widget.order.items.fold<int>(
        0,
        (n, i) => n + i.price * (_available[i.productId] ?? i.quantity),
      );

  bool get _changed => widget.order.items
      .any((i) => (_available[i.productId] ?? i.quantity) != i.quantity);

  bool get _allGone => widget.order.items
      .every((i) => (_available[i.productId] ?? 0) == 0);

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final newTotal = _newItemsTotal + widget.order.deliveryFee;
    final blockedNote = !_changed
        ? S.avail.needChange
        : (_allGone ? S.avail.allGone : null);

    return SheetBody(
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (blockedNote != null) ...[
            Text(
              blockedNote,
              style: TextStyle(fontSize: 13, color: tok.danger),
            ),
            const SizedBox(height: 8),
          ],
          YButton(
            label: S.avail.send(formatPrice(newTotal)),
            onPressed: blockedNote != null
                ? null
                : () => Navigator.of(context).pop(_available),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: S.avail.title, subtitle: S.avail.hint),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            child: Column(
              children: [
                for (final item in widget.order.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        ProductPhoto(
                            photo: item.photo, emoji: item.emoji, size: 44),
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
                                  color: tok.text,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _hint(item),
                                style: TextStyle(
                                    fontSize: 12.5, color: tok.hint),
                              ),
                            ],
                          ),
                        ),
                        QtyStepper(
                          quantity: _available[item.productId] ?? item.quantity,
                          max: item.quantity,
                          compact: true,
                          onChanged: (v) => setState(
                              () => _available[item.productId] = v),
                        ),
                      ],
                    ),
                  ),
                Divider(color: tok.border),
                TotalRow(
                  label: S.avail.old,
                  value: formatPrice(widget.order.total),
                ),
                TotalRow(
                  label: S.avail.neu,
                  value: formatPrice(newTotal),
                  strong: true,
                  valueColor: tok.accentInk,
                ),
                const SizedBox(height: 10),
                Text(
                  S.avail.note,
                  style: TextStyle(fontSize: 12.5, color: tok.hint, height: 1.3),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _hint(OrderItem item) {
    final have = _available[item.productId] ?? item.quantity;
    if (have == 0) return S.avail.none;
    if (have == item.quantity) return S.avail.all;
    return '${S.avail.ordered(item.quantity)} · ${S.avail.less(item.quantity - have)}';
  }
}

/// Edits one product's price.
Future<int?> showPriceSheet(
    BuildContext context, String name, int current) {
  return showYSheet<int>(
    context: context,
    builder: (context) => _PriceSheet(name: name, current: current),
  );
}

class _PriceSheet extends StatefulWidget {
  const _PriceSheet({required this.name, required this.current});

  final String name;
  final int current;

  @override
  State<_PriceSheet> createState() => _PriceSheetState();
}

class _PriceSheetState extends State<_PriceSheet> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.current}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      bottom: YButton(
        label: S.common.save,
        onPressed: () {
          final value = int.tryParse(_controller.text.replaceAll(RegExp(r'\D'), ''));
          Navigator.of(context).pop(value != null && value > 0 ? value : null);
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: S.products.editPrice, subtitle: widget.name),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(
                suffixText: S.common.som,
                labelText: S.products.price,
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

/// "Xodim taklif qilish": pick a role, then copy the mocked 24-hour link.
Future<void> showInviteSheet(BuildContext context, WidgetRef ref) {
  return showYSheet<void>(
    context: context,
    builder: (context) => _InviteSheet(ref: ref),
  );
}

class _InviteSheet extends StatefulWidget {
  const _InviteSheet({required this.ref});

  final WidgetRef ref;

  @override
  State<_InviteSheet> createState() => _InviteSheetState();
}

class _InviteSheetState extends State<_InviteSheet> {
  String _role = 'seller';
  Invite? _invite;
  bool _busy = false;

  Future<void> _create() async {
    setState(() => _busy = true);
    final invite = await widget.ref.read(shopApiProvider).createInvite(_role);
    if (!mounted) return;
    setState(() {
      _invite = invite;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final seller = _role == 'seller';
    final can = seller ? S.invite.sellerYes : S.invite.courierYes;
    final cannot = seller ? S.invite.sellerNo : S.invite.courierNo;

    return SheetBody(
      bottom: _invite == null
          ? YButton(
              label: S.invite.link,
              loading: _busy,
              onPressed: _create,
            )
          : YButton(
              label: S.common.close,
              variant: YButtonVariant.grey,
              onPressed: () => Navigator.of(context).pop(),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: S.invite.title, subtitle: S.invite.which),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _RoleTile(
                        title: S.invite.seller,
                        subtitle: S.invite.sellerSub,
                        selected: seller,
                        onTap: () => setState(() => _role = 'seller'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _RoleTile(
                        title: S.invite.courier,
                        subtitle: S.invite.courierSub,
                        selected: !seller,
                        onTap: () => setState(() => _role = 'courier'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  seller ? S.invite.sellerCan : S.invite.courierCan,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: tok.text,
                  ),
                ),
                const SizedBox(height: 6),
                for (final line in can)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_rounded, size: 16, color: tok.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(line,
                              style: TextStyle(fontSize: 13, color: tok.text)),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 6),
                for (final line in cannot)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.close_rounded, size: 16, color: tok.hint),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(line,
                              style: TextStyle(fontSize: 13, color: tok.hint)),
                        ),
                      ],
                    ),
                  ),
                if (_invite != null) ...[
                  const SizedBox(height: 14),
                  YCard(
                    color: tok.card,
                    shadow: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _invite!.link,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: tok.text,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${S.invite.valid} · ${shortDateTime(_invite!.expiresAt)}',
                          style: TextStyle(fontSize: 12, color: tok.hint),
                        ),
                        const SizedBox(height: 10),
                        YButton(
                          label: S.invite.copy,
                          icon: Icons.copy_rounded,
                          small: true,
                          variant: YButtonVariant.mint,
                          onPressed: () {
                            Clipboard.setData(
                                ClipboardData(text: _invite!.link));
                            showToast(context, S.invite.copied,
                                kind: ToastKind.success);
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          S.invite.after,
                          style: TextStyle(fontSize: 12, color: tok.hint),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Material(
      color: selected ? tok.accentSoft : tok.card,
      borderRadius: BorderRadius.circular(YRadius.button),
      child: InkWell(
        borderRadius: BorderRadius.circular(YRadius.button),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(YRadius.button),
            border: Border.all(color: selected ? tok.accent : tok.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: selected ? tok.accentInk : tok.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: tok.hint, height: 1.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
