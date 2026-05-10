import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:guidex/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _data = [
    OnboardingData(
      title: 'Choose Your Future Path',
      description:
          'Find the right college, course, and career path with expert guidance.',
      imageAsset: 'assets/image/onboarding12.png',
      color: const Color(0xFF6C63FF),
    ),
    OnboardingData(
      title: 'Level Up Your Skills',
      description:
          'Discover internships, courses, and career opportunities with expert guidance.',
      imageAsset: 'assets/image/onboarding2.png',
      color: const Color.fromARGB(255, 22, 198, 157),
    ),
    OnboardingData(
      title: 'Crack Your Dream Exam',
      description:
          'Personalized tests, analysis, and expert strategies to crack exams.',
      imageAsset: 'assets/image/onboarding3.png',
      color: const Color.fromARGB(255, 94, 194, 237),
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background Blobs
          Positioned(
            top: -100,
            right: -50,
            child: AnimatedBlob(
              color: _data[_currentPage].color.withValues(alpha: 0.2),
              size: 400,
            ),
          ),
          Positioned(
            bottom: -150,
            left: -100,
            child: AnimatedBlob(
              color: _data[_currentPage].color.withValues(alpha: 0.15),
              size: 500,
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    itemCount: _data.length,
                    itemBuilder: (context, index) {
                      return OnboardingContent(data: _data[index]);
                    },
                  ),
                ),

                // Bottom Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 40,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Page Indicators
                      Row(
                        children: List.generate(
                          _data.length,
                          (index) => buildDot(index),
                        ),
                      ),

                      // Next Button
                      GestureDetector(
                        onTap: () {
                          if (_currentPage == _data.length - 1) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              AppRoutes.login,
                              (route) => false,
                            );
                          } else {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 500),
                              curve: Curves.easeInOut,
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 60,
                          width: _currentPage == _data.length - 1 ? 140 : 60,
                          decoration: BoxDecoration(
                            color: _data[_currentPage].color,
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: _data[_currentPage].color.withValues(
                                      alpha: 0.4,
                                    ),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _currentPage == _data.length - 1
                                ? const Text(
                                    'Get Started',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  )
                                : const Icon(
                                    Icons.arrow_forward_ios,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: _currentPage == index
            ? _data[_currentPage].color
            : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingContent extends StatelessWidget {
  final OnboardingData data;

  const OnboardingContent({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Transform.translate(
            offset: const Offset(0, 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    data.color.withValues(alpha: 0.22),
                    data.color.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: data.color.withValues(alpha: 0.2),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: data.imageAsset != null
                  ? Padding(
                      padding: EdgeInsets.only(
                        top: data.imageAsset == 'assets/image/onboarding2.png'
                            ? 27
                            : 10,
                      ),
                      child: Image.asset(
                        data.imageAsset!,
                        width: data.imageAsset == 'assets/image/onboarding2.png'
                            ? 330
                            : 300,
                        height:
                            data.imageAsset == 'assets/image/onboarding2.png'
                                ? 330
                                : 300,
                        fit: BoxFit.contain,
                      ),
                    )
                  : Icon(data.icon, size: 100, color: data.color),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData? icon;
  final String? imageAsset;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    this.icon,
    this.imageAsset,
    required this.color,
  }) : assert(
          icon != null || imageAsset != null,
          'Either icon or imageAsset must be provided.',
        );
}

class AnimatedBlob extends StatefulWidget {
  final Color color;
  final double size;

  const AnimatedBlob({super.key, required this.color, required this.size});

  @override
  State<AnimatedBlob> createState() => _AnimatedBlobState();
}

class _AnimatedBlobState extends State<AnimatedBlob>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: BlobPainter(
            animationValue: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class BlobPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  BlobPainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 3;

    final List<Offset> points = [];
    const int numPoints = 8;
    for (int i = 0; i < numPoints; i++) {
      final angle = (i * 2 * math.pi / numPoints);
      // Create organic movement using sine waves
      final variation = math.sin(animationValue * 2 * math.pi + i) * 20;
      final currentRadius = radius + variation;
      points.add(
        Offset(
          center.dx + currentRadius * math.cos(angle),
          center.dy + currentRadius * math.sin(angle),
        ),
      );
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < numPoints; i++) {
      final p2 = points[(i + 1) % numPoints];

      // Calculate a control point between p1 and p2 that is further out
      final midAngle = (i * 2 * math.pi / numPoints) + (math.pi / numPoints);

      final variation = math.sin(animationValue * 2 * math.pi + i + 0.5) * 30;
      final cpRadius =
          radius + variation + 40; // Push control point further out

      final cp = Offset(
        center.dx + cpRadius * math.cos(midAngle),
        center.dy + cpRadius * math.sin(midAngle),
      );

      path.quadraticBezierTo(cp.dx, cp.dy, p2.dx, p2.dy);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant BlobPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.color != color;
  }
}
