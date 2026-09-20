/// Page furniture: the mint page gradient, white cards, section headers and
/// the small labelled rows that most screens are built from.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// The soft mint gradient that fades out over the first ~460 px of a page.
class PageBackground extends StatelessWidget {
  const PageBackground({super.key, required this.child, this.height = 460});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Container(
      color: tok.isDark ? tok.bg : tok.gradientBottom,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [tok.gradientTop, tok.gradientBottom],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

/// A white rounded card with the standard soft shadow.
class YCard extends StatelessWidget {
  const YCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.radius = YRadius.card,
    this.color,
    this.borderColor,
    this.onTap,
    this.shadow = true,
  });

  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? tok.surface,
        borderRadius: BorderRadius.circular(radius),
        border: borderColor == null ? null : Border.all(color: borderColor!, width: 1.4),
        boxShadow: shadow ? tok.shadow : null,
      ),
      child: child,
    );
    final wrapped = onTap == null
        ? body
        : Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: onTap,
              child: body,
            ),
          );
    return margin == null ? wrapped : Padding(padding: margin!, child: wrapped);
  }
}

/// `Doʻkonlar                       Barchasini koʻrish →`
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
    this.padding =
        const EdgeInsets.fromLTRB(screenPadding, 0, screenPadding - 6, 0),
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: tok.text,
              ),
            ),
          ),
          if (action != null)
            InkWell(
              borderRadius: BorderRadius.circular(YRadius.smallButton),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                child: Row(
                  children: [
                    Text(
                      action!,
                      style: TextStyle(
                        color: tok.accent,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 17, color: tok.accent),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A settings-style row: icon, title, optional value, chevron.
class YRow extends StatelessWidget {
  const YRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.value,
    this.onTap,
    this.trailing,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final color = danger ? tok.danger : tok.text;
    return InkWell(
      borderRadius: BorderRadius.circular(YRadius.card),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 21, color: danger ? tok.danger : tok.hint),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(fontSize: 13, color: tok.hint),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  value!,
                  style: TextStyle(fontSize: 14.5, color: tok.hint),
                ),
              ),
            if (trailing != null) trailing!,
            if (trailing == null && onTap != null)
              Icon(Icons.chevron_right_rounded, size: 22, color: tok.hint),
          ],
        ),
      ),
    );
  }
}

/// A label/value line used in totals blocks.
class TotalRow extends StatelessWidget {
  const TotalRow({
    super.key,
    required this.label,
    required this.value,
    this.strong = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool strong;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: strong ? 16 : 14.5,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
              color: strong ? tok.text : tok.hint,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 17 : 14.5,
              fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
              color: valueColor ?? tok.text,
            ),
          ),
        ],
      ),
    );
  }
}
