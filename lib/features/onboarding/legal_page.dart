/// Foydalanish shartlari / Maxfiylik siyosati. Placeholder texts: the draft
/// notice stays visible, exactly as in the mini app.
library;

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/strings_buyer.dart';
import '../widgets/layout.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key, required this.doc});

  /// `terms` or `privacy`.
  final String doc;

  @override
  Widget build(BuildContext context) {
    final tok = yt(context);
    final isTerms = doc != 'privacy';
    final title = isTerms ? t('profile.terms') : t('profile.privacy');
    final paragraphs = isTerms
        ? [t('legal.terms.1'), t('legal.terms.2'), t('legal.terms.3')]
        : [t('legal.privacy.1'), t('legal.privacy.2'), t('legal.privacy.3')];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PageBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(title: Text(title)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                      screenPadding, 4, screenPadding, 32),
                  children: [
                    YCard(
                      color: tok.peach,
                      shadow: false,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_rounded, size: 19, color: tok.warn),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              t('legal.draft'),
                              style: TextStyle(
                                fontSize: 13.5,
                                color: tok.text,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final p in paragraphs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Text(
                          p,
                          style: TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: tok.text,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
