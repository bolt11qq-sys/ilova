/// The shop shell: Panel · Buyurtmalar · Mahsulotlar · Sozlamalar.
///
/// It is the same APK as the buyer app, so the two modes share the mock
/// database: what the shop does here shows up for the buyer immediately.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/strings_shop.dart';
import '../state/providers.dart';
import 'theme.dart';

const Duration shopPollInterval = Duration(seconds: 15);

class ShopShell extends ConsumerStatefulWidget {
  const ShopShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<ShopShell> createState() => _ShopShellState();
}

class _ShopShellState extends ConsumerState<ShopShell>
    with WidgetsBindingObserver {
  Timer? _poll;
  int _lastNewCount = -1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
    _poll = Timer.periodic(shopPollInterval, (_) => _refresh());
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

  /// Switches the mock server into "the shop drives the orders" mode and
  /// creates the demo orders from other customers, once.
  Future<void> _open() async {
    await ref.read(shopApiProvider).openShopApp();
    if (!mounted) return;
    _refresh();
  }

  void _refresh() {
    if (!mounted) return;
    ref.invalidate(shopOrdersProvider);
    ref.invalidate(shopStatsProvider);
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
    final tok = yt(context);
    final waiting = ref.watch(shopStatsProvider).valueOrNull?.waiting ?? 0;
    // A new order while the screen is open gets a short haptic nudge.
    if (_lastNewCount >= 0 && waiting > _lastNewCount) {
      HapticFeedback.mediumImpact();
    }
    _lastNewCount = waiting;

    final items = [
      (S.nav.panel, Icons.insert_chart_outlined, Icons.insert_chart_rounded, 0),
      (S.nav.orders, Icons.inbox_outlined, Icons.inbox_rounded, waiting),
      (S.nav.products, Icons.grid_view_outlined, Icons.grid_view_rounded, 0),
      (S.nav.settings, Icons.settings_outlined, Icons.settings_rounded, 0),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: Padding(
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
                  child: _ShopNavButton(
                    label: items[i].$1,
                    icon: items[i].$2,
                    activeIcon: items[i].$3,
                    badge: items[i].$4,
                    selected: i == widget.navigationShell.currentIndex,
                    onTap: () => _go(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShopNavButton extends StatelessWidget {
  const _ShopNavButton({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final bool selected;
  final int badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final color = selected ? tok.accent : tok.hint;
    return InkWell(
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
                Icon(selected ? activeIcon : icon, size: 24, color: color),
                if (badge > 0)
                  Positioned(
                    right: -8,
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
                        '$badge',
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
            label,
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
    );
  }
}
