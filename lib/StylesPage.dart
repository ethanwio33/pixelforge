// lib/StylesPage.dart

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'dart:ui';

// Import necessary pages
import 'AIPage.dart';

// ===================================================================
// ---                       APP CONSTANTS                         ---
// ===================================================================
// NOTE: Colors are aligned with the established design language.
class AppColors {
  static const Color primaryColor = Color(0xFF0A0A0A); // Deep black
  static const Color accentColor = Color(0xFF00F5FF); // Bright cyan
  static const Color highlightColor = Color(0xFFFF006E); // Hot pink
  static const Color textColor = Color(0xFFFFFFFF); // White
}

// Data model remains unchanged
class WallpaperStyle {
  final String title;
  final String imagePath;

  WallpaperStyle({required this.title, required this.imagePath});
}

// ===================================================================
// ---       REVAMPED: ULTRA-MODERN STYLES PAGE (V2)             ---
// ===================================================================
class StylesPage extends StatefulWidget {
  const StylesPage({super.key});

  @override
  _StylesPageState createState() => _StylesPageState();
}

class _StylesPageState extends State<StylesPage> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // The list of styles remains unchanged.
  final List<WallpaperStyle> styles = [
    WallpaperStyle(
        title: 'Cyberpunk', imagePath: 'assets/images/Cyberpunk.png'),
    WallpaperStyle(
        title: 'Steampunk', imagePath: 'assets/images/Steampunk.png'),
    WallpaperStyle(title: 'Fantasy', imagePath: 'assets/images/Fantasy.png'),
    WallpaperStyle(title: 'Mecha', imagePath: 'assets/images/Mecha.png'),
    WallpaperStyle(title: 'Noir', imagePath: 'assets/images/Noir.png'),
    WallpaperStyle(
        title: 'Pixel Art', imagePath: 'assets/images/Pixel_Art.png'),
    WallpaperStyle(
        title: 'Watercolor', imagePath: 'assets/images/Watercolor.png'),
    WallpaperStyle(title: 'Sketch', imagePath: 'assets/images/Sketch.png'),
    WallpaperStyle(
        title: 'Realistic', imagePath: 'assets/images/Realistic.png'),
    WallpaperStyle(title: 'Modern', imagePath: 'assets/images/Modern.png'),
    WallpaperStyle(title: 'Classic', imagePath: 'assets/images/Classic.png'),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeIn);

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: CustomScrollView(
        slivers: [
          // REVAMPED: Glassmorphism App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            backgroundColor: AppColors.primaryColor.withOpacity(0.7),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Choose Your Style',
                style: TextStyle(
                    color: AppColors.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
              centerTitle: true,
              background: ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          ),
          // REVAMPED: "Create Your Own" Card
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: CustomPromptCard(),
            ),
          ),

          // ▼▼▼ ERROR FIXED HERE ▼▼▼
          // The FadeTransition was replaced with SliverFadeTransition, which is a sliver.
          // The SliverPadding is now placed *inside* the animation widget.
          SliverFadeTransition(
            opacity: _fadeAnimation,
            sliver: SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              sliver: SliverMasonryGrid(
                gridDelegate:
                    const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                ),
                mainAxisSpacing: 16.0,
                crossAxisSpacing: 16.0,
                delegate: SliverChildBuilderDelegate(
                  (context, index) => StyleCard(style: styles[index]),
                  childCount: styles.length,
                ),
              ),
            ),
          ),
          // ▲▲▲ END OF FIX ▲▲▲

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

// ===================================================================
// ---            REVAMPED WIDGET: StyleCard (V2)                  ---
// ===================================================================
class StyleCard extends StatefulWidget {
  final WallpaperStyle style;
  const StyleCard({super.key, required this.style});

  @override
  _StyleCardState createState() => _StyleCardState();
}

class _StyleCardState extends State<StyleCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToGenerator() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIPage(initialPrompt: widget.style.title),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) =>
          Transform.scale(scale: _scaleAnimation.value, child: child),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          _navigateToGenerator();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          height: 220,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(widget.style.imagePath, fit: BoxFit.cover),
                // Animated Gradient Overlay for text readability
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8)
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                    ),
                  ),
                ),
                // Title Text with Neon Glow
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Text(
                    widget.style.title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                            blurRadius: 15.0,
                            color: AppColors.accentColor.withOpacity(0.7),
                            offset: const Offset(0, 0)),
                        const Shadow(
                            blurRadius: 8.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// ---      REVAMPED WIDGET: CustomPromptCard (V2)                 ---
// ===================================================================
class CustomPromptCard extends StatefulWidget {
  const CustomPromptCard({super.key});

  @override
  State<CustomPromptCard> createState() => _CustomPromptCardState();
}

class _CustomPromptCardState extends State<CustomPromptCard> {
  final TextEditingController _controller = TextEditingController();

  void _generateFromCustomPrompt() {
    if (_controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter a style or idea!'),
          backgroundColor: AppColors.highlightColor,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIPage(initialPrompt: _controller.text.trim()),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.0),
            color: Colors.black.withOpacity(0.25),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Have Another Idea?',
                style: TextStyle(
                  color: AppColors.textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                style: const TextStyle(color: AppColors.textColor),
                decoration: InputDecoration(
                  hintText: 'e.g., "Cosmic Ocean", "8-bit Sunset"',
                  hintStyle:
                      TextStyle(color: AppColors.textColor.withOpacity(0.5)),
                  filled: true,
                  fillColor: AppColors.primaryColor.withOpacity(0.7),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _generateFromCustomPrompt,
                  icon: const Icon(Icons.auto_awesome,
                      color: AppColors.primaryColor),
                  label: const Text('Generate',
                      style: TextStyle(
                          color: AppColors.primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    shadowColor: AppColors.accentColor.withOpacity(0.5),
                    elevation: 10,
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
