import 'dart:ui';

import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  const GlassContainer({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.borderRadius = 20,
    this.blurSigma = 20,
    this.backgroundAlpha = 0.75,
    this.borderAlpha = 0.18,
    this.shadow = const [
      BoxShadow(
        color: Color(0x0A000000),
        blurRadius: 20,
        offset: Offset(0, 4),
      ),
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
            color: Colors.white.withOpacity(backgroundAlpha),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.65),
              width: 0.5,
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
  const GlassBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFFF2F2F7),
      child: Stack(
        children: [
          // top-left blue blob
          Positioned(
            top: -size.height * 0.06,
            left: -size.width * 0.12,
            child: _Blob(
              size: size.width * 0.55,
              color: const Color(0xFF007AFF),
              opacity: 0.10,
            ),
          ),
          // top-right purple blob
          Positioned(
            top: size.height * 0.12,
            right: -size.width * 0.15,
            child: _Blob(
              size: size.width * 0.45,
              color: const Color(0xFF5856D6),
              opacity: 0.08,
            ),
          ),
          // center-left teal blob
          Positioned(
            top: size.height * 0.38,
            left: -size.width * 0.10,
            child: _Blob(
              size: size.width * 0.40,
              color: const Color(0xFF32ADE6),
              opacity: 0.07,
            ),
          ),
          // bottom-right green blob
          Positioned(
            bottom: -size.height * 0.05,
            right: -size.width * 0.10,
            child: _Blob(
              size: size.width * 0.50,
              color: const Color(0xFF34C759),
              opacity: 0.09,
            ),
          ),
          // bottom-left pink blob
          Positioned(
            bottom: size.height * 0.08,
            left: -size.width * 0.08,
            child: _Blob(
              size: size.width * 0.38,
              color: const Color(0xFFFF2D55),
              opacity: 0.06,
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({
    required this.size,
    required this.color,
    required this.opacity,
  });

  final double size;
  final Color color;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(opacity),
            color.withOpacity(0),
          ],
        ),
      ),
    );
  }
}
