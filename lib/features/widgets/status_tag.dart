/// Status pills: green for success, amber for "needs confirmation", red for
/// rejected or cancelled, grey for neutral.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';

enum TagTone { success, warn, danger, neutral, accentSoft }

class StatusTag extends StatelessWidget {
  const StatusTag({
    super.key,
    required this.label,
    this.tone = TagTone.neutral,
    this.icon,
    this.small = false,
  });

  final String label;
  final TagTone tone;
  final IconData? icon;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final (Color bg, Color fg) = switch (tone) {
      TagTone.success => (tok.accentSoft, tok.accentInk),
      TagTone.warn => (const Color(0x2EF59E0B), tok.warn),
      TagTone.danger => (tok.danger.withAlpha(36), tok.danger),
      TagTone.neutral => (tok.card, tok.hint),
      TagTone.accentSoft => (tok.mint, tok.accentInk),
    };
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 8 : 10, vertical: small ? 3 : 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(YRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? 12 : 14, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: small ? 11 : 12.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// The buyer-facing label of an order status ("Yetkazildi" vs "Olib ketildi"
/// depends on how the order is fulfilled).
String orderStatusLabel(OrderStatus status, Fulfilment fulfilment) {
  switch (status) {
    case OrderStatus.isNew:
      return t('status.new');
    case OrderStatus.confirm:
      return t('status.confirm');
    case OrderStatus.accepted:
      return t('status.accepted');
    case OrderStatus.preparing:
      return t('status.preparing');
    case OrderStatus.onTheWay:
      return t('status.on_the_way');
    case OrderStatus.ready:
      return t('status.ready');
    case OrderStatus.completed:
      return fulfilment == Fulfilment.delivery
          ? t('status.delivered')
          : t('status.pickedUp');
    case OrderStatus.rejected:
      return t('status.rejected');
    case OrderStatus.cancelled:
      return t('status.cancelled');
    case OrderStatus.expired:
      return t('status.expired');
  }
}

TagTone orderStatusTone(OrderStatus status) {
  switch (status) {
    case OrderStatus.completed:
    case OrderStatus.onTheWay:
    case OrderStatus.ready:
    case OrderStatus.accepted:
    case OrderStatus.preparing:
      return TagTone.success;
    case OrderStatus.confirm:
      return TagTone.warn;
    case OrderStatus.rejected:
    case OrderStatus.cancelled:
    case OrderStatus.expired:
      return TagTone.danger;
    case OrderStatus.isNew:
      return TagTone.neutral;
  }
}

/// The four-segment progress bar on order cards and on the tracking page.
class OrderProgress extends StatelessWidget {
  const OrderProgress({super.key, required this.status, this.height = 5});

  final OrderStatus status;
  final double height;

  static int stepOf(OrderStatus status) {
    switch (status) {
      case OrderStatus.isNew:
      case OrderStatus.confirm:
        return 0;
      case OrderStatus.accepted:
        return 1;
      case OrderStatus.preparing:
        return 2;
      case OrderStatus.onTheWay:
      case OrderStatus.ready:
        return 3;
      case OrderStatus.completed:
        return 4;
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
      case OrderStatus.expired:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final done = stepOf(status);
    final failed = status == OrderStatus.rejected ||
        status == OrderStatus.cancelled ||
        status == OrderStatus.expired;
    return Row(
      children: [
        for (var i = 0; i < 4; i++) ...[
          Expanded(
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: failed
                    ? tok.danger.withAlpha(64)
                    : (i < done ? tok.accent : tok.card),
                borderRadius: BorderRadius.circular(height),
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 5),
        ],
      ],
    );
  }
}
