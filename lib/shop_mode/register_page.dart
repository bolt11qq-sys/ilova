/// "Yangi doʻkon roʻyxatdan oʻtkazish" — four steps, then the pending screen.
///
/// The map is the static picture `so-map.jpg` with a pin drawn on top, and the
/// shop photo is picked from the bundled storefronts (the demo asks for no
/// camera or gallery permission).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../core/phone.dart';
import '../core/strings_shop.dart';
import '../data/models.dart';
import '../data/seed.dart';
import '../features/widgets/buttons.dart';
import '../features/widgets/layout.dart';
import '../features/widgets/sheet.dart';
import '../state/providers.dart';

class ShopRegisterPage extends ConsumerStatefulWidget {
  const ShopRegisterPage({super.key});

  @override
  ConsumerState<ShopRegisterPage> createState() => _ShopRegisterPageState();
}

class _ShopRegisterPageState extends ConsumerState<ShopRegisterPage> {
  int _step = 0;

  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController(text: 'Chilonzor, ');
  final _fee = TextEditingController(text: '8000');
  final _min = TextEditingController(text: '30000');

  final Set<String> _cats = {S.reg.cats.first};
  String? _photo;
  String _opensAt = '07:00';
  String _closesAt = '23:00';
  bool _sunDifferent = false;
  String _sunOpensAt = '08:00';
  String _sunClosesAt = '22:00';
  bool _delivers = true;
  double _radiusKm = 1.5;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _fee.dispose();
    _min.dispose();
    super.dispose();
  }

  int _number(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  void _next() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        if (_name.text.trim().length < 2) {
          setState(() => _error = S.reg.s1.name);
          return;
        }
        if (!isValidPhone(nationalDigits(_phone.text))) {
          setState(() => _error = S.reg.s1.phone);
          return;
        }
        setState(() => _step = 1);
      case 1:
        if (_address.text.trim().length < 6) {
          setState(() => _error = S.reg.s2.address);
          return;
        }
        setState(() => _step = 2);
      case 2:
        setState(() => _step = 3);
      case 3:
        _submit();
    }
  }

  Future<void> _submit() async {
    setState(() => _busy = true);
    final id = await ref.read(shopApiProvider).registerShop(
          Registration(
            name: _name.text.trim(),
            categories: _cats
                .map((c) => regCategoryIds[c] ?? 'bakaleya')
                .toSet()
                .toList(),
            phone: toE164(nationalDigits(_phone.text)),
            address: _address.text.trim(),
            opensAt: _opensAt,
            closesAt: _closesAt,
            sunDifferent: _sunDifferent,
            sunOpensAt: _sunOpensAt,
            sunClosesAt: _sunClosesAt,
            delivers: _delivers,
            deliveryFee: _delivers ? _number(_fee) : 0,
            minOrder: _delivers ? _number(_min) : 0,
            deliveryRadiusM: _delivers ? (_radiusKm * 1000).round() : 0,
            photo: _photo,
          ),
        );
    ref.read(activeShopIdProvider.notifier).state = id;
    invalidateAll(ref);
    if (!mounted) return;
    setState(() => _busy = false);
    context.go('/shop-pending');
  }

  Future<void> _pickTime(String current, ValueChanged<String> onPicked) async {
    final parts = current.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 8,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
    );
    if (picked == null) return;
    onPicked('${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}');
  }

  Future<void> _pickPhoto() async {
    final chosen = await showChoiceSheet<String>(
      context,
      title: S.reg.s2.photo,
      selected: _photo,
      options: [
        for (var i = 0; i < pickablePhotos.length; i++)
          ChoiceOption(pickablePhotos[i], '${S.reg.s2.photo} ${i + 1}',
              icon: Icons.image_rounded),
      ],
    );
    if (chosen != null) setState(() => _photo = chosen);
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PageBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      screenPadding, 12, screenPadding, 10),
                  child: Row(
                    children: [
                      YIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => _step == 0
                            ? context.pop()
                            : setState(() => _step--),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Row(
                          children: [
                            for (var i = 0; i < 4; i++) ...[
                              Expanded(
                                child: Container(
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: i <= _step ? tok.accent : tok.card,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                              if (i < 3) const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        S.reg.of(_step + 1),
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: tok.hint,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        screenPadding, 8, screenPadding, 24),
                    child: switch (_step) {
                      0 => _step1(tok),
                      1 => _step2(tok),
                      2 => _step3(tok),
                      _ => _step4(tok),
                    },
                  ),
                ),
                BottomActionBar(
                  child: YButton(
                    label: _step == 3 ? S.common.finish : S.common.cont,
                    loading: _busy,
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _head(YTokens tok, String title, String sub) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 26,
              height: 1.15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.6,
              color: tok.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(sub, style: TextStyle(fontSize: 15, color: tok.hint)),
          const SizedBox(height: 22),
        ],
      );

  Widget _label(YTokens tok, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6, top: 16),
        child: Text(text, style: TextStyle(fontSize: 13.5, color: tok.hint)),
      );

  Widget _step1(YTokens tok) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _head(tok, S.reg.s1.title, S.reg.s1.sub),
          Text(S.reg.s1.name,
              style: TextStyle(fontSize: 13.5, color: tok.hint)),
          const SizedBox(height: 6),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(hintText: S.reg.s1.namePh),
          ),
          _label(tok, S.reg.s1.sells),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in S.reg.cats)
                ChoiceChip(
                  label: Text(c),
                  selected: _cats.contains(c),
                  onSelected: (on) => setState(() {
                    if (on) {
                      _cats.add(c);
                    } else if (_cats.length > 1) {
                      _cats.remove(c);
                    }
                  }),
                ),
            ],
          ),
          _label(tok, S.reg.s1.phone),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                child: Text('+998',
                    style: TextStyle(fontSize: 16, color: tok.hint)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0),
              hintText: '90 123 45 67',
              errorText: _error,
            ),
          ),
        ],
      );

  Widget _step2(YTokens tok) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _head(tok, S.reg.s2.title, S.reg.s2.sub),
          ClipRRect(
            borderRadius: BorderRadius.circular(YRadius.bigCard),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1.5,
                  child: Image.asset(
                    'assets/img/so-map.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: tok.card),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.place_rounded, size: 44, color: tok.accent),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: tok.surface,
                        borderRadius: BorderRadius.circular(YRadius.pill),
                      ),
                      child: Text(
                        S.reg.s2.here,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: tok.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(S.reg.s2.hint,
              style: TextStyle(fontSize: 12.5, color: tok.hint)),
          _label(tok, S.reg.s2.address),
          TextField(
            controller: _address,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(errorText: _error),
          ),
          _label(tok, S.reg.s2.photo),
          YCard(
            onTap: _pickPhoto,
            child: Row(
              children: [
                Container(
                  height: 52,
                  width: 52,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: tok.card,
                    borderRadius: BorderRadius.circular(YRadius.smallButton),
                  ),
                  child: _photo == null
                      ? Icon(Icons.add_a_photo_rounded,
                          size: 22, color: tok.hint)
                      : Image.asset(_photo!, fit: BoxFit.cover),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _photo == null ? S.reg.s2.addPhoto : S.addProduct.photoOk,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tok.text,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: tok.hint),
              ],
            ),
          ),
        ],
      );

  Widget _step3(YTokens tok) {
    Widget hours(String title, String from, String to,
            ValueChanged<String> onFrom, ValueChanged<String> onTo) =>
        YCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: tok.text,
                  ),
                ),
              ),
              _TimePill(value: from, onTap: () => _pickTime(from, onFrom)),
              const SizedBox(width: 8),
              Text('–', style: TextStyle(color: tok.hint)),
              const SizedBox(width: 8),
              _TimePill(value: to, onTap: () => _pickTime(to, onTo)),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _head(tok, S.reg.s3.title, S.reg.s3.sub),
        hours(
          S.settings.monSat,
          _opensAt,
          _closesAt,
          (v) => setState(() => _opensAt = v),
          (v) => setState(() => _closesAt = v),
        ),
        const SizedBox(height: 12),
        YCard(
          color: tok.accentSoft,
          shadow: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.reg.s3.sunDiff,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tok.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      S.reg.s3.sunDiffSub,
                      style: TextStyle(
                          fontSize: 12.5, color: tok.hint, height: 1.25),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _sunDifferent,
                onChanged: (v) => setState(() => _sunDifferent = v),
              ),
            ],
          ),
        ),
        if (_sunDifferent) ...[
          const SizedBox(height: 12),
          hours(
            S.settings.sunday,
            _sunOpensAt,
            _sunClosesAt,
            (v) => setState(() => _sunOpensAt = v),
            (v) => setState(() => _sunClosesAt = v),
          ),
        ],
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline_rounded, size: 18, color: tok.hint),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                S.reg.s3.note,
                style: TextStyle(fontSize: 12.5, color: tok.hint, height: 1.3),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _step4(YTokens tok) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _head(tok, S.reg.s4.title, S.reg.s4.sub),
          YCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.reg.s4.yes,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: tok.text,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        S.reg.s4.yesSub,
                        style: TextStyle(fontSize: 12.5, color: tok.hint),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _delivers,
                  onChanged: (v) => setState(() => _delivers = v),
                ),
              ],
            ),
          ),
          if (_delivers) ...[
            _label(tok, S.reg.s4.fee),
            TextField(
              controller: _fee,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(suffixText: S.common.som),
            ),
            _label(tok, S.reg.s4.min),
            TextField(
              controller: _min,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(suffixText: S.common.som),
            ),
            _label(tok, '${S.reg.s4.radius} ${_radiusKm.toStringAsFixed(1)} km'),
            Slider(
              value: _radiusKm,
              min: 0.5,
              max: 3,
              divisions: 25,
              label: '${_radiusKm.toStringAsFixed(1)} km',
              onChanged: (v) => setState(() => _radiusKm = v),
            ),
            const SizedBox(height: 4),
            Text(S.reg.s4.currency,
                style: TextStyle(fontSize: 12.5, color: tok.hint)),
          ],
        ],
      );
}

class _TimePill extends StatelessWidget {
  const _TimePill({required this.value, required this.onTap});

  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return InkWell(
      borderRadius: BorderRadius.circular(YRadius.smallButton),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: tok.card,
          borderRadius: BorderRadius.circular(YRadius.smallButton),
          border: Border.all(color: tok.border),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: tok.text,
          ),
        ),
      ),
    );
  }
}

/// "Arizangiz qabul qilindi" — the shop is pending until an admin approves it.
class ShopPendingPage extends ConsumerWidget {
  const ShopPendingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          child: Column(
            children: [
              AppBar(title: Text(S.appTitle)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      screenPadding, 12, screenPadding, 40),
                  children: [
                    Center(
                      child: Image.asset(
                        'assets/img/so-pending.png',
                        height: 190,
                        errorBuilder: (_, __, ___) => Icon(
                            Icons.hourglass_top_rounded,
                            size: 110,
                            color: tok.warn),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      S.reg.pendingTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: tok.text,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      S.reg.pendingText,
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 15, color: tok.hint, height: 1.4),
                    ),
                    const SizedBox(height: 22),
                    YCard(
                      color: tok.accentSoft,
                      shadow: false,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            S.reg.tipTitle,
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: tok.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            S.reg.tipText,
                            style: TextStyle(
                                fontSize: 13, color: tok.hint, height: 1.35),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    YButton(
                      label: S.reg.addProducts,
                      icon: Icons.add_rounded,
                      onPressed: () => context.go('/shop-mode/products'),
                    ),
                    const SizedBox(height: 10),
                    YButton(
                      label: S.nav.panel,
                      variant: YButtonVariant.grey,
                      onPressed: () => context.go('/shop-mode/panel'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
