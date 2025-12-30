import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/platform/responsive.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _slides = const [
    _Slide(
      title: 'Own your scope',
      body: 'Track in-scope vs out-of-scope requests across all clients.',
      icon: Icons.shield_rounded,
    ),
    _Slide(
      title: 'Instant reports',
      body: 'Generate PDF scope reports and share in one tap.',
      icon: Icons.picture_as_pdf_rounded,
    ),
    _Slide(
      title: 'Analytics you need',
      body: 'See where scope creep is costing time and money.',
      icon: Icons.auto_graph_rounded,
    ),
    _Slide(
      title: 'Stay notified',
      body: 'Real-time alerts when clients ask for extras.',
      icon: Icons.notifications_active_rounded,
    ),
    _Slide(
      title: 'Get paid',
      body: 'Bill out-of-scope work with Stripe-ready workflows.',
      icon: Icons.credit_card_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_index >= _slides.length - 1) {
      context.go('/');
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 260), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Responsive.centeredContent(
          context,
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/'),
                  child: const Text('Skip'),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (_, i) {
                    final s = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(s.icon, size: 60, color: AppColors.primary),
                        ).animate().fadeIn(duration: 260.ms).scale(
                              begin: const Offset(0.9, 0.9),
                              end: const Offset(1, 1),
                            ),
                        const SizedBox(height: 20),
                        Text(
                          s.title,
                          style: AppText.h2(context),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          s.body,
                          style: AppText.bodyMuted(context),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => Container(
                    width: 10,
                    height: 10,
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? AppColors.primary
                          : AppColors.subtext.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _next,
                  icon: Icon(
                    _index == _slides.length - 1
                        ? Icons.login_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  label: Text(
                    _index == _slides.length - 1 ? 'Get started' : 'Next',
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

class _Slide {
  final String title;
  final String body;
  final IconData icon;
  const _Slide({required this.title, required this.body, required this.icon});
}
