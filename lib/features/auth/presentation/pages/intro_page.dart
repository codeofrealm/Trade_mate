import 'package:flutter/material.dart';

import '../../../../app/app_routes.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  static const _slides = [
    _IntroSlide(
      icon: Icons.storefront_outlined,
      title: 'Welcome to TradeMate',
      body:
          'Manage your shop, products, and orders from one simple mobile workspace.',
      tags: ['Products', 'Orders', 'Dashboard'],
    ),
    _IntroSlide(
      icon: Icons.inventory_2_outlined,
      title: 'Keep products organized',
      body:
          'Add details, update stock, and keep your catalog ready for customers.',
      tags: ['Stock', 'Pricing', 'Details'],
    ),
    _IntroSlide(
      icon: Icons.receipt_long_outlined,
      title: 'Follow every order',
      body:
          'Review new orders, confirm requests, and track progress without clutter.',
      tags: ['Requests', 'Confirm', 'History'],
    ),
    _IntroSlide(
      icon: Icons.insights_outlined,
      title: 'Grow with clarity',
      body: 'Use analytics and alerts to understand what needs attention next.',
      tags: ['Analytics', 'Alerts', 'Growth'],
    ),
  ];

  bool get _isLastPage => _currentPage == _slides.length - 1;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  void _goNext() {
    if (_isLastPage) {
      _openLogin();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
          child: Column(
            children: [
              _IntroTopBar(onSkip: _openLogin),
              const SizedBox(height: 10),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double page = index.toDouble();
                        if (_pageController.hasClients &&
                            _pageController.page != null) {
                          page = _pageController.page!;
                        }

                        final distance = (page - index).abs().clamp(0.0, 1.0);
                        final scale = 0.94 + ((1 - distance) * 0.06);
                        final opacity = 0.55 + ((1 - distance) * 0.45);

                        return Opacity(
                          opacity: opacity,
                          child: Transform.scale(scale: scale, child: child),
                        );
                      },
                      child: _IntroSlideView(slide: slide),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              _IntroIndicator(
                count: _slides.length,
                selectedIndex: _currentPage,
              ),
              const SizedBox(height: 22),
              _IntroActions(
                isLastPage: _isLastPage,
                onSkip: _openLogin,
                onNext: _goNext,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroSlide {
  const _IntroSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.tags,
  });

  final IconData icon;
  final String title;
  final String body;
  final List<String> tags;
}

class _IntroTopBar extends StatelessWidget {
  const _IntroTopBar({required this.onSkip});

  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE8F2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.storefront_outlined,
            color: Color(0xFF007AFF),
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'TradeMate',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        TextButton(
          onPressed: onSkip,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF64748B),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: const Text('Skip'),
        ),
      ],
    );
  }
}

class _IntroSlideView extends StatelessWidget {
  const _IntroSlideView({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              key: ValueKey(slide.title),
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 520),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 22 * (1 - value)),
                  child: Opacity(opacity: value, child: child),
                );
              },
              child: _IntroIconPanel(icon: slide.icon),
            ),
            const SizedBox(height: 38),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.08),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Column(
                key: ValueKey(slide.title),
                children: [
                  Text(
                    slide.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    slide.body,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      height: 1.48,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in slide.tags) _FeatureChip(label: tag),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroIconPanel extends StatelessWidget {
  const _IntroIconPanel({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: const Color(0xFFD8E1EE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF007AFF).withValues(alpha: 0.08),
            blurRadius: 28,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 118,
            height: 118,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F2FF),
              borderRadius: BorderRadius.circular(30),
            ),
          ),
          Icon(icon, color: const Color(0xFF007AFF), size: 72),
          const Positioned(right: 22, top: 22, child: _StatusDot()),
          const Positioned(left: 24, bottom: 24, child: _MiniLine(width: 48)),
          const Positioned(right: 24, bottom: 42, child: _MiniLine(width: 34)),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: const Color(0xFF34C759),
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _MiniLine extends StatelessWidget {
  const _MiniLine({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 6,
      decoration: BoxDecoration(
        color: const Color(0xFFD8E1EE),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD8E1EE)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF172033),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _IntroIndicator extends StatelessWidget {
  const _IntroIndicator({required this.count, required this.selectedIndex});

  final int count;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (index) {
        final selected = index == selectedIndex;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          width: selected ? 26 : 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF007AFF) : const Color(0xFFD8E1EE),
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class _IntroActions extends StatelessWidget {
  const _IntroActions({
    required this.isLastPage,
    required this.onSkip,
    required this.onNext,
  });

  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 96,
          height: 52,
          child: OutlinedButton(
            onPressed: onSkip,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF172033),
              side: const BorderSide(color: Color(0xFFD8E1EE)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text('Skip'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: onNext,
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Icon(
                  isLastPage
                      ? Icons.login_outlined
                      : Icons.arrow_forward_rounded,
                  key: ValueKey(isLastPage),
                  size: 21,
                ),
              ),
              label: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Text(
                  isLastPage ? 'Get started' : 'Next',
                  key: ValueKey(isLastPage),
                ),
              ),
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
