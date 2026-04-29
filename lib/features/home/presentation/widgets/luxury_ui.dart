import 'dart:ui';

import 'package:flutter/cupertino.dart';

abstract final class LuxuryColors {
  static const backgroundTop = Color(0xFF121216);
  static const backgroundBottom = Color(0xFF060608);
  static const gold = Color(0xFFD4AF37);
  static const glass = Color(0x26FFFFFF);
  static const glassStrong = Color(0x32FFFFFF);
  static const border = Color(0x4DFFFFFF);
  static const textPrimary = CupertinoColors.white;
  static const textSoft = Color(0xFFB7B7BF);
}

abstract final class LuxuryInsets {
  static const page = EdgeInsets.fromLTRB(16, 14, 16, 34);
  static const sectionGap = SizedBox(height: 14);
  static const tileGap = SizedBox(height: 10);
}

class LuxuryBackground extends StatelessWidget {
  const LuxuryBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [LuxuryColors.backgroundTop, LuxuryColors.backgroundBottom],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            left: -30,
            child: _GlowOrb(
              size: 180,
              color: LuxuryColors.gold.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            top: 190,
            right: -60,
            child: _GlowOrb(
              size: 150,
              color: CupertinoColors.white.withValues(alpha: 0.07),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class LuxuryGlassCard extends StatelessWidget {
  const LuxuryGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 16,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? LuxuryColors.glassStrong,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: LuxuryColors.border, width: 0.9),
            boxShadow: [
              BoxShadow(
                color: CupertinoColors.black.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class LuxurySectionTitle extends StatelessWidget {
  const LuxurySectionTitle(this.title, {super.key, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: LuxuryColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: LuxuryColors.textSoft,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 70, spreadRadius: 12)],
      ),
    );
  }
}
