// lib/CategoryPage.dart

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Import project-specific files
import 'HomePage.dart';
import 'WallpaperViewPage.dart';
// NEW: Import the InterstitialAdService to show ads on click.
import 'services/InterstitialAdService.dart';

// ===================================================================
// ---                  ULTRA MODERN CATEGORY PAGE                ---
// ===================================================================
class CategoryPage extends StatefulWidget {
  final Category category;
  final String baseUrl;

  const CategoryPage({
    super.key,
    required this.category,
    required this.baseUrl,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage>
    with TickerProviderStateMixin {
  late final List<String> _shuffledWallpaperUrls;
  late AnimationController _headerAnimationController;
  late AnimationController _gridAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _gridAnimation;

  bool _isHeaderVisible = true;
  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // Create a mutable list of all wallpaper URLs for this category
    final wallpaperUrls = widget.category.wallpapers.map((wallpaper) {
      return '${widget.baseUrl}${widget.category.folder}/${wallpaper.filename}';
    }).toList();

    // Shuffle the list to ensure a different order each time the page is opened
    wallpaperUrls.shuffle();
    _shuffledWallpaperUrls = wallpaperUrls;

    // Initialize animations
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );

    _gridAnimation = CurvedAnimation(
      parent: _gridAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Start animations
    _headerAnimationController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _gridAnimationController.forward();
    });

    // Listen to scroll changes
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final scrollOffset = _scrollController.offset;
    final shouldShowHeader = scrollOffset < 100;

    if (shouldShowHeader != _isHeaderVisible) {
      setState(() {
        _isHeaderVisible = shouldShowHeader;
      });
    }
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _gridAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl =
        '${widget.baseUrl}${widget.category.folder}/${widget.category.thumbnail}';

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Main content
          CustomScrollView(
            controller: _scrollController,
            slivers: <Widget>[
              // Dynamic header that shrinks on scroll
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _headerAnimation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, -50 * (1 - _headerAnimation.value)),
                      child: Opacity(
                        opacity: _headerAnimation.value,
                        child: _buildDynamicHeader(thumbnailUrl),
                      ),
                    );
                  },
                ),
              ),

              // Wallpaper grid
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                sliver: AnimatedBuilder(
                  animation: _gridAnimation,
                  builder: (context, child) {
                    return SliverMasonryGrid.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16.0,
                      crossAxisSpacing: 16.0,
                      childCount: _shuffledWallpaperUrls.length,
                      itemBuilder: (context, index) {
                        final wallpaperUrl = _shuffledWallpaperUrls[index];
                        return Transform.translate(
                          offset: Offset(0, 30 * (1 - _gridAnimation.value)),
                          child: Opacity(
                            opacity: _gridAnimation.value,
                            child: _ModernWallpaperTile(
                              imageUrl: wallpaperUrl,
                              index: index,
                              onTap: () {
                                _handleWallpaperTap(index);
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),

          // Floating back button
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 20,
            child: AnimatedOpacity(
              opacity: _isHeaderVisible ? 1.0 : 0.9,
              duration: const Duration(milliseconds: 300),
              child: _buildFloatingBackButton(),
            ),
          ),

          // Floating category title (appears when scrolling)
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            top: _isHeaderVisible
                ? -100
                : MediaQuery.of(context).padding.top + 20,
            left: 80,
            right: 20,
            child: _buildFloatingTitle(),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicHeader(String thumbnailUrl) {
    return Container(
      height: 320,
      margin: const EdgeInsets.fromLTRB(20, 60, 20, 30),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            CachedNetworkImage(
              imageUrl: thumbnailUrl,
              fit: BoxFit.cover,
            ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.3, 1.0],
                ),
              ),
            ),

            // Content
            Positioned(
              bottom: 40,
              left: 30,
              right: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category name
                  Text(
                    widget.category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Wallpaper count
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_shuffledWallpaperUrls.length} Wallpapers',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Decorative elements
            Positioned(
              top: 30,
              right: 30,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.collections_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingBackButton() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(24),
              child: const Icon(
                Icons.arrow_back_ios_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingTitle() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Center(
            child: Text(
              widget.category.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleWallpaperTap(int index) {
    // Add haptic feedback
    // HapticFeedback.lightImpact();

    InterstitialAdService.showAd(onAdComplete: () {
      Future.microtask(() {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                WallpaperViewPage(
              wallpaperUrls: _shuffledWallpaperUrls,
              initialIndex: index,
            ),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
            transitionDuration: const Duration(milliseconds: 400),
          ),
        );
      });
    });
  }
}

// ===================================================================
// ---              MODERN WALLPAPER TILE WIDGET                  ---
// ===================================================================
class _ModernWallpaperTile extends StatefulWidget {
  final String imageUrl;
  final int index;
  final VoidCallback onTap;

  const _ModernWallpaperTile({
    required this.imageUrl,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ModernWallpaperTile> createState() => _ModernWallpaperTileState();
}

class _ModernWallpaperTileState extends State<_ModernWallpaperTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = (widget.index % 3 == 0) ? 280.0 : 200.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _controller.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _controller.reverse();
              widget.onTap();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _controller.reverse();
            },
            child: Container(
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: _isPressed ? 8 : 15,
                    offset: Offset(0, _isPressed ? 2 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Main image
                    CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildShimmerPlaceholder(),
                      errorWidget: (context, error, stack) =>
                          _buildErrorWidget(),
                    ),

                    // Gradient overlay
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.1),
                            Colors.black.withOpacity(0.3),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.7, 1.0],
                        ),
                      ),
                    ),

                    // Hover/Press effect
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color: _isPressed
                            ? Colors.white.withOpacity(0.1)
                            : Colors.transparent,
                      ),
                    ),

                    // Download icon
                    Positioned(
                      bottom: 12,
                      right: 12,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.download_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1A1A1A),
            const Color(0xFF2A2A2A),
            const Color(0xFF1A1A1A),
          ],
          begin: const Alignment(-1.0, -0.5),
          end: const Alignment(1.0, 0.5),
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Colors.white24,
          size: 40,
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: Colors.white24,
              size: 40,
            ),
            SizedBox(height: 8),
            Text(
              'Failed to load',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
