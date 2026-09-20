/// Toasts. The Telegram bot's notifications become in-app snackbars.
///
/// The messenger is reached through a global key so a toast still appears when
/// the widget that asked for it has already been popped (adding to the cart
/// from a bottom sheet, for example).
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

final GlobalKey<ScaffoldMessengerState> appMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum ToastKind { success, error, info }

void showToast(BuildContext context, String message,
    {ToastKind kind = ToastKind.info}) {
  final messenger =
      appMessengerKey.currentState ?? ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  final themed = appMessengerKey.currentContext ?? context;
  final tok = yt(themed);
  final (IconData icon, Color color) = switch (kind) {
    ToastKind.success => (Icons.check_circle_rounded, tok.accent),
    ToastKind.error => (Icons.error_rounded, tok.danger),
    ToastKind.info => (Icons.info_rounded, Colors.white),
  };
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.fromLTRB(
            screenPadding, 0, screenPadding, screenPadding),
        content: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
}
