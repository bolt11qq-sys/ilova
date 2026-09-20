/// First launch: welcome → phone → name → address.
///
/// The Telegram `requestContact()` step has no Android equivalent, so only the
/// manual `+998` input is offered and the profile stays "Tasdiqlanmagan".
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/geo.dart';
import '../../core/phone.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import '../../state/providers.dart';
import '../widgets/buttons.dart';
import '../widgets/layout.dart';
import '../widgets/toast.dart';

/// Formats what the user types as `90 123 45 67`.
class PhoneMaskFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final masked = maskNational(nationalDigits(newValue.text));
    return TextEditingValue(
      text: masked,
      selection: TextSelection.collapsed(offset: masked.length),
    );
  }
}

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  final _phone = TextEditingController();
  final _name = TextEditingController();
  final _street = TextEditingController();
  final _apartment = TextEditingController();
  final _landmark = TextEditingController();

  String _district = districts.first.name;
  Coords? _detected;
  String? _error;
  bool _detecting = false;
  bool _showOutside = false;
  bool _joining = false;

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _street.dispose();
    _apartment.dispose();
    _landmark.dispose();
    super.dispose();
  }

  void _back() {
    if (_showOutside) {
      setState(() => _showOutside = false);
      return;
    }
    if (_step == 0) return;
    setState(() {
      _step--;
      _error = null;
    });
  }

  void _next() {
    setState(() => _error = null);
    switch (_step) {
      case 0:
        setState(() => _step = 1);
      case 1:
        final digits = nationalDigits(_phone.text);
        if (!isValidPhone(digits)) {
          setState(() => _error = t('onb.phone.invalid'));
          return;
        }
        ref.read(appStateProvider).setUser(phone: toE164(digits));
        setState(() => _step = 2);
      case 2:
        final name = _name.text.trim();
        if (name.length < 2 || name.length > 30) {
          setState(() => _error = t('onb.name.invalid'));
          return;
        }
        ref.read(appStateProvider).setUser(firstName: name);
        setState(() => _step = 3);
      case 3:
        _finishAddress();
    }
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);
    // No location permission in the demo: the pin lands in the service area.
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _detecting = false;
      _detected = serviceCenter;
      _district = nearestDistrict(serviceCenter).name;
    });
    showToast(context, t('address.detected'));
  }

  void _finishAddress() {
    final street = _street.text.trim();
    if (street.length < 4) {
      setState(() => _error = t('address.tooShort'));
      return;
    }
    final app = ref.read(appStateProvider);
    final address = app.buildAddress(
      label: AddressLabel.home,
      district: _district,
      street: street,
      apartment: _apartment.text.trim(),
      landmark: _landmark.text.trim(),
      isDefault: true,
      detected: _detected,
    );
    if (!isInServiceArea(address.coords)) {
      setState(() => _showOutside = true);
      return;
    }
    app.addAddress(address);
    _done();
  }

  void _done() {
    final app = ref.read(appStateProvider);
    app.finishOnboarding();
    ref.read(serverProvider).onboard();
    if (mounted) context.go('/');
  }

  Future<void> _joinWaitlist() async {
    setState(() => _joining = true);
    await ref.read(serverProvider).joinWaitlist(_district);
    if (!mounted) return;
    setState(() => _joining = false);
    showToast(context, t('onb.waitlistDone'), kind: ToastKind.success);
    _browseAnyway();
  }

  void _browseAnyway() {
    final app = ref.read(appStateProvider);
    final address = app.buildAddress(
      label: AddressLabel.home,
      district: _district,
      street: _street.text.trim(),
      apartment: _apartment.text.trim(),
      landmark: _landmark.text.trim(),
      isDefault: true,
      detected: _detected,
    );
    app.addAddress(address);
    _done();
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return PopScope(
      canPop: _step == 0 && !_showOutside,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: PageBackground(
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      screenPadding, 12, screenPadding, 8),
                  child: Row(
                    children: [
                      if (_step > 0 || _showOutside)
                        YIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: _back,
                          tooltip: t('common.back'),
                        )
                      else
                        const SizedBox(width: 40),
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
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                        screenPadding, 12, screenPadding, 24),
                    child: _showOutside ? _outside(tok) : _stepBody(tok),
                  ),
                ),
                _bottom(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottom() {
    if (_showOutside) {
      return BottomActionBar(
        child: Column(
          children: [
            YButton(
              label: t('onb.outside.wait'),
              loading: _joining,
              onPressed: _joinWaitlist,
            ),
            const SizedBox(height: 10),
            YButton(
              label: t('onb.outside.browse'),
              variant: YButtonVariant.grey,
              onPressed: _joining ? null : _browseAnyway,
            ),
          ],
        ),
      );
    }
    final label = switch (_step) {
      0 => t('onb.welcome.cta'),
      3 => t('onb.address.done'),
      _ => t('common.continue'),
    };
    return BottomActionBar(child: YButton(label: label, onPressed: _next));
  }

  Widget _stepBody(YTokens tok) {
    switch (_step) {
      case 0:
        return _welcome(tok);
      case 1:
        return _phoneStep(tok);
      case 2:
        return _nameStep(tok);
      default:
        return _addressStep(tok);
    }
  }

  Widget _title(YTokens tok, String title, String text) => Column(
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
          const SizedBox(height: 10),
          Text(
            text,
            style: TextStyle(fontSize: 15.5, color: tok.hint, height: 1.4),
          ),
          const SizedBox(height: 24),
        ],
      );

  Widget _welcome(YTokens tok) {
    Widget benefit(IconData icon, String text) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: tok.accentSoft,
                  borderRadius: BorderRadius.circular(YRadius.smallButton),
                ),
                child: Icon(icon, size: 21, color: tok.accentInk),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: tok.text,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Center(
          child: Image.asset(
            'assets/img/basket.png',
            height: 190,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.shopping_basket_rounded, size: 110, color: tok.accent),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t('onb.welcome.title'),
          style: TextStyle(
            fontSize: 28,
            height: 1.12,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.7,
            color: tok.text,
          ),
        ),
        const SizedBox(height: 22),
        benefit(Icons.storefront_rounded, t('onb.welcome.b1')),
        benefit(Icons.local_offer_rounded, t('onb.welcome.b2')),
        benefit(Icons.delivery_dining_rounded, t('onb.welcome.b3')),
        const SizedBox(height: 10),
        Text(
          t('onb.terms.before'),
          style: TextStyle(fontSize: 12.5, color: tok.hint),
        ),
        const SizedBox(height: 4),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _LegalLink(label: t('profile.terms'), doc: 'terms'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(t('onb.terms.and'),
                  style: TextStyle(fontSize: 12.5, color: tok.hint)),
            ),
            _LegalLink(label: t('profile.privacy'), doc: 'privacy'),
          ],
        ),
      ],
    );
  }

  Widget _phoneStep(YTokens tok) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(tok, t('onb.phone.title'), t('onb.phone.text')),
        Text(
          t('onb.phone.label'),
          style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: tok.hint),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _phone,
          autofocus: true,
          keyboardType: TextInputType.phone,
          inputFormatters: [PhoneMaskFormatter()],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            prefixIcon: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
              child: Text(
                '+998',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: tok.hint,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0),
            hintText: '90 123 45 67',
            errorText: _error,
          ),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
      ],
    );
  }

  Widget _nameStep(YTokens tok) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(tok, t('onb.name.title'), t('onb.name.text')),
        Text(
          t('onb.name.label'),
          style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: tok.hint),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _name,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          decoration: InputDecoration(errorText: _error),
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
        ),
      ],
    );
  }

  Widget _addressStep(YTokens tok) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(tok, t('onb.address.title'), t('onb.address.text')),
        YButton(
          label: t('address.detect'),
          icon: Icons.my_location_rounded,
          variant: YButtonVariant.mint,
          loading: _detecting,
          onPressed: _detect,
        ),
        const SizedBox(height: 18),
        Text(
          t('onb.address.manual'),
          style: TextStyle(
              fontSize: 13.5, fontWeight: FontWeight.w600, color: tok.hint),
        ),
        const SizedBox(height: 10),
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
                onChanged: (v) => setState(() => _district = v ?? _district),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _apartment,
                decoration:
                    InputDecoration(hintText: t('address.apartment')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _landmark,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                    hintText: t('address.landmarkPlaceholder')),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _outside(YTokens tok) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Center(
          child: Image.asset(
            'assets/img/outside.png',
            height: 190,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.explore_off_rounded, size: 110, color: tok.hint),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          t('onb.outside.title'),
          style: TextStyle(
            fontSize: 24,
            height: 1.15,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: tok.text,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          t('onb.outside.text', {'district': _district}),
          style: TextStyle(fontSize: 15.5, color: tok.hint, height: 1.4),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  const _LegalLink({required this.label, required this.doc});

  final String label;
  final String doc;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return GestureDetector(
      onTap: () => context.push('/legal/$doc'),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.5,
          color: tok.accent,
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
          decorationColor: tok.accent,
        ),
      ),
    );
  }
}
