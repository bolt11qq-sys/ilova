/// Loading, empty and error states. Every screen has all three.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';
import 'buttons.dart';

/// A grey placeholder block shown while data loads.
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.height = 16,
    this.width,
    this.radius = 8,
  });

  final double height;
  final double? width;
  final double radius;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          color: Color.lerp(tok.card, tok.photoBg, _c.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}

/// A column of skeleton lines standing in for a list.
class SkeletonList extends StatelessWidget {
  const SkeletonList({super.key, this.count = 4, this.height = 72});

  final int count;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: screenPadding),
      child: Column(
        children: [
          for (var i = 0; i < count; i++) ...[
            Skeleton(height: height, radius: YRadius.card),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.text,
    this.image,
    this.icon,
    this.ctaLabel,
    this.onCta,
    this.extra,
  });

  final String title;
  final String? text;

  /// Asset path of the illustration.
  final String? image;
  final IconData? icon;
  final String? ctaLabel;
  final VoidCallback? onCta;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              Image.asset(
                image!,
                height: 168,
                errorBuilder: (_, __, ___) =>
                    Icon(icon ?? Icons.inbox_rounded, size: 72, color: tok.hint),
              )
            else if (icon != null)
              Container(
                height: 84,
                width: 84,
                decoration:
                    BoxDecoration(color: tok.accentSoft, shape: BoxShape.circle),
                child: Icon(icon, size: 38, color: tok.accentInk),
              ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: tok.text,
                letterSpacing: -0.3,
              ),
            ),
            if (text != null) ...[
              const SizedBox(height: 8),
              Text(
                text!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.5, color: tok.hint, height: 1.4),
              ),
            ],
            if (extra != null) ...[const SizedBox(height: 14), extra!],
            if (ctaLabel != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 240,
                child: YButton(label: ctaLabel!, onPressed: onCta),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({super.key, this.message, this.onRetry});

  final String? message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      title: t('common.errorTitle'),
      text: message ?? t('common.errorText'),
      icon: Icons.cloud_off_rounded,
      ctaLabel: t('common.retry'),
      onCta: onRetry,
    );
  }
}

/// Renders an [AsyncValue] with the project's own three states.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.onRetry,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => loading ?? const SkeletonList(),
      error: (e, _) => ErrorStateView(
        message: e is Exception ? '$e' : null,
        onRetry: onRetry,
      ),
    );
  }
}
