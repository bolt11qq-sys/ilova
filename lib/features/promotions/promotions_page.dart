/// "Aksiyalar" — every active promotion of open shops in range, biggest
/// discount first.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../sheets/cart_sheets.dart';
import '../widgets/chips.dart';
import '../widgets/layout.dart';
import '../widgets/product_cards.dart';
import '../widgets/states.dart';

class PromotionsPage extends ConsumerStatefulWidget {
  const PromotionsPage({super.key});

  @override
  ConsumerState<PromotionsPage> createState() => _PromotionsPageState();
}

class _PromotionsPageState extends ConsumerState<PromotionsPage> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final hits = ref.watch(promotionsProvider(_category));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(title: Text(t('nav.promotions'))),
              hits.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (list) => Padding(
                  padding: const EdgeInsets.fromLTRB(
                      screenPadding, 0, screenPadding, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('promos.summary', {'n': list.length}),
                        style: TextStyle(fontSize: 14.5, color: tok.text),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        t('pr.sorted'),
                        style: TextStyle(fontSize: 12.5, color: tok.hint),
                      ),
                    ],
                  ),
                ),
              ),
              CategoryChips(
                selected: _category,
                onSelect: (c) => setState(() => _category = c),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: AsyncView<List<ProductHit>>(
                  value: hits,
                  onRetry: () =>
                      ref.invalidate(promotionsProvider(_category)),
                  data: (list) {
                    if (list.isEmpty) {
                      return EmptyState(
                        title: t('promos.empty'),
                        text: t('promos.emptyText'),
                        icon: Icons.local_offer_rounded,
                      );
                    }
                    final now = DateTime.now().millisecondsSinceEpoch;
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          screenPadding, 0, screenPadding, 110),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.63,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) => PromoCard(
                        hit: list[i],
                        now: now,
                        onTap: () => showProductSheet(
                          context,
                          ref,
                          product: list[i].product,
                          shopName: list[i].shop.name,
                          shopOpen: list[i].shop.isOpen,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
