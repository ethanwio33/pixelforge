// lib/CategoriesListPage.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Project-specific files
import 'HomePage.dart'; // Assuming this defines WallpaperCollection, Category, etc.
import 'CategoryPage.dart';

// ===================================================================
// ---         REPOSITORY FOR DATA FETCHING & CACHING (Unchanged)  ---
// ===================================================================
class WallpaperRepository {
  static const String _apiUrl =
      'https://www.alhyane.fun/geminiwallpapers/wallpapers.json';
  static const String _cacheFileName = 'wallpapers_cache.json';

  Future<File> _getCacheFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_cacheFileName');
  }

  Future<WallpaperCollection> getWallpaperCollection() async {
    final cacheFile = await _getCacheFile();
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        await cacheFile.writeAsString(response.body);
        return WallpaperCollection.fromJson(json.decode(response.body));
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      if (await cacheFile.exists()) {
        final cachedContent = await cacheFile.readAsString();
        return WallpaperCollection.fromJson(json.decode(cachedContent));
      }
      throw Exception('Failed to fetch data and no cache available: $e');
    }
  }
}

// ===================================================================
// ---      REVAMPED: ULTRA-MODERN CATEGORIES LIST PAGE WIDGET     ---
// ===================================================================
class CategoriesListPage extends StatefulWidget {
  const CategoriesListPage({super.key});

  @override
  State<CategoriesListPage> createState() => _CategoriesListPageState();
}

class _CategoriesListPageState extends State<CategoriesListPage>
    with TickerProviderStateMixin {
  final WallpaperRepository _repository = WallpaperRepository();
  late Future<WallpaperCollection> _wallpaperCollection;

  // Animation controllers for the staggered entry effect
  late AnimationController _headerAnimationController;
  late AnimationController _gridAnimationController;
  late Animation<double> _headerAnimation;
  late Animation<double> _gridAnimation;

  @override
  void initState() {
    super.initState();
    _wallpaperCollection = _repository.getWallpaperCollection();

    // Initialize animations
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _gridAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    _gridAnimation = CurvedAnimation(
      parent: _gridAnimationController,
      curve: Curves.easeOutCubic,
    );

    // Start animations after a short delay to allow the page to build
    Future.delayed(const Duration(milliseconds: 100), () {
      _headerAnimationController.forward();
      // Stagger the grid animation for a more dynamic effect
      Future.delayed(const Duration(milliseconds: 200), () {
        _gridAnimationController.forward();
      });
    });
  }

  void _retry() {
    setState(() {
      _wallpaperCollection = _repository.getWallpaperCollection();
    });
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _gridAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: FutureBuilder<WallpaperCollection>(
        future: _wallpaperCollection,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          if (snapshot.hasError) {
            return _ErrorDisplay(
              errorMessage: snapshot.error.toString(),
              onRetry: _retry,
            );
          }
          if (snapshot.hasData) {
            final collection = snapshot.data!;
            final categories = collection.categories;
            final baseUrl = collection.baseUrl;

            // Main UI with CustomScrollView for advanced layouts
            return CustomScrollView(
              slivers: <Widget>[
                // Sliver 1: The Animated Header
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _headerAnimation,
                    builder: (context, child) => Transform.translate(
                      offset: Offset(0, 30 * (1 - _headerAnimation.value)),
                      child: Opacity(
                        opacity: _headerAnimation.value,
                        child: _buildHeader(),
                      ),
                    ),
                  ),
                ),

                // Sliver 2: The Animated Category Grid
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  sliver: AnimatedBuilder(
                    animation: _gridAnimation,
                    builder: (context, child) {
                      return SliverMasonryGrid.count(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16.0,
                        crossAxisSpacing: 16.0,
                        childCount: categories.length,
                        itemBuilder: (context, index) {
                          final category = categories[index];
                          // Apply animation to each tile
                          return Transform.translate(
                            offset: Offset(0, 40 * (1 - _gridAnimation.value)),
                            child: Opacity(
                              opacity: _gridAnimation.value,
                              child: _ModernCategoryTile(
                                category: category,
                                baseUrl: baseUrl,
                                onTap: () => _navigateToCategory(
                                  context,
                                  category,
                                  baseUrl,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          }
          return const Center(
            child: Text(
              'No categories found.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        },
      ),
    );
  }

  // A new header widget consistent with the modern design
  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        MediaQuery.of(context).padding.top + 24,
        24,
        24,
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Explore Collections',
            style: TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Find your next favorite wallpaper',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  // Navigation logic with a smooth, consistent page transition
  void _navigateToCategory(
      BuildContext context, Category category, String baseUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CategoryPage(
          category: category,
          baseUrl: baseUrl,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubic;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }
}

// ===================================================================
// ---           NEW: _ModernCategoryTile WIDGET                   ---
// ===================================================================
class _ModernCategoryTile extends StatefulWidget {
  final Category category;
  final String baseUrl;
  final VoidCallback onTap;

  const _ModernCategoryTile({
    required this.category,
    required this.baseUrl,
    required this.onTap,
  });

  @override
  State<_ModernCategoryTile> createState() => _ModernCategoryTileState();
}

class _ModernCategoryTileState extends State<_ModernCategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation =
        Tween<double>(begin: 1.0, end: 0.95).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl =
        '${widget.baseUrl}${widget.category.folder}/${widget.category.thumbnail}';
    // Use a pseudo-random height based on the category name length for variety
    final height = (widget.category.name.length % 3 + 4) * 55.0;

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
                    offset: Offset(0, _isPressed ? 4 : 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Layer 1: Cached background image
                    CachedNetworkImage(
                      imageUrl: thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildShimmerPlaceholder(),
                      errorWidget: (context, error, stack) =>
                          _buildErrorWidget(),
                    ),

                    // Layer 2: Protective gradient for text legibility
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.2),
                            Colors.black.withOpacity(0.7),
                          ],
                          begin: Alignment.center,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),

                    // Layer 3: Content
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category Name
                          Text(
                            widget.category.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Wallpaper Count in a styled "pill"
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              '${widget.category.wallpapers.length} Wallpapers',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
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

  // A shimmer placeholder consistent with the modern aesthetic
  Widget _buildShimmerPlaceholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A), Color(0xFF1A1A1A)],
          begin: Alignment(-1.0, -0.5),
          end: Alignment(1.0, 0.5),
          stops: [0.0, 0.5, 1.0],
          tileMode: TileMode.repeated,
        ),
      ),
    );
  }

  // An error widget that fits the dark theme
  Widget _buildErrorWidget() {
    return Container(
      color: const Color(0xFF1A1A1A),
      child: const Center(
        child:
            Icon(Icons.broken_image_outlined, color: Colors.white24, size: 48),
      ),
    );
  }
}

// ===================================================================
// ---           THEME-ALIGNED ERROR AND RETRY WIDGET              ---
// ===================================================================
class _ErrorDisplay extends StatelessWidget {
  final VoidCallback onRetry;
  final String errorMessage;

  const _ErrorDisplay({
    required this.onRetry,
    this.errorMessage = "An error occurred.",
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: Colors.white38, size: 64),
            const SizedBox(height: 20),
            Text(
              'Failed to Load Content',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please check your network connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60, fontSize: 16),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text('Retry', style: TextStyle(fontSize: 16)),
            )
          ],
        ),
      ),
    );
  }
}
