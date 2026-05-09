import 'package:flutter/cupertino.dart';

abstract final class LuxuryColors {
  static const backgroundTop = Color(0xFFF7F9FC);
  static const backgroundBottom = Color(0xFFF7F9FC);
  static const gold = Color(0xFF007AFF);
  static const glass = Color(0xFFFFFFFF);
  static const glassStrong = Color(0xFFFFFFFF);
  static const border = Color(0xFFDCE3EE);
  static const textPrimary = Color(0xFF172033);
  static const textSoft = Color(0xFF687386);
}

abstract final class LuxuryInsets {
  static const page = EdgeInsets.fromLTRB(12, 12, 12, 24);
  static const sectionGap = SizedBox(height: 10);
  static const tileGap = SizedBox(height: 8);
}

class LuxuryBackground extends StatelessWidget {
  const LuxuryBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: LuxuryColors.backgroundTop),
      child: child,
    );
  }
}

class LuxuryGlassCard extends StatelessWidget {
  const LuxuryGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.radius = 8,
    this.tint,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: tint ?? LuxuryColors.glassStrong,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: LuxuryColors.border),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
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
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: LuxuryColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: LuxuryColors.textSoft,
                fontSize: 13,
                letterSpacing: 0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
