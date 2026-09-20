/// Address sheets: pick a saved address, or add and edit one.
///
/// "Joylashuvimni aniqlash" is simulated in the demo (no location permission,
/// no INTERNET permission) — see DECISIONS.md.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/geo.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/providers.dart';
import '../widgets/buttons.dart';
import '../widgets/layout.dart';
import '../widgets/sheet.dart';
import '../widgets/toast.dart';

const Map<AddressLabel, String> addressLabelNames = {
  AddressLabel.home: 'address.label.home',
  AddressLabel.work: 'address.label.work',
  AddressLabel.other: 'address.label.other',
};

IconData addressLabelIcon(AddressLabel label) => switch (label) {
      AddressLabel.home => Icons.home_rounded,
      AddressLabel.work => Icons.work_rounded,
      AddressLabel.other => Icons.place_rounded,
    };

/// The picker: saved addresses plus "Manzil qoʻshish".
Future<void> showAddressSheet(BuildContext context, WidgetRef ref) {
  return showYSheet<void>(
    context: context,
    builder: (sheetContext) => Consumer(
      builder: (context, ref, _) {
        final app = ref.watch(appStateProvider);
        final tok = yt(context);
        final state = app.state;
        return SheetBody(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SheetHeader(title: t('address.sheetTitle')),
              for (final a in state.addresses)
                ListTile(
                  leading: Icon(addressLabelIcon(a.label), color: tok.hint),
                  title: Text(
                    a.oneLine,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: a.id == state.activeAddress?.id
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: a.id == state.activeAddress?.id
                          ? tok.accentInk
                          : tok.text,
                    ),
                  ),
                  subtitle: a.landmark.isEmpty
                      ? null
                      : Text(t('sv.landmark', {'v': a.landmark}),
                          style: TextStyle(fontSize: 13, color: tok.hint)),
                  trailing: a.id == state.activeAddress?.id
                      ? Icon(Icons.check_rounded, color: tok.accent)
                      : null,
                  onTap: () {
                    app.setActiveAddress(a.id);
                    Navigator.of(context).pop();
                  },
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    screenPadding, 10, screenPadding, screenPadding),
                child: YButton(
                  label: t('address.add'),
                  icon: Icons.add_rounded,
                  variant: YButtonVariant.mint,
                  onPressed: () async {
                    if (state.addresses.length >= maxAddresses) {
                      showToast(
                        context,
                        t('address.max', {'n': maxAddresses}),
                        kind: ToastKind.error,
                      );
                      return;
                    }
                    // Keep the picker alive while the form is open, then close
                    // both with a navigator captured before the await.
                    final navigator = Navigator.of(context);
                    await showAddressForm(context, ref);
                    navigator.pop();
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// The add/edit form. Returns the saved address, or null when cancelled.
Future<Address?> showAddressForm(
  BuildContext context,
  WidgetRef ref, {
  Address? existing,
}) {
  return showYSheet<Address>(
    context: context,
    builder: (context) => _AddressForm(existing: existing),
  );
}

class _AddressForm extends ConsumerStatefulWidget {
  const _AddressForm({this.existing});

  final Address? existing;

  @override
  ConsumerState<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends ConsumerState<_AddressForm> {
  late AddressLabel _label = widget.existing?.label ?? AddressLabel.home;
  late String _district = widget.existing?.district ?? districts.first.name;
  late final TextEditingController _street =
      TextEditingController(text: widget.existing?.street ?? '');
  late final TextEditingController _apartment =
      TextEditingController(text: widget.existing?.apartment ?? '');
  late final TextEditingController _landmark =
      TextEditingController(text: widget.existing?.landmark ?? '');
  Coords? _detected;
  String? _error;
  bool _detecting = false;

  @override
  void dispose() {
    _street.dispose();
    _apartment.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);
    // The demo has no location permission: it drops the pin in the service
    // area so the flow can be shown end to end.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _detected = serviceCenter;
      _district = nearestDistrict(serviceCenter).name;
    });
    showToast(context, t('address.detected'));
  }

  void _save() {
    final street = _street.text.trim();
    if (street.length < 4) {
      setState(() => _error = t('address.tooShort'));
      return;
    }
    final app = ref.read(appStateProvider);
    final address = app.buildAddress(
      id: widget.existing?.id,
      label: _label,
      district: _district,
      street: street,
      apartment: _apartment.text.trim(),
      landmark: _landmark.text.trim(),
      isDefault: widget.existing?.isDefault ?? false,
      detected: _detected,
    );
    if (widget.existing == null) {
      final problem = app.addAddress(address);
      if (problem != null) {
        showToast(context, t('address.max', {'n': maxAddresses}),
            kind: ToastKind.error);
        return;
      }
    } else {
      app.updateAddress(address);
    }
    Navigator.of(context).pop(address);
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return SheetBody(
      bottom: YButton(label: t('common.save'), onPressed: _save),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(
            title: widget.existing == null
                ? t('address.add')
                : t('address.edit'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                YButton(
                  label: t('address.detect'),
                  icon: Icons.my_location_rounded,
                  variant: YButtonVariant.mint,
                  loading: _detecting,
                  onPressed: _detect,
                ),
                const SizedBox(height: 16),
                _FieldLabel(t('address.labelTitle')),
                const SizedBox(height: 6),
                Row(
                  children: [
                    for (final l in AddressLabel.values) ...[
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _label = l),
                          child: Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: _label == l ? tok.accentSoft : tok.card,
                              borderRadius:
                                  BorderRadius.circular(YRadius.smallButton),
                              border: Border.all(
                                color: _label == l ? tok.accent : tok.border,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(addressLabelIcon(l),
                                    size: 17,
                                    color: _label == l
                                        ? tok.accentInk
                                        : tok.hint),
                                const SizedBox(width: 6),
                                Text(
                                  t(addressLabelNames[l]!),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: _label == l
                                        ? tok.accentInk
                                        : tok.text,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (l != AddressLabel.values.last)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                _FieldLabel(t('address.district')),
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
                        value: _district,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(YRadius.button),
                        items: [
                          for (final d in districts)
                            DropdownMenuItem(value: d.name, child: Text(d.name)),
                        ],
                        onChanged: (v) =>
                            setState(() => _district = v ?? _district),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _FieldLabel(t('address.street')),
                const SizedBox(height: 6),
                TextField(
                  controller: _street,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: t('address.streetPlaceholder'),
                    errorText: _error,
                  ),
                  onChanged: (_) {
                    if (_error != null) setState(() => _error = null);
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(t('address.apartment')),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _apartment,
                            keyboardType: TextInputType.text,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _FieldLabel(t('address.landmark')),
                          const SizedBox(height: 6),
                          TextField(
                            controller: _landmark,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: t('address.landmarkPlaceholder'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Text(
      text,
      style: TextStyle(
        fontSize: 13.5,
        fontWeight: FontWeight.w600,
        color: tok.hint,
      ),
    );
  }
}
