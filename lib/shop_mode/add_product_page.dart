/// "Mahsulot qoʻshish": from the shared catalog (set only the price) or a
/// custom product.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/format.dart';
import '../core/strings_shop.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../features/widgets/buttons.dart';
import '../features/widgets/layout.dart';
import '../features/widgets/photo.dart';
import '../features/widgets/sheet.dart';
import '../features/widgets/states.dart';
import '../features/widgets/toast.dart';
import '../state/providers.dart';

class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({super.key});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppBar(title: Text(S.addProduct.title)),
              TabBar(
                controller: _tabs,
                labelColor: tok.accent,
                unselectedLabelColor: tok.hint,
                indicatorColor: tok.accent,
                tabs: [
                  Tab(text: S.addProduct.tabCatalog),
                  Tab(text: S.addProduct.tabOwn),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: const [_CatalogTab(), _CustomTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogTab extends ConsumerStatefulWidget {
  const _CatalogTab();

  @override
  ConsumerState<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends ConsumerState<_CatalogTab> {
  final _query = TextEditingController();
  List<CatalogHit> _hits = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    final shopId = ref.read(activeShopIdProvider);
    final hits =
        await ref.read(shopApiProvider).searchCatalog(shopId, _query.text);
    if (!mounted) return;
    setState(() {
      _hits = hits;
      _loading = false;
    });
  }

  Future<void> _add(CatalogHit hit) async {
    final price = await showPriceInput(context, hit.name, hit.basePrice);
    if (price == null || !mounted) return;
    final shopId = ref.read(activeShopIdProvider);
    await ref.read(shopApiProvider).addFromCatalog(shopId, hit.id, price);
    ref.invalidate(shopProductsOwnProvider);
    ref.invalidate(shopStatsProvider);
    invalidateAll(ref);
    if (!mounted) return;
    await _search();
    if (!mounted) return;
    showToast(context, S.products.nowHave(hit.name), kind: ToastKind.success);
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              screenPadding, 12, screenPadding, 8),
          child: TextField(
            controller: _query,
            onChanged: (_) => _search(),
            decoration: InputDecoration(
              hintText: S.addProduct.search,
              prefixIcon: Icon(Icons.search_rounded, color: tok.hint),
            ),
          ),
        ),
        Padding(
          padding:
              const EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '${S.addProduct.found(_hits.length)} · ${S.addProduct.hint}',
                  style:
                      TextStyle(fontSize: 12.5, color: tok.hint, height: 1.3),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _loading
              ? const SkeletonList(count: 5, height: 60)
              : ListView.separated(
                  padding: EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, bottomBarSpace(context)),
                  itemCount: _hits.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final hit = _hits[i];
                    return YCard(
                      padding: const EdgeInsets.all(10),
                      onTap: hit.has ? null : () => _add(hit),
                      child: Row(
                        children: [
                          ProductPhoto(
                              photo: hit.photo, emoji: hit.emoji, size: 44),
                          const SizedBox(width: 11),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  hit.name,
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
                                  '${S.addProduct.category(categoryName(hit.categoryId))} · '
                                  '${formatPrice(hit.basePrice)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 12.5, color: tok.hint),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (hit.has)
                            Text(
                              S.addProduct.alreadyHave,
                              style:
                                  TextStyle(fontSize: 12.5, color: tok.hint),
                            )
                          else
                            YButton(
                              label: S.common.add,
                              small: true,
                              expand: false,
                              onPressed: () => _add(hit),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// Asks for a price. Returns null when cancelled.
Future<int?> showPriceInput(
    BuildContext context, String name, int suggested) {
  return showYSheet<int>(
    context: context,
    builder: (context) => _PriceInput(name: name, suggested: suggested),
  );
}

class _PriceInput extends StatefulWidget {
  const _PriceInput({required this.name, required this.suggested});

  final String name;
  final int suggested;

  @override
  State<_PriceInput> createState() => _PriceInputState();
}

class _PriceInputState extends State<_PriceInput> {
  late final TextEditingController _controller =
      TextEditingController(text: '${widget.suggested}');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SheetBody(
      bottom: YButton(
        label: S.common.add,
        onPressed: () {
          final value =
              int.tryParse(_controller.text.replaceAll(RegExp(r'\D'), ''));
          Navigator.of(context).pop(value != null && value > 0 ? value : null);
        },
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: S.addProduct.yourPrice, subtitle: widget.name),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            child: TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              decoration: InputDecoration(suffixText: S.common.som),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _CustomTab extends ConsumerStatefulWidget {
  const _CustomTab();

  @override
  ConsumerState<_CustomTab> createState() => _CustomTabState();
}

class _CustomTabState extends ConsumerState<_CustomTab> {
  final _name = TextEditingController();
  final _price = TextEditingController();
  String _unit = 'dona';
  String _category = categories.first.id;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'\D'), ''));
    if (name.length < 2 || price == null || price <= 0) {
      setState(() => _error = S.common.error);
      return;
    }
    setState(() => _busy = true);
    final shopId = ref.read(activeShopIdProvider);
    await ref.read(shopApiProvider).createCustom(
          shopId,
          name: name,
          unit: _unit,
          categoryId: _category,
          price: price,
        );
    ref.invalidate(shopProductsOwnProvider);
    invalidateAll(ref);
    if (!mounted) return;
    setState(() => _busy = false);
    showToast(context, S.products.nowHave(name), kind: ToastKind.success);
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return ListView(
      padding:
          EdgeInsets.fromLTRB(screenPadding, 14, screenPadding, bottomBarSpace(context)),
      children: [
        Text(S.addProduct.name,
            style: TextStyle(fontSize: 13.5, color: tok.hint)),
        const SizedBox(height: 6),
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(hintText: S.addProduct.namePh),
        ),
        const SizedBox(height: 14),
        Text(S.addProduct.unit,
            style: TextStyle(fontSize: 13.5, color: tok.hint)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          children: [
            for (final u in const ['dona', 'kg', 'l', 'quti'])
              ChoiceChip(
                label: Text(u),
                selected: _unit == u,
                onSelected: (_) => setState(() => _unit = u),
              ),
          ],
        ),
        const SizedBox(height: 14),
        Text(S.addProduct.categoryLbl,
            style: TextStyle(fontSize: 13.5, color: tok.hint)),
        const SizedBox(height: 6),
        YCard(
          padding: EdgeInsets.zero,
          color: tok.card,
          shadow: false,
          radius: YRadius.button,
          child: DropdownButtonHideUnderline(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButton<String>(
                value: _category,
                isExpanded: true,
                items: [
                  for (final c in categories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(S.addProduct.priceLbl,
            style: TextStyle(fontSize: 13.5, color: tok.hint)),
        const SizedBox(height: 6),
        TextField(
          controller: _price,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            suffixText: S.common.som,
            errorText: _error,
          ),
        ),
        const SizedBox(height: 22),
        YButton(label: S.common.add, loading: _busy, onPressed: _save),
      ],
    );
  }
}
