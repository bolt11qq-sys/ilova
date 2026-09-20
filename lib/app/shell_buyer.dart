/// The buyer shell: five tabs in a floating white pill, plus the polling that
/// replaces the Telegram bot's push notifications.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/strings_buyer.dart';
import '../state/providers.dart';
import 'theme.dart';

/// How often the order list is re-read while the app is in the foreground.
const Duration ordersPollInterval = Duration(seconds: 15);

class BuyerShell extends ConsumerStatefulWidget {
  const BuyerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends ConsumerState<BuyerShell>
    with WidgetsBindingObserver {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _poll = Timer.periodic(ordersPollInterval, (_) => _refresh());
  }

  @override
  void dispose() {
    _poll?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(ordersProvider);
  }

  void _go(int index) {
    HapticFeedback.selectionClick();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = ref.watch(cartCountProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: BuyerNavBar(
        currentIndex: widget.navigationShell.currentIndex,
        cartCount: cartCount,
        onTap: _go,
      ),
    );
  }
}

class BuyerNavItem {
  const BuyerNavItem(this.label, this.icon, this.activeIcon);
  final String label;
  final IconData icon;
  final IconData activeIcon;
}

List<BuyerNavItem> buyerNavItems() => [
      BuyerNavItem(t('nav.home'), Icons.home_outlined, Icons.home_rounded),
      BuyerNavItem(t('nav.shops'), Icons.storefront_outlined,
          Icons.storefront_rounded),
      BuyerNavItem(t('nav.cart'), Icons.shopping_cart_outlined,
          Icons.shopping_cart_rounded),
      BuyerNavItem(t('nav.orders'), Icons.receipt_long_outlined,
          Icons.receipt_long_rounded),
      BuyerNavItem(
          t('nav.profile'), Icons.person_outline_rounded, Icons.person_rounded),
    ];

/// The floating white pill with five items; the cart carries a count badge.
class BuyerNavBar extends StatelessWidget {
  const BuyerNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.cartCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final int cartCount;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final items = buyerNavItems();
    return Padding(
      padding: EdgeInsets.fromLTRB(
          12, 0, 12, 10 + MediaQuery.paddingOf(context).bottom),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: tok.surface,
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: tok.isDark
                  ? Colors.black.withAlpha(120)
                  : const Color(0x29143C32),
              blurRadius: 28,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  badge: i == 2 ? cartCount : 0,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final BuyerNavItem item;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final color = selected ? tok.accent : tok.hint;
    return Semantics(
      label: item.label,
      selected: selected,
      button: true,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(selected ? item.activeIcon : item.icon,
                      size: 24, color: color),
                  if (badge > 0)
                    Positioned(
                      right: -7,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(
                          color: tok.accent,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: tok.surface, width: 2),
                        ),
                        child: Text(
                          badge > 99 ? '99+' : '$badge',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: tok.accentText,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 3),
            Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
