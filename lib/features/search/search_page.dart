/// Search: 300 ms debounce, minimum two characters, five remembered queries,
/// two result groups and three sort orders.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../sheets/cart_sheets.dart';
import '../widgets/chips.dart';
import '../widgets/layout.dart';
import '../widgets/product_cards.dart';
import '../widgets/shop_widgets.dart';
import '../widgets/states.dart';

const int minSearchChars = 2;
const Duration searchDebounce = Duration(milliseconds: 300);

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();
  Timer? _debounce;
  String _query = '';
  SearchSort _sort = SearchSort.distance;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(searchDebounce, () {
      if (!mounted) return;
      setState(() => _query = value.trim());
      if (value.trim().length >= minSearchChars) {
        ref.read(appStateProvider).rememberSearch(value.trim());
      }
    });
    setState(() {});
  }

  void _use(String query) {
    _controller.text = query;
    setState(() => _query = query);
    ref.read(appStateProvider).rememberSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final ready = _query.length >= minSearchChars;

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
                    screenPadding - 8, 8, screenPadding, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      tooltip: t('common.back'),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        textInputAction: TextInputAction.search,
                        onChanged: _onChanged,
                        onSubmitted: _use,
                        decoration: InputDecoration(
                          hintText: t('se.placeholder'),
                          prefixIcon:
                              Icon(Icons.search_rounded, color: tok.hint),
                          suffixIcon: _controller.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: t('search.clear'),
                                  icon: Icon(Icons.close_rounded,
                                      color: tok.hint),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() => _query = '');
                                  },
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (ready) ...[
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: screenPadding),
                    children: [
                      for (final s in SearchSort.values) ...[
                        YChip(
                          label: switch (s) {
                            SearchSort.distance => t('search.sort.distance'),
                            SearchSort.price => t('search.sort.price'),
                            SearchSort.discount => t('search.sort.discount'),
                          },
                          selected: _sort == s,
                          onTap: () => setState(() => _sort = s),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],
              Expanded(child: ready ? _results() : _start()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _start() {
    final tok = yt(context);
    final recent = ref.watch(appStateProvider).state.recentSearches;
    if (recent.isEmpty) {
      return EmptyState(
        title: t('search.startTitle'),
        text: t('search.startText'),
        icon: Icons.search_rounded,
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(
          screenPadding, 6, screenPadding, 40),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              t('search.recent'),
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: tok.text,
              ),
            ),
            TextButton(
              onPressed: () =>
                  ref.read(appStateProvider).clearRecentSearches(),
              child: Text(t('search.clearRecent')),
            ),
          ],
        ),
        for (final q in recent)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.history_rounded, color: tok.hint),
            title: Text(q, style: TextStyle(fontSize: 15, color: tok.text)),
            onTap: () => _use(q),
          ),
        const SizedBox(height: 16),
        Text(
          t('search.minChars', {'n': minSearchChars}),
          style: TextStyle(fontSize: 13, color: tok.hint),
        ),
      ],
    );
  }

  Widget _results() {
    final tok = yt(context);
    final key = (query: _query, sort: _sort);
    final result = ref.watch(searchProvider(key));

    return AsyncView<SearchResult>(
      value: result,
      onRetry: () => ref.invalidate(searchProvider(key)),
      data: (r) {
        if (r.shops.isEmpty && r.products.isEmpty) {
          return EmptyState(
            title: t('search.empty', {'q': _query}),
            text: t('search.emptyHint'),
            icon: Icons.search_off_rounded,
          );
        }
        return ListView(
          padding: EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, bottomBarSpace(context)),
          children: [
            Text(
              t('se.summary', {
                'q': _query,
                's': r.shops.length,
                'p': r.products.length,
              }),
              style: TextStyle(fontSize: 13, color: tok.hint),
            ),
            const SizedBox(height: 12),
            if (r.shops.isNotEmpty) ...[
              Text(
                t('search.shops'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tok.text,
                ),
              ),
              const SizedBox(height: 8),
              for (final s in r.shops) ...[
                ShopRow(shop: s, onTap: () => context.push('/shop/${s.id}')),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 8),
            ],
            if (r.products.isNotEmpty) ...[
              Text(
                t('search.products'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tok.text,
                ),
              ),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.68,
                ),
                itemCount: r.products.length,
                itemBuilder: (context, i) {
                  final hit = r.products[i];
                  final app = ref.watch(appStateProvider);
                  final qty = app.state.cart.shopId == hit.product.shopId
                      ? app.quantityOf(hit.product.id)
                      : 0;
                  return ProductGridCard(
                    product: hit.product,
                    quantity: qty,
                    canOrder: hit.shop.isOpen,
                    shopName: hit.shop.name,
                    onTap: () => showProductSheet(
                      context,
                      ref,
                      product: hit.product,
                      shopName: hit.shop.name,
                      shopOpen: hit.shop.isOpen,
                    ),
                    onAdd: () => addProductToCart(
                        context, ref, hit.product, hit.shop.name),
                    onQuantity: (v) => app.setQuantity(hit.product.id, v),
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }
}
