import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Brand splash shown while the persisted session is restored ([AuthGate]).
///
/// Barber-themed but deliberately calm: the logo settles in with a soft blue
/// halo, a scissor-marked label states the craft, and a slow barber-pole stripe
/// doubles as the loading cue. Every color comes from [AppPalette] tokens, so it
/// reads correctly in both light and dark themes — nothing is hardcoded.
class AppSplash extends StatefulWidget {
  const AppSplash({super.key});

  @override
  State<AppSplash> createState() => _AppSplashState();
}

class _AppSplashState extends State<AppSplash> with TickerProviderStateMixin {
  // One-shot staggered entrance (logo → title → pole).
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 820),
  );
  // Forever loop driving the halo pulse and the barber-pole scroll.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  );

  late final Animation<double> _logoFade = _fade(0.00, 0.45);
  late final Animation<double> _logoScale = CurvedAnimation(
    parent: _intro,
    curve: const Interval(0.0, 0.62, curve: Curves.easeOutBack),
  );
  late final Animation<double> _titleFade = _fade(0.34, 0.72);
  late final Animation<double> _poleFade = _fade(0.60, 1.00);

  Animation<double> _fade(double begin, double end) => CurvedAnimation(
        parent: _intro,
        curve: Interval(begin, end, curve: Curves.easeOut),
      );

  @override
  void initState() {
    super.initState();
    _intro.forward();
    _loop.repeat();
  }

  @override
  void dispose() {
    _intro.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: colors.brightness,
      ),
      child: Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _Logo(fade: _logoFade, scale: _logoScale, pulse: _loop),
              const SizedBox(height: AppSpacing.xl + AppSpacing.xs),
              FadeTransition(opacity: _titleFade, child: const _Title()),
              const SizedBox(height: AppSpacing.lg),
              FadeTransition(
                opacity: _poleFade,
                child: _BarberPole(scroll: _loop),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The logo mark sitting in a breathing blue halo.
class _Logo extends StatelessWidget {
  const _Logo({required this.fade, required this.scale, required this.pulse});

  final Animation<double> fade;
  final Animation<double> scale;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FadeTransition(
      opacity: fade,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.86, end: 1.0).animate(scale),
        child: AnimatedBuilder(
          animation: pulse,
          builder: (context, child) {
            // Smooth 0→1→0 pulse for a glow that swells and eases back.
            final t = (math.sin(pulse.value * 2 * math.pi) + 1) / 2;
            return DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.18 + 0.20 * t),
                    blurRadius: 34 + 14 * t,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Image.asset(
              'assets/logo.png',
              width: 112,
              height: 112,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
      ),
    );
  }
}

/// App name plus a scissor-flanked craft label.
class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.text;
    return Column(
      children: [
        Text('Randevu Defteri', style: text.screenTitle),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.content_cut_rounded, size: 13, color: colors.textMuted),
            const SizedBox(width: AppSpacing.xs),
            Text('BERBER DEFTERİ', style: text.topLabel),
          ],
        ),
      ],
    );
  }
}

/// A slim barber pole whose diagonal stripes scroll forever — the loading cue.
class _BarberPole extends StatelessWidget {
  const _BarberPole({required this.scroll});

  final Animation<double> scroll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return RepaintBoundary(
      child: SizedBox(
        width: 132,
        height: 9,
        child: AnimatedBuilder(
          animation: scroll,
          builder: (context, _) => CustomPaint(
            painter: _BarberPolePainter(
              phase: scroll.value,
              stripe: colors.primary,
              track: colors.softBlue,
              border: colors.border,
            ),
          ),
        ),
      ),
    );
  }
}

class _BarberPolePainter extends CustomPainter {
  _BarberPolePainter({
    required this.phase,
    required this.stripe,
    required this.track,
    required this.border,
  });

  final double phase; // 0..1, scrolls the stripes by one period.
  final Color stripe;
  final Color track;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height / 2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );

    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRRect(rrect, Paint()..color = track);

    // Diagonal bands marching to the right — the spinning-pole illusion.
    final slope = size.height; // ~45° lean
    final period = size.height * 1.7;
    final stripeW = period / 2;
    final start = -phase * period - period;
    final paint = Paint()..color = stripe;
    for (double x = start; x < size.width + slope + period; x += period) {
      canvas.drawPath(
        Path()
          ..moveTo(x, size.height)
          ..lineTo(x + stripeW, size.height)
          ..lineTo(x + stripeW + slope, 0)
          ..lineTo(x + slope, 0)
          ..close(),
        paint,
      );
    }
    canvas.restore();

    // Hairline keeps the capsule crisp where the track meets the background.
    canvas.drawRRect(
      rrect.deflate(0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = border,
    );
  }

  @override
  bool shouldRepaint(covariant _BarberPolePainter old) =>
      old.phase != phase ||
      old.stripe != stripe ||
      old.track != track ||
      old.border != border;
}
