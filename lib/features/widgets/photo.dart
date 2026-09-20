/// Product and shop pictures. Anything without a bundled photo falls back to
/// an emoji tile, so no screen ever shows a broken image.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class ProductPhoto extends StatelessWidget {
  const ProductPhoto({
    super.key,
    required this.photo,
    required this.emoji,
    this.size,
    this.radius = YRadius.mini,
    this.fit = BoxFit.cover,
    this.emojiScale = 0.45,
  });

  final String? photo;
  final String emoji;
  final double? size;
  final double radius;
  final BoxFit fit;
  final double emojiScale;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        height: size,
        width: size,
        color: tok.photoBg,
        child: photo == null
            ? _EmojiTile(emoji: emoji, scale: emojiScale)
            : Image.asset(
                photo!,
                fit: fit,
                errorBuilder: (_, __, ___) =>
                    _EmojiTile(emoji: emoji, scale: emojiScale),
              ),
      ),
    );
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({required this.emoji, required this.scale});

  final String emoji;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final side = box.hasBoundedHeight && box.hasBoundedWidth
            ? (box.maxHeight < box.maxWidth ? box.maxHeight : box.maxWidth)
            : 48.0;
        return Center(
          child: Text(emoji, style: TextStyle(fontSize: side * scale)),
        );
      },
    );
  }
}

/// The coloured circle with a white line icon that stands for a shop.
class ShopAvatar extends StatelessWidget {
  const ShopAvatar({
    super.key,
    required this.color,
    required this.icon,
    this.photo,
    this.size = 48,
    this.dimmed = false,
  });

  final Color color;
  final IconData icon;
  final String? photo;
  final double size;

  /// Closed shops are shown at 55 % opacity.
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final circle = Container(
      height: size,
      width: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: photo == null
          ? Icon(icon, size: size * 0.48, color: Colors.white)
          : Image.asset(
              photo!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Icon(icon, size: size * 0.48, color: Colors.white),
            ),
    );
    return dimmed ? Opacity(opacity: 0.55, child: circle) : circle;
  }
}
