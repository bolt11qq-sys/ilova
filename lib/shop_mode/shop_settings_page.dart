/// "Sozlamalar": shop details, delivery, opening hours, vacation, staff, the
/// tariff card and the demo actions (including the way back to the buyer app).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/theme.dart';
import '../core/phone.dart';
import '../core/strings_shop.dart';
import '../data/mock_shop_api.dart';
import '../data/models.dart';
import '../features/widgets/buttons.dart';
import '../features/widgets/layout.dart';
import '../features/widgets/states.dart';
import '../features/widgets/toast.dart';
import '../state/providers.dart';
import 'shop_sheets.dart';

class ShopSettingsPage extends ConsumerWidget {
  const ShopSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(shopSettingsProvider);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              AppBar(title: Text(S.settings.title)),
              Expanded(
                child: AsyncView<ShopSettingsData>(
                  value: settings,
                  onRetry: () => ref.invalidate(shopSettingsProvider),
                  data: (s) => _SettingsBody(settings: s),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsBody extends ConsumerStatefulWidget {
  const _SettingsBody({required this.settings});

  final ShopSettingsData settings;

  @override
  ConsumerState<_SettingsBody> createState() => _SettingsBodyState();
}

class _SettingsBodyState extends ConsumerState<_SettingsBody> {
  late final TextEditingController _name =
      TextEditingController(text: widget.settings.name);
  late final TextEditingController _phone = TextEditingController(
      text: maskNational(nationalDigits(widget.settings.phone)));
  late final TextEditingController _fee =
      TextEditingController(text: '${widget.settings.deliveryFee}');
  late final TextEditingController _min =
      TextEditingController(text: '${widget.settings.minOrder}');
  late final TextEditingController _time =
      TextEditingController(text: widget.settings.deliveryTimeText);

  late bool _delivers = widget.settings.delivers;
  late bool _vacation = widget.settings.vacation;
  late bool _sunDifferent = widget.settings.sunDifferent;
  late double _radiusKm = widget.settings.deliveryRadiusM / 1000;
  late String _opensAt = widget.settings.opensAt;
  late String _closesAt = widget.settings.closesAt;
  late String _sunOpensAt = widget.settings.sunOpensAt;
  late String _sunClosesAt = widget.settings.sunClosesAt;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _fee.dispose();
    _min.dispose();
    _time.dispose();
    super.dispose();
  }

  int _number(TextEditingController c) =>
      int.tryParse(c.text.replaceAll(RegExp(r'\D'), '')) ?? 0;

  Future<void> _save() async {
    setState(() => _busy = true);
    final digits = nationalDigits(_phone.text);
    await ref.read(shopApiProvider).saveSettings(
          widget.settings.id,
          name: _name.text.trim(),
          phone: digits.length == 9 ? toE164(digits) : null,
          delivers: _delivers,
          deliveryFee: _number(_fee),
          minOrder: _number(_min),
          deliveryRadiusM: (_radiusKm * 1000).round(),
          deliveryTimeText: _time.text.trim(),
          opensAt: _opensAt,
          closesAt: _closesAt,
          sunDifferent: _sunDifferent,
          sunOpensAt: _sunOpensAt,
          sunClosesAt: _sunClosesAt,
          vacation: _vacation,
        );
    ref.invalidate(shopSettingsProvider);
    invalidateAll(ref);
    if (!mounted) return;
    setState(() => _busy = false);
    showToast(context, S.settings.saved, kind: ToastKind.success);
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

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final s = widget.settings;

    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 14),
          child: Text(text,
              style: TextStyle(fontSize: 13.5, color: tok.hint)),
        );

    Widget sectionTitle(String text) => Padding(
          padding: const EdgeInsets.only(top: 22, bottom: 10),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: tok.text,
            ),
          ),
        );

    Widget hoursRow(String title, String from, String to,
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
              _TimeBox(value: from, onTap: () => _pickTime(from, onFrom)),
              const SizedBox(width: 8),
              Text('–', style: TextStyle(color: tok.hint)),
              const SizedBox(width: 8),
              _TimeBox(value: to, onTap: () => _pickTime(to, onTo)),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsets.fromLTRB(screenPadding, 0, screenPadding, 120),
      children: [
        sectionTitle(S.settings.info),
        label(S.settings.name),
        TextField(controller: _name),
        label(S.settings.phone),
        TextField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
              child:
                  Text('+998', style: TextStyle(fontSize: 16, color: tok.hint)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
          ),
        ),
        sectionTitle(S.settings.delivery),
        YCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  S.settings.selfDeliver,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tok.text,
                  ),
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
          label(S.settings.fee),
          TextField(
            controller: _fee,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(suffixText: S.common.som),
          ),
          label(S.settings.min),
          TextField(
            controller: _min,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(suffixText: S.common.som),
          ),
          label(S.settings.time),
          TextField(
            controller: _time,
            decoration: InputDecoration(hintText: S.settings.minutesHint),
          ),
          label('${S.settings.radius}: ${_radiusKm.toStringAsFixed(1)} km'),
          Slider(
            value: _radiusKm.clamp(0.5, 3),
            min: 0.5,
            max: 3,
            divisions: 25,
            label: '${_radiusKm.toStringAsFixed(1)} km',
            onChanged: (v) => setState(() => _radiusKm = v),
          ),
        ],
        sectionTitle(S.settings.hours),
        hoursRow(
          S.settings.monSat,
          _opensAt,
          _closesAt,
          (v) => setState(() => _opensAt = v),
          (v) => setState(() => _closesAt = v),
        ),
        const SizedBox(height: 10),
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
                    const SizedBox(height: 2),
                    Text(
                      S.reg.s3.sunDiffSub,
                      style:
                          TextStyle(fontSize: 12.5, color: tok.hint, height: 1.25),
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
          const SizedBox(height: 10),
          hoursRow(
            S.settings.sunday,
            _sunOpensAt,
            _sunClosesAt,
            (v) => setState(() => _sunOpensAt = v),
            (v) => setState(() => _sunClosesAt = v),
          ),
        ],
        const SizedBox(height: 12),
        YCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.settings.vacation,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tok.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      S.settings.vacationSub,
                      style: TextStyle(fontSize: 12.5, color: tok.hint),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _vacation,
                onChanged: (v) => setState(() => _vacation = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        YButton(label: S.common.save, loading: _busy, onPressed: _save),
        sectionTitle(S.settings.staff),
        _StaffList(),
        const SizedBox(height: 10),
        YButton(
          label: S.settings.invite,
          icon: Icons.person_add_alt_rounded,
          variant: YButtonVariant.mint,
          onPressed: () => showInviteSheet(context, ref),
        ),
        sectionTitle(S.settings.tariff),
        YCard(
          color: tok.mint,
          shadow: false,
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded,
                  size: 26, color: tok.accentInk),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${S.settings.tariffName} · ${S.settings.tariffFree}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: tok.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      S.settings.tariffText,
                      style: TextStyle(fontSize: 12.5, color: tok.hint),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        sectionTitle(S.settings.demo),
        YCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              YRow(
                icon: Icons.add_business_rounded,
                title: S.settings.newShop,
                onTap: () => context.push('/shop-register'),
              ),
              Divider(height: 1, color: tok.border),
              YRow(
                icon: Icons.swap_horiz_rounded,
                title: S.settings.backToDemo,
                onTap: () {
                  ref.read(shopApiProvider).setActiveShop(demoShopId);
                  ref.read(activeShopIdProvider.notifier).state = demoShopId;
                  invalidateAll(ref);
                },
              ),
              if (s.pending) ...[
                Divider(height: 1, color: tok.border),
                YRow(
                  icon: Icons.verified_rounded,
                  title: S.settings.approve,
                  onTap: () async {
                    await ref.read(shopApiProvider).approveShop(s.id);
                    ref.invalidate(shopSettingsProvider);
                    invalidateAll(ref);
                    if (context.mounted) {
                      showToast(context, S.settings.approved,
                          kind: ToastKind.success);
                    }
                  },
                ),
              ],
              Divider(height: 1, color: tok.border),
              YRow(
                icon: Icons.exit_to_app_rounded,
                title: S.settings.backToBuyer,
                subtitle: S.settings.backToBuyerSub,
                onTap: () => context.go('/'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '${S.appTitle} 1.0',
            style: TextStyle(fontSize: 12, color: tok.hint),
          ),
        ),
      ],
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.value, required this.onTap});

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

class _StaffList extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final staff = ref.watch(staffProvider);
    return staff.when(
      loading: () => const Skeleton(height: 60, radius: YRadius.card),
      error: (_, __) => const SizedBox.shrink(),
      data: (list) => YCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) Divider(height: 1, color: tok.border),
              YRow(
                icon: list[i].owner
                    ? Icons.workspace_premium_rounded
                    : Icons.person_rounded,
                title: list[i].name,
                subtitle: list[i].role,
                trailing: list[i].owner
                    ? null
                    : IconButton(
                        icon: Icon(Icons.close_rounded, color: tok.hint),
                        onPressed: () async {
                          await ref
                              .read(shopApiProvider)
                              .removeStaff(list[i].id);
                          ref.invalidate(staffProvider);
                        },
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
