/// Bottom sheets: one scaffold, plus the generic "choice" and "confirm"
/// sheets the whole app reuses.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';
import 'buttons.dart';

/// Opens a scrollable bottom sheet with the project's shape and padding.
Future<T?> showYSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext context) builder,
  bool isScrollControlled = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: true,
    backgroundColor: yt(context).surface,
    builder: builder,
  );
}

/// The common head of a sheet: a title and an optional subtitle.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, this.subtitle, this.trailing});

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(screenPadding, 2, screenPadding, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: tok.text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 14, color: tok.hint, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// A sheet body that never grows past 85 % of the screen.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.child, this.bottom});

  final Widget child;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: SingleChildScrollView(child: child)),
          if (bottom != null)
            Padding(
              padding: EdgeInsets.fromLTRB(
                screenPadding,
                10,
                screenPadding,
                10 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: bottom!,
            ),
        ],
      ),
    );
  }
}

class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label, {this.subtitle, this.icon});

  final T value;
  final String label;
  final String? subtitle;
  final IconData? icon;
}

/// A generic list sheet ("Saralash", "Turkumlar", unit pickers …).
Future<T?> showChoiceSheet<T>(
  BuildContext context, {
  required String title,
  required List<ChoiceOption<T>> options,
  T? selected,
}) {
  return showYSheet<T>(
    context: context,
    builder: (context) {
      final tok = yt(context);
      return SheetBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SheetHeader(title: title),
            for (final o in options)
              ListTile(
                leading: o.icon == null
                    ? null
                    : Icon(o.icon, color: tok.hint, size: 22),
                title: Text(
                  o.label,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight:
                        o.value == selected ? FontWeight.w700 : FontWeight.w500,
                    color: o.value == selected ? tok.accentInk : tok.text,
                  ),
                ),
                subtitle: o.subtitle == null
                    ? null
                    : Text(o.subtitle!,
                        style: TextStyle(fontSize: 13, color: tok.hint)),
                trailing: o.value == selected
                    ? Icon(Icons.check_rounded, color: tok.accent)
                    : null,
                onTap: () => Navigator.of(context).pop(o.value),
              ),
            const SizedBox(height: 12),
          ],
        ),
      );
    },
  );
}

/// Yes/no confirmation. Resolves to `true` only when the user confirms.
Future<bool> showConfirmSheet(
  BuildContext context, {
  required String title,
  String? text,
  required String yesLabel,
  String? noLabel,
  bool danger = false,
}) async {
  final result = await showYSheet<bool>(
    context: context,
    builder: (context) => SheetBody(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SheetHeader(title: title, subtitle: text),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                screenPadding, 4, screenPadding, screenPadding),
            child: Column(
              children: [
                YButton(
                  label: yesLabel,
                  variant:
                      danger ? YButtonVariant.danger : YButtonVariant.primary,
                  onPressed: () => Navigator.of(context).pop(true),
                ),
                const SizedBox(height: 10),
                YButton(
                  label: noLabel ?? t('common.cancel'),
                  variant: YButtonVariant.grey,
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
  return result ?? false;
}
