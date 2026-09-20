/// One category across every shop in range.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/models.dart';
import '../../data/seed.dart';
import '../../core/strings_buyer.dart';
import '../../state/providers.dart';
import '../sheets/cart_sheets.dart';
import '../widgets/layout.dart';
import '../widgets/product_cards.dart';
import '../widgets/states.dart';

class CategoryPage extends ConsumerWidget {
  const CategoryPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hits = ref.watch(categoryProductsProvider(categoryId));
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppBar(title: Text(categoryName(categoryId))),
              Expanded(
                child: AsyncView<List<ProductHit>>(
                  value: hits,
                  onRetry: () =>
                      ref.invalidate(categoryProductsProvider(categoryId)),
                  data: (list) {
                    if (list.isEmpty) {
                      return EmptyState(
                        title: t('cat.empty'),
                        icon: Icons.inventory_2_rounded,
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                          screenPadding, 4, screenPadding, 110),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.68,
                      ),
                      itemCount: list.length,
                      itemBuilder: (context, i) {
                        final hit = list[i];
                        final app = ref.watch(appStateProvider);
                        final cart = app.state.cart;
                        final qty = cart.shopId == hit.product.shopId
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
                          onQuantity: (v) =>
                              app.setQuantity(hit.product.id, v),
                        );
                      },
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
