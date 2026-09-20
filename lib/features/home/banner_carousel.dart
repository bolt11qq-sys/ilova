/// The three Home banners. They advance by themselves every 5 seconds and
/// pause for 10 seconds after a touch.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';

class BannerSlide {
  const BannerSlide({
    required this.kind,
    required this.tag,
    required this.title,
    required this.text,
    required this.cta,
    required this.route,
    required this.art,
  });

  final BannerKind kind;
  final String tag;
  final String title;
  final String text;
  final String cta;
  final String route;

  /// One or two asset paths; two are drawn as a small duo.
  final List<String> art;
}

List<BannerSlide> homeBanners() => [
      BannerSlide(
        kind: BannerKind.promo,
        tag: t('hb.promo.tag'),
        title: t('hb.promo.title'),
        text: t('hb.promo.text'),
        cta: t('hb.promo.cta'),
        route: '/promotions',
        art: const ['assets/img/hero-basket.jpg'],
      ),
      BannerSlide(
        kind: BannerKind.fresh,
        tag: t('hb.fresh.tag'),
        title: t('hb.fresh.title'),
        text: t('hb.fresh.text'),
        cta: t('hb.fresh.cta'),
        route: '/shops',
        art: const ['assets/img/patir.png', 'assets/img/sut2.png'],
      ),
      BannerSlide(
        kind: BannerKind.fast,
        tag: t('hb.fast.tag'),
        title: t('hb.fast.title'),
        text: t('hb.fast.text'),
        cta: t('hb.fast.cta'),
        route: '/shops',
        art: const ['assets/img/bag.png'],
      ),
    ];

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key, required this.onTap});

  final ValueChanged<String> onTap;

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  final _controller = PageController();
  final _slides = homeBanners();
  Timer? _timer;
  int _index = 0;
  DateTime _pausedUntil = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _advance());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _advance() {
    if (!mounted || !_controller.hasClients) return;
    if (DateTime.now().isBefore(_pausedUntil)) return;
    final next = (_index + 1) % _slides.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _pause() {
    _pausedUntil = DateTime.now().add(const Duration(seconds: 10));
  }

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    return Column(
      children: [
        SizedBox(
          height: 182,
          child: Listener(
            onPointerDown: (_) => _pause(),
            child: PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: screenPadding),
                child: _Slide(
                  slide: _slides[i],
                  counter: '${i + 1}/${_slides.length}',
                  onTap: () => widget.onTap(_slides[i].route),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 7,
                width: i == _index ? 18 : 7,
                decoration: BoxDecoration(
                  color: i == _index ? tok.accent : tok.border,
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              if (i < _slides.length - 1) const SizedBox(width: 6),
            ],
          ],
        ),
      ],
    );
  }
}

class _Slide extends StatelessWidget {
  const _Slide({
    required this.slide,
    required this.counter,
    required this.onTap,
  });

  final BannerSlide slide;
  final String counter;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = BannerPalette.all[slide.kind]!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(YRadius.banner),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: palette.gradient,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: 0,
              bottom: 0,
              width: 168,
              child: _Art(paths: slide.art),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 150, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: palette.tag,
                      borderRadius: BorderRadius.circular(YRadius.pill),
                    ),
                    child: Text(
                      slide.tag,
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    slide.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.25,
                      color: palette.ink.withAlpha(190),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: palette.tag,
                      borderRadius: BorderRadius.circular(YRadius.button),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          slide.cta,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_rounded,
                            size: 15, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              bottom: 10,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(56),
                  borderRadius: BorderRadius.circular(YRadius.pill),
                ),
                child: Text(
                  counter,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Art extends StatelessWidget {
  const _Art({required this.paths});

  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    if (paths.length >= 2) {
      return Stack(
        children: [
          Positioned(
            right: 58,
            bottom: 8,
            child: Image.asset(paths[0], height: 96, errorBuilder: _fallback),
          ),
          Positioned(
            right: 6,
            bottom: 14,
            child: Image.asset(paths[1], height: 112, errorBuilder: _fallback),
          ),
        ],
      );
    }
    return Image.asset(paths.first, fit: BoxFit.cover, errorBuilder: _fallback);
  }

  static Widget _fallback(BuildContext context, Object error, StackTrace? s) =>
      const SizedBox.shrink();
}
