/// "Profil": the buyer, the saved addresses, the legal pages, the shop-mode
/// invitation and "Hisobni oʻchirish".
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/phone.dart';
import '../../core/strings_buyer.dart';
import '../../data/models.dart';
import '../../state/app_state.dart';
import '../../state/providers.dart';
import '../onboarding/onboarding_page.dart' show PhoneMaskFormatter;
import '../sheets/address_sheet.dart';
import '../sheets/support_sheet.dart';
import '../widgets/buttons.dart';
import '../widgets/layout.dart';
import '../widgets/sheet.dart';
import '../widgets/status_tag.dart';
import '../widgets/toast.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final app = ref.watch(appStateProvider);
    final state = app.state;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: EdgeInsets.fromLTRB(screenPadding, 12, screenPadding, bottomBarSpace(context)),
            children: [
              Text(
                t('pf.title'),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: tok.text,
                ),
              ),
              const SizedBox(height: 14),
              YCard(
                child: Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: tok.accentSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          state.user.firstName.isEmpty
                              ? '?'
                              : state.user.firstName
                                  .substring(0, 1)
                                  .toUpperCase(),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: tok.accentInk,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.user.firstName.isEmpty
                                ? t('onb.name.label')
                                : state.user.firstName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: tok.text,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  displayPhone(state.user.phone),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 13.5, color: tok.hint),
                                ),
                              ),
                              const SizedBox(width: 8),
                              StatusTag(
                                label: state.user.phoneVerified
                                    ? t('pf.verified')
                                    : t('profile.unverified'),
                                tone: state.user.phoneVerified
                                    ? TagTone.success
                                    : TagTone.neutral,
                                small: true,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    YButton(
                      label: t('pf.edit'),
                      small: true,
                      expand: false,
                      variant: YButtonVariant.grey,
                      onPressed: () => _editProfile(context, ref),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: sectionGap),
              Text(
                t('pf.addresses'),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: tok.text,
                ),
              ),
              const SizedBox(height: 8),
              for (final a in state.addresses) ...[
                _AddressCard(address: a),
                const SizedBox(height: 8),
              ],
              YButton(
                label: t('pf.addNew'),
                icon: Icons.add_rounded,
                variant: YButtonVariant.mint,
                onPressed: () async {
                  if (state.addresses.length >= maxAddresses) {
                    showToast(context, t('address.max', {'n': maxAddresses}),
                        kind: ToastKind.error);
                    return;
                  }
                  await showAddressForm(context, ref);
                },
              ),
              const SizedBox(height: sectionGap),
              YCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    YRow(
                      icon: Icons.language_rounded,
                      title: t('profile.language'),
                      value: t('profile.languageValue'),
                    ),
                    Divider(height: 1, color: tok.border),
                    YRow(
                      icon: Icons.headset_mic_rounded,
                      title: t('profile.help'),
                      onTap: () => showSupportSheet(context),
                    ),
                    Divider(height: 1, color: tok.border),
                    YRow(
                      icon: Icons.description_rounded,
                      title: t('profile.terms'),
                      onTap: () => context.push('/legal/terms'),
                    ),
                    Divider(height: 1, color: tok.border),
                    YRow(
                      icon: Icons.shield_rounded,
                      title: t('profile.privacy'),
                      onTap: () => context.push('/legal/privacy'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: sectionGap),
              YCard(
                color: tok.mint,
                shadow: false,
                onTap: () => context.go('/shop-mode/panel'),
                child: Row(
                  children: [
                    Container(
                      height: 46,
                      width: 46,
                      decoration: BoxDecoration(
                        color: tok.accent,
                        borderRadius:
                            BorderRadius.circular(YRadius.smallButton),
                      ),
                      child: Icon(Icons.storefront_rounded,
                          size: 24, color: tok.accentText),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('pf.ownerTitle'),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: tok.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t('pf.ownerText'),
                            style: TextStyle(fontSize: 13, color: tok.hint),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 22, color: tok.accentInk),
                  ],
                ),
              ),
              const SizedBox(height: sectionGap),
              YCard(
                padding: EdgeInsets.zero,
                child: YRow(
                  icon: Icons.delete_outline_rounded,
                  title: t('profile.delete'),
                  danger: true,
                  onTap: () => _deleteAccount(context, ref),
                ),
              ),
              const SizedBox(height: 18),
              Center(
                child: Text(
                  t('pf.version'),
                  style: TextStyle(fontSize: 12.5, color: tok.hint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context, WidgetRef ref) async {
    await showYSheet<void>(
      context: context,
      builder: (context) => const _EditProfileSheet(),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmSheet(
      context,
      title: t('profile.deleteTitle'),
      text: t('profile.deleteText'),
      yesLabel: t('profile.deleteYes'),
      danger: true,
    );
    if (!ok || !context.mounted) return;
    await ref.read(serverProvider).deleteAccount();
    ref.read(appStateProvider).reset();
    invalidateAll(ref);
    if (context.mounted) context.go('/onboarding');
  }
}

class _AddressCard extends ConsumerWidget {
  const _AddressCard({required this.address});

  final Address address;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tok = yt(context);
    final app = ref.watch(appStateProvider);
    return YCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      child: Row(
        children: [
          Icon(addressLabelIcon(address.label), size: 21, color: tok.hint),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        address.oneLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: tok.text,
                        ),
                      ),
                    ),
                    if (address.isDefault) ...[
                      const SizedBox(width: 8),
                      StatusTag(
                        label: t('profile.default'),
                        tone: TagTone.success,
                        small: true,
                      ),
                    ],
                  ],
                ),
                if (address.landmark.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    t('sv.landmark', {'v': address.landmark}),
                    style: TextStyle(fontSize: 12.5, color: tok.hint),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: tok.hint),
            onSelected: (value) async {
              switch (value) {
                case 'edit':
                  await showAddressForm(context, ref, existing: address);
                case 'default':
                  app.makeDefault(address.id);
                case 'delete':
                  final ok = await showConfirmSheet(
                    context,
                    title: t('profile.deleteAddressTitle'),
                    text: address.oneLine,
                    yesLabel: t('common.delete'),
                    danger: true,
                  );
                  if (ok) app.removeAddress(address.id);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit', child: Text(t('common.edit'))),
              if (!address.isDefault)
                PopupMenuItem(
                    value: 'default', child: Text(t('profile.makeDefault'))),
              PopupMenuItem(value: 'delete', child: Text(t('common.delete'))),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = ref.read(appStateProvider).state.user;
    _name = TextEditingController(text: user.firstName);
    _phone = TextEditingController(
        text: maskNational(nationalDigits(user.phone)));
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    if (name.length < 2 || name.length > 30) {
      setState(() => _error = t('onb.name.invalid'));
      return;
    }
    final digits = nationalDigits(_phone.text);
    if (!isValidPhone(digits)) {
      setState(() => _error = t('onb.phone.invalid'));
      return;
    }
    ref.read(appStateProvider).setUser(
          firstName: name,
          phone: toE164(digits),
        );
    Navigator.of(context).pop();
    showToast(context, t('profile.phoneChanged'), kind: ToastKind.success);
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
          SheetHeader(title: t('pf.edit')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t('onb.name.label'),
                    style: TextStyle(fontSize: 13.5, color: tok.hint)),
                const SizedBox(height: 6),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 14),
                Text(t('onb.phone.label'),
                    style: TextStyle(fontSize: 13.5, color: tok.hint)),
                const SizedBox(height: 6),
                TextField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [PhoneMaskFormatter()],
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 6, 14),
                      child: Text('+998',
                          style: TextStyle(fontSize: 16, color: tok.hint)),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0),
                    errorText: _error,
                  ),
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
