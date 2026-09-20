/// "Panel": the open/closed switch, the waiting-orders alert, the promotion
/// shortcut and today's figures.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../core/strings_shop.dart';
import '../core/time.dart';
import '../data/models.dart';
import '../features/widgets/layout.dart';
import '../features/widgets/states.dart';
import '../state/providers.dart';

class ShopPanelPage extends ConsumerWidget {
  const ShopPanelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(shopSettingsProvider);
    final stats = ref.watch(shopStatsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(shopSettingsProvider);
              ref.invalidate(shopStatsProvider);
            },
            child: AsyncView<ShopSettingsData>(
              value: settings,
              onRetry: () => ref.invalidate(shopSettingsProvider),
              data: (s) => ListView(
                padding: const EdgeInsets.fromLTRB(
                    screenPadding, 8, screenPadding, 110),
                children: [
                  _ShopHead(settings: s),
                  const SizedBox(height: 14),
                  _OpenSwitch(settings: s),
                  if (s.pending) ...[
                    const SizedBox(height: 12),
                    _PendingCard(),
                  ],
                  const SizedBox(height: 12),
                  stats.when(
                    loading: () => const Skeleton(
                        height: 92, radius: YRadius.card),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (st) => Column(
                      children: [
                        if (st.waiting > 0) ...[
                          _WaitingCard(stats: st),
                          const SizedBox(height: 12),
                        ],
                        _PromoCta(),
                        const SizedBox(height: 18),
                        _TodayStats(stats: st),
                        const SizedBox(height: 14),
                        _StockLink(stats: st),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopHead extends StatelessWidget {
  const _ShopHead({required this.settings});

  final ShopSettingsData settings;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Row(
      children: [
        Container(
          height: 64,
          width: 64,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: tok.card,
            borderRadius: BorderRadius.circular(YRadius.card),
          ),
          child: settings.photo == null
              ? Icon(Icons.storefront_rounded, size: 30, color: tok.hint)
              : Image.asset(
                  settings.photo!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Icon(
                      Icons.storefront_rounded, size: 30, color: tok.hint),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                settings.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: tok.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                S.panel.today(
                    longDate(DateTime.now().millisecondsSinceEpoch)),
                style: TextStyle(fontSize: 14, color: tok.hint),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OpenSwitch extends ConsumerWidget {
  const _OpenSwitch({required this.settings});

  final ShopSettingsData settings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final open = settings.manualOpen && !settings.vacation;
    return YCard(
      child: Row(
        children: [
          Container(
            height: 12,
            width: 12,
            decoration: BoxDecoration(
              color: open ? tok.accent : tok.hint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  open ? S.panel.open : S.panel.closed,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: tok.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  open ? S.panel.openSub : S.panel.closedSub,
                  style: TextStyle(fontSize: 13, color: tok.hint),
                ),
              ],
            ),
          ),
          Switch(
            value: open,
            onChanged: (v) async {
              await ref
                  .read(shopApiProvider)
                  .saveSettings(settings.id, manualOpen: v, vacation: false);
              ref.invalidate(shopSettingsProvider);
              invalidateAll(ref);
            },
          ),
        ],
      ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return YCard(
      color: tok.peach,
      shadow: false,
      child: Row(
        children: [
          Image.asset(
            'assets/img/so-pending.png',
            height: 56,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.hourglass_top_rounded, size: 34, color: tok.warn),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.panel.pending,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: tok.text,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  S.panel.pendingSub,
                  style: TextStyle(fontSize: 13, color: tok.hint, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingCard extends StatelessWidget {
  const _WaitingCard({required this.stats});

  final ShopStats stats;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final oldest = stats.oldestWaitingAt;
    final minutes = oldest == null
        ? 0
        : ((DateTime.now().millisecondsSinceEpoch - oldest) / 60000).floor();
    return YCard(
      color: tok.peach,
      shadow: false,
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: tok.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_active_rounded,
                size: 22, color: tok.warn),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.panel.waiting(stats.waiting),
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: tok.text,
                  ),
                ),
                if (oldest != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    S.panel.oldest(minutes),
                    style: TextStyle(fontSize: 12.5, color: tok.hint),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => context.go('/shop-mode/orders'),
            child: Text(S.panel.view),
          ),
        ],
      ),
    );
  }
}

class _PromoCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return YCard(
      color: tok.accent,
      shadow: false,
      onTap: () => context.push('/shop-promo'),
      child: Row(
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(56),
              borderRadius: BorderRadius.circular(YRadius.smallButton),
            ),
            child: Icon(Icons.local_offer_rounded,
                size: 24, color: tok.accentText),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.panel.promoTitle,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: tok.accentText,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  S.panel.promoSub,
                  style: TextStyle(
                    fontSize: 13,
                    color: tok.accentText.withAlpha(215),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: tok.accentText),
        ],
      ),
    );
  }
}

class _TodayStats extends StatelessWidget {
  const _TodayStats({required this.stats});

  final ShopStats stats;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);

    Widget tile(IconData icon, String label, String value, String? note) =>
        YCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 19, color: tok.accent),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: tok.hint),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: tok.text,
                ),
              ),
              if (note != null) ...[
                const SizedBox(height: 5),
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: tok.accentInk,
                  ),
                ),
              ],
            ],
          ),
        );

    final showDelta = stats.yesterdayOrders != 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          S.panel.todayTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: tok.text,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: tile(
                Icons.shopping_basket_rounded,
                S.panel.ordersLabel,
                '${stats.orders}',
                showDelta
                    ? S.panel.yesterday(
                        '${stats.ordersDelta >= 0 ? '+' : ''}${stats.ordersDelta}')
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: tile(
                Icons.payments_rounded,
                S.panel.revenueLabel,
                formatPrice(stats.revenue),
                showDelta
                    ? S.panel.yesterday(
                        '${stats.revenueDeltaPct >= 0 ? '+' : ''}${stats.revenueDeltaPct}%')
                    : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: tile(
                Icons.visibility_rounded,
                S.panel.viewsLabel,
                '${stats.views}',
                stats.views > 0 ? S.panel.viaPromos : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: tile(
                Icons.local_offer_rounded,
                S.panel.promosLabel,
                '${stats.activePromos}',
                stats.bestPromo == null
                    ? S.panel.noPromo
                    : S.panel.best(stats.bestPromo!),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StockLink extends StatelessWidget {
  const _StockLink({required this.stats});

  final ShopStats stats;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return YCard(
      onTap: () => context.go('/shop-mode/products'),
      child: Row(
        children: [
          Image.asset(
            'assets/img/so-box.png',
            height: 40,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.inventory_2_rounded, size: 26, color: tok.hint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.panel.stock,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: tok.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  S.panel.stockSub(stats.soldOut),
                  style: TextStyle(fontSize: 13, color: tok.hint),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 22, color: tok.hint),
        ],
      ),
    );
  }
}
