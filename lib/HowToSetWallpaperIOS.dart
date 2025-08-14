import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryColor = Color(0xFF0A0A0A);
  static const Color accentColor = Color(0xFF00F5FF);
  static const Color highlightColor = Color(0xFFFF006E);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color gradientStart = Color(0xFF0F3460);
  static const Color gradientEnd = Color(0xFF533483);
  static const Color neonGreen = Color(0xFF39FF14);
}

class HowToSetWallpaperIOSPage extends StatefulWidget {
  const HowToSetWallpaperIOSPage({super.key});

  @override
  State<HowToSetWallpaperIOSPage> createState() =>
      _HowToSetWallpaperIOSPageState();
}

class _HowToSetWallpaperIOSPageState extends State<HowToSetWallpaperIOSPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _animatedStep(int step, String text, int delay) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.2),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Interval(delay * 0.1, 1.0, curve: Curves.easeOut),
          ),
        ),
        child: _StepTile(step: step, text: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated Gradient Background
          AnimatedContainer(
            duration: const Duration(seconds: 5),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor,
                  AppColors.gradientStart,
                  AppColors.gradientEnd
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Set on iOS',
                        style: TextStyle(
                          color: AppColors.accentColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          letterSpacing: 1.2,
                          shadows: [
                            Shadow(
                              color: AppColors.accentColor.withOpacity(0.7),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Follow These 3 Easy Steps:',
                      style: TextStyle(
                        color: AppColors.textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Animated Steps
                    _animatedStep(
                        1,
                        'Save the wallpaper to Photos using the Download button.',
                        1),
                    const SizedBox(height: 24),
                    _animatedStep(
                        2, 'Open the Photos app and find the wallpaper.', 2),
                    const SizedBox(height: 24),
                    _animatedStep(
                        3,
                        'Tap Share icon, then select "Use as Wallpaper" to apply.',
                        3),
                    const SizedBox(height: 32),

                    // Glass Info Box with animation
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const _GlassInfoBox(
                        icon: Icons.info_outline,
                        iconColor: AppColors.neonGreen,
                        text:
                            'Due to iOS restrictions, apps cannot set the wallpaper for you. This must be done manually from the Photos app.',
                      ),
                    ),

                    const Spacer(),

                    // Animated Back Button
                    FadeTransition(
                      opacity: _fadeAnimation,
                      child: const _GradientBackButton(),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  final int step;
  final String text;
  const _StepTile({required this.step, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.gradientStart, AppColors.gradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          width: 36,
          height: 36,
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: AppColors.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassInfoBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _GlassInfoBox({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: AppColors.textColor.withOpacity(0.85),
                    fontSize: 15,
                    height: 1.5,
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

class _GradientBackButton extends StatelessWidget {
  const _GradientBackButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accentColor, AppColors.highlightColor],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.highlightColor.withOpacity(0.4),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'Go Back',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
