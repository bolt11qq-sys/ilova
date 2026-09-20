/// Buttons: one accent-filled primary and its outline, grey, mint and danger
/// variants, plus the full-width bar pinned above the safe area that stands in
/// for the Telegram MainButton.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';

enum YButtonVariant { primary, outline, grey, mint, danger }

class YButton extends StatelessWidget {
  const YButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = YButtonVariant.primary,
    this.icon,
    this.small = false,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final YButtonVariant variant;
  final IconData? icon;
  final bool small;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final disabled = onPressed == null || loading;

    late final Color bg;
    late final Color fg;
    Border? border;
    switch (variant) {
      case YButtonVariant.primary:
        bg = tok.accent;
        fg = tok.accentText;
      case YButtonVariant.outline:
        bg = Colors.transparent;
        fg = tok.accent;
        border = Border.all(color: tok.accent, width: 1.5);
      case YButtonVariant.grey:
        bg = tok.card;
        fg = tok.text;
      case YButtonVariant.mint:
        bg = tok.accentSoft;
        fg = tok.accentInk;
      case YButtonVariant.danger:
        bg = tok.danger;
        fg = Colors.white;
    }

    final content = loading
        ? SizedBox(
            height: small ? 16 : 20,
            width: small ? 16 : 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: fg),
          )
        : Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: small ? 17 : 19, color: fg),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: fg,
                    fontSize: small ? 14 : 15.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );

    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(
            small ? YRadius.smallButton : YRadius.button),
        child: InkWell(
          borderRadius: BorderRadius.circular(
              small ? YRadius.smallButton : YRadius.button),
          onTap: disabled
              ? null
              : () {
                  HapticFeedback.lightImpact();
                  onPressed!();
                },
          child: Container(
            height: small ? 38 : 50,
            width: expand ? double.infinity : null,
            padding: EdgeInsets.symmetric(horizontal: small ? 14 : 18),
            decoration: BoxDecoration(
              border: border,
              borderRadius: BorderRadius.circular(
                  small ? YRadius.smallButton : YRadius.button),
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}

/// A full-width button pinned above the safe area — the Android stand-in for
/// the Telegram MainButton.
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.child, this.note});

  final Widget child;
  final Widget? note;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        screenPadding,
        12,
        screenPadding,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: tok.surface,
        border: Border(top: BorderSide(color: tok.border)),
        boxShadow: tok.shadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note != null) ...[note!, const SizedBox(height: 10)],
          child,
        ],
      ),
    );
  }
}

/// A borderless text button in the accent colour ("Barchasini koʻrish →").
class YLink extends StatelessWidget {
  const YLink({super.key, required this.label, this.onTap, this.icon});

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return InkWell(
      borderRadius: BorderRadius.circular(YRadius.smallButton),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: tok.accent,
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon, size: 17, color: tok.accent),
            ],
          ],
        ),
      ),
    );
  }
}

/// A circular icon button on a soft background (back arrows, close buttons).
class YIconButton extends StatelessWidget {
  const YIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.background,
    this.color,
    this.size = 40,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final Color? background;
  final Color? color;
  final double size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final button = Material(
      color: background ?? tok.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          height: size,
          width: size,
          child: Icon(icon, size: size * 0.5, color: color ?? tok.text),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
