/// "Yordam". In the mini app this opened a Telegram chat; the APK shows the
/// support handle with a copy action and sends nothing anywhere.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';
import '../widgets/buttons.dart';
import '../widgets/layout.dart';
import '../widgets/sheet.dart';
import '../widgets/toast.dart';

Future<void> showSupportSheet(BuildContext context) {
  return showYSheet<void>(
    context: context,
    builder: (context) {
      final tok = yt(context);
      return SheetBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(title: t('support.title'), subtitle: t('support.text')),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  screenPadding, 4, screenPadding, screenPadding),
              child: Column(
                children: [
                  YCard(
                    color: tok.card,
                    shadow: false,
                    child: Row(
                      children: [
                        Icon(Icons.support_agent_rounded,
                            size: 22, color: tok.accentInk),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            t('support.handle'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: tok.text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  YButton(
                    label: t('support.copy'),
                    icon: Icons.copy_rounded,
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: t('support.handle')));
                      Navigator.of(context).pop();
                      showToast(context, t('support.copied'),
                          kind: ToastKind.success);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
