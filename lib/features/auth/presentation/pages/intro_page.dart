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
          'A simple workspace for managing products, customer orders, and daily trade activity.',
    ),
    _IntroSlide(
      icon: Icons.inventory_2_outlined,
      title: 'Organize products',
      body:
          'Keep product details neat, update listings quickly, and make your catalog easy to browse.',
    ),
    _IntroSlide(
      icon: Icons.receipt_long_outlined,
      title: 'Track every order',
      body:
          'Follow order requests, confirmations, and history from one place without extra clutter.',
    ),
    _IntroSlide(
      icon: Icons.insights_outlined,
      title: 'Grow with clarity',
      body:
          'Use clean dashboards and notifications to understand what needs your attention next.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentPage == _slides.length - 1) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 26),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
                  },
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return _IntroSlideView(slide: slide);
                  },
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (index) {
                  final selected = index == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    width: selected ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF007AFF)
                          : const Color(0xFFD8E1EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 26),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _goNext,
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Get started' : 'Next',
                  ),
                ),
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
  });

  final IconData icon;
  final String title;
  final String body;
}

class _IntroSlideView extends StatelessWidget {
  const _IntroSlideView({required this.slide});

  final _IntroSlide slide;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 154,
              height: 154,
              decoration: BoxDecoration(
                color: const Color(0xFFE8F2FF),
                borderRadius: BorderRadius.circular(42),
              ),
              child: Icon(slide.icon, color: const Color(0xFF007AFF), size: 72),
            ),
            const SizedBox(height: 44),
            Text(
              slide.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 31,
                fontWeight: FontWeight.w900,
                height: 1.08,
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
          ],
        ),
      ),
    );
  }
}
