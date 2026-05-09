import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 8,
    this.blurSigma = 0,
    this.backgroundAlpha = 1,
    this.borderAlpha = 1,
    this.shadow = const [
      BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blurSigma;
  final double backgroundAlpha;
  final double borderAlpha;
  final List<BoxShadow> shadow;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: backgroundAlpha),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: const Color(0xFFDCE3EE).withValues(alpha: borderAlpha),
              width: 1,
            ),
            boxShadow: shadow,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class GlassBackground extends StatelessWidget {
  const GlassBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF7F9FC),
      child: child,
    );
  }
}
