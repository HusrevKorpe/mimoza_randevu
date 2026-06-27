import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Small, letter-spaced top label, e.g. "RANDEVU DEFTERİ".
///
/// Pass the text already in the desired case — we do not call `toUpperCase`
/// here because Dart's default-locale casing mangles Turkish letters (i → I
/// instead of İ).
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final style = context.text.topLabel;
    return Text(
      text,
      style: color == null ? style : style.copyWith(color: color),
    );
  }
}
