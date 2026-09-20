/// "Doʻkonlar" — every shop in range, open first, then nearest.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/search.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../sheets/address_sheet.dart';
import '../widgets/layout.dart';
import '../widgets/shop_widgets.dart';
import '../widgets/states.dart';

class ShopsPage extends ConsumerStatefulWidget {
  const ShopsPage({super.key});

  @override
  ConsumerState<ShopsPage> createState() => _ShopsPageState();
}

class _ShopsPageState extends ConsumerState<ShopsPage> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final shops = ref.watch(shopsProvider);
    final inArea = ref.watch(inServiceAreaProvider);

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
                    screenPadding, 12, screenPadding, 6),
                child: Text(
                  t('shops.title'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: tok.text,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    screenPadding, 6, screenPadding, 10),
                child: TextField(
                  controller: _query,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: t('shops.search'),
                    prefixIcon: Icon(Icons.search_rounded, color: tok.hint),
                    suffixIcon: _query.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.close_rounded, color: tok.hint),
                            onPressed: () {
                              _query.clear();
                              setState(() {});
                            },
                          ),
                  ),
                ),
              ),
              Expanded(
                child: !inArea
                    ? EmptyState(
                        title: t('out.title'),
                        text: t('out.text'),
                        image: 'assets/img/outside.png',
                        ctaLabel: t('out.pick'),
                        onCta: () => showAddressSheet(context, ref),
                      )
                    : AsyncView<List<ShopView>>(
                        value: shops,
                        onRetry: () => ref.invalidate(shopsProvider),
                        data: (list) => _list(list),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(List<ShopView> all) {
    final tok = yt(context);
    final q = _query.text.trim();
    final list = q.isEmpty
        ? all
        : all
            .where((s) => matchScore(q, '${s.name} ${s.type}') != null)
            .toList();

    if (list.isEmpty) {
      return EmptyState(
        title: q.isEmpty ? t('home.noShops') : t('shops.none'),
        text: q.isEmpty ? t('out.text') : t('search.emptyHint'),
        icon: Icons.storefront_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(shopsProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(
            screenPadding, 4, screenPadding, 110),
        itemCount: list.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                t('shops.count', {'n': list.length}),
                style: TextStyle(fontSize: 13, color: tok.hint),
              ),
            );
          }
          final s = list[i - 1];
          return ShopRow(
            shop: s,
            onTap: () => context.push('/shop/${s.id}'),
          );
        },
      ),
    );
  }
}
