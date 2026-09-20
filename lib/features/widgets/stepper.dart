/// The `− n +` quantity stepper.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';

class QtyStepper extends StatelessWidget {
  const QtyStepper({
    super.key,
    required this.quantity,
    required this.onChanged,
    this.max = 99,
    this.min = 0,
    this.compact = false,
  });

  final int quantity;
  final ValueChanged<int> onChanged;
  final int max;
  final int min;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final side = compact ? 30.0 : 34.0;

    Widget button(IconData icon, VoidCallback? onTap, String tooltip) =>
        Semantics(
          label: tooltip,
          button: true,
          child: Material(
            color: onTap == null ? tok.card : tok.accentSoft,
            borderRadius: BorderRadius.circular(YRadius.smallButton),
            child: InkWell(
              borderRadius: BorderRadius.circular(YRadius.smallButton),
              onTap: onTap == null
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      onTap();
                    },
              child: SizedBox(
                height: side,
                width: side,
                child: Icon(
                  icon,
                  size: compact ? 17 : 19,
                  color: onTap == null ? tok.hint : tok.accentInk,
                ),
              ),
            ),
          ),
        );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        button(
          Icons.remove_rounded,
          quantity > min ? () => onChanged(quantity - 1) : null,
          t('common.less'),
        ),
        SizedBox(
          width: compact ? 30 : 38,
          child: Text(
            '$quantity',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: compact ? 14.5 : 16,
              fontWeight: FontWeight.w700,
              color: tok.text,
            ),
          ),
        ),
        button(
          Icons.add_rounded,
          quantity < max ? () => onChanged(quantity + 1) : null,
          t('common.more'),
        ),
      ],
    );
  }
}

/// The small round "+" shown on product cards that are not in the cart yet.
class AddButton extends StatelessWidget {
  const AddButton({super.key, required this.onTap, this.enabled = true});

  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Material(
      color: enabled ? tok.accent : tok.card,
      borderRadius: BorderRadius.circular(YRadius.smallButton),
      child: InkWell(
        borderRadius: BorderRadius.circular(YRadius.smallButton),
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                onTap();
              }
            : null,
        child: SizedBox(
          height: 32,
          width: 32,
          child: Icon(
            Icons.add_rounded,
            size: 19,
            color: enabled ? tok.accentText : tok.hint,
          ),
        ),
      ),
    );
  }
}
