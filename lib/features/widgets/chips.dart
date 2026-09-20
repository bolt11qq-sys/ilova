/// Pill-shaped filter chips: the "Hammasi + seven categories" row and the
/// smaller sort chips.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';
import '../../data/seed.dart';

class YChip extends StatelessWidget {
  const YChip({
    super.key,
    required this.label,
    required this.selected,
    this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Material(
      color: selected ? tok.accent : tok.surface,
      borderRadius: BorderRadius.circular(YRadius.pill),
      child: InkWell(
        borderRadius: BorderRadius.circular(YRadius.pill),
        onTap: onTap == null
            ? null
            : () {
                HapticFeedback.selectionClick();
                onTap!();
              },
        child: Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(YRadius.pill),
            border: Border.all(color: selected ? tok.accent : tok.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon,
                    size: 16, color: selected ? tok.accentText : tok.hint),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? tok.accentText : tok.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Hammasi" plus the categories, horizontally scrollable.
/// [allowed] limits the row to the categories a shop actually sells.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selected,
    required this.onSelect,
    this.allowed,
    this.padding = const EdgeInsets.symmetric(horizontal: screenPadding),
  });

  /// `null` means "Hammasi".
  final String? selected;
  final ValueChanged<String?> onSelect;
  final List<String>? allowed;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final list = allowed == null
        ? categories
        : categories.where((c) => allowed!.contains(c.id)).toList();
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: list.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          if (i == 0) {
            return YChip(
              label: t('common.all'),
              selected: selected == null,
              onTap: () => onSelect(null),
            );
          }
          final c = list[i - 1];
          return YChip(
            label: c.name,
            selected: selected == c.id,
            onTap: () => onSelect(c.id),
          );
        },
      ),
    );
  }
}
