import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui'; // Required for the glass/blur effect
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Page Imports
import 'StylesPage.dart';
import 'CategoryPage.dart';
import 'WallpaperViewPage.dart';
import 'services/InterstitialAdService.dart';
import 'CategoriesListPage.dart';

// NOTE: AppColors should be imported from a shared theme file.
// This local definition is for example purposes.
// AppColors should be imported from your main.dart or a shared theme file.
// For this example, I'm defining it here, but you should remove this
// and rely on the one from your main file.
class AppColors {
  static const Color primaryColor = Color(0xFF0A0A0A); // Deep black
  static const Color secondaryColor = Color(0xFF1A1A2E); // Deep blue-black
  static const Color accentColor = Color(0xFF00F5FF); // Bright cyan
  static const Color highlightColor = Color(0xFFFF006E); // Hot pink
  static const Color textColor = Color(0xFFFFFFFF); // White
  static const Color textSecondaryColor = Color(0xFF9B9B9B); // Gray
  static const Color surfaceColor = Color(0xFF16213E); // Dark blue
  static const Color gradientStart = Color(0xFF0F3460); // Dark blue
  static const Color gradientEnd = Color(0xFF533483); // Purple
  static const Color neonGreen = Color(0xFF39FF14); // Bright green
  static const Color electricPurple = Color(0xFF8A2BE2); // Electric purple
}

// ────────────────────────────────────────────────────────────
// DATA MODELS (Unchanged)
// ────────────────────────────────────────────────────────────
class Wallpaper {
  final String id;
  final String filename;
  Wallpaper({required this.id, required this.filename});

  factory Wallpaper.fromJson(Map<String, dynamic> json) =>
      Wallpaper(id: json['id'], filename: json['filename']);
}

class Category {
  final String name;
  final String folder;
  final String thumbnail;
  final List<Wallpaper> wallpapers;
  Category({
    required this.name,
    required this.folder,
    required this.thumbnail,
    required this.wallpapers,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    final wp =
        (json['wallpapers'] as List).map((e) => Wallpaper.fromJson(e)).toList();
    return Category(
      name: json['name'],
      folder: json['folder'],
      thumbnail: json['thumbnail'],
      wallpapers: wp,
    );
  }
}

class WallpaperCollection {
  final String baseUrl;
  final List<String> trending;
  final List<Category> categories;
  WallpaperCollection({
    required this.baseUrl,
    required this.trending,
    required this.categories,
  });

  factory WallpaperCollection.fromJson(Map<String, dynamic> json) =>
      WallpaperCollection(
        baseUrl: json['baseUrl'],
        trending: List<String>.from(json['trending']),
        categories: (json['categories'] as List)
            .map((e) => Category.fromJson(e))
            .toList(),
      );
}

// ────────────────────────────────────────────────────────────
// REVAMPED: ULTRA-MODERN HOME PAGE
// ────────────────────────────────────────────────────────────
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late Future<WallpaperCollection> _wallpaperCollection;
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _wallpaperCollection = _fetchWallpaperCollection();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
            .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    // Start animation once data is fetched
    _wallpaperCollection.then((_) {
      if (mounted) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _retry() {
    setState(() {
      _wallpaperCollection = _fetchWallpaperCollection();
      _wallpaperCollection.then((_) {
        if (mounted) {
          _animationController.forward();
        }
      });
    });
  }

  Future<WallpaperCollection> _fetchWallpaperCollection() async {
    // This fetching logic is robust and remains unchanged.
    try {
      final res = await http.get(Uri.parse(
          'https://www.alhyane.fun/geminiwallpapers/wallpapers.json'));
      if (res.statusCode == 200) {
        return WallpaperCollection.fromJson(json.decode(res.body));
      }
      throw Exception('Failed to load data from server.');
    } on SocketException {
      throw Exception('No Internet connection.');
    } on TimeoutException {
      throw Exception('Connection timed out.');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: FutureBuilder<WallpaperCollection>(
        future: _wallpaperCollection,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          if (snap.hasError) {
            return _ErrorDisplay(onRetry: _retry);
          }
          if (!snap.hasData) {
            return const Center(
                child: Text('No wallpapers found.',
                    style: TextStyle(color: Colors.white54)));
          }

          final collection = snap.data!;

          // ▼▼▼ NEW LOGIC: Find the featured category ▼▼▼
          final featuredCategory = collection.categories.firstWhere(
            (cat) => cat.name == 'Azure Dreams',
            orElse: () => collection.categories.first, // Fallback
          );
          // ▲▲▲ END OF NEW LOGIC ▲▲▲

          return FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(
                          top: 16.0), // Padding from top nav bar
                      child: _NavigationCard(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Explore AI Verse',
                        subtitle: 'Generate unique wallpapers',
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => StylesPage())),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Trending Now',
                      onSeeAll: () {}, // No "See All" for trending
                      showSeeAll: false,
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _TrendingSection(collection: collection)),

                  // ▼▼▼ NEW SECTION ADDED HERE ▼▼▼
                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Azure Dreams', // Title for the new section
                      onSeeAll: () {
                        // Navigate to the full category page
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => CategoryPage(
                                    category: featuredCategory,
                                    baseUrl: collection.baseUrl)));
                      },
                      showSeeAll: true,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _FeaturedCategorySection(
                      category: featuredCategory,
                      baseUrl: collection.baseUrl,
                    ),
                  ),
                  // ▲▲▲ END OF NEW SECTION ▲▲▲

                  SliverToBoxAdapter(
                    child: _SectionHeader(
                      title: 'Categories',
                      onSeeAll: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CategoriesListPage())),
                      showSeeAll: true,
                    ),
                  ),
                  SliverToBoxAdapter(
                      child: _CategoriesSection(collection: collection)),
                  const SliverToBoxAdapter(child: SizedBox(height: 50)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// REVAMPED UI WIDGETS
// ────────────────────────────────────────────────────────────

// ▼▼▼ NEW WIDGET ADDED HERE ▼▼▼
class _FeaturedCategorySection extends StatelessWidget {
  final Category category;
  final String baseUrl;

  const _FeaturedCategorySection(
      {required this.category, required this.baseUrl});

  @override
  Widget build(BuildContext context) {
    // Create a list of full image URLs for the category
    final urls = category.wallpapers
        .map((w) => '$baseUrl${category.folder}/${w.filename}')
        .toList();

    return SizedBox(
      height: 240, // Same height as trending for consistency
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (c, i) {
          return _TrendingWallpaperTile(
            // Reusing the same tile as the trending section
            imageUrl: urls[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    WallpaperViewPage(wallpaperUrls: urls, initialIndex: i),
              ),
            ),
          );
        },
      ),
    );
  }
}
// ▲▲▲ END OF NEW WIDGET ▲▲▲

class _NavigationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70)),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      color: Colors.white54, size: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool showSeeAll;
  final VoidCallback onSeeAll;

  const _SectionHeader(
      {required this.title, required this.onSeeAll, this.showSeeAll = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          if (showSeeAll)
            GestureDetector(
              onTap: onSeeAll,
              child: const Icon(Icons.arrow_forward,
                  color: Colors.white70, size: 24),
            ),
        ],
      ),
    );
  }
}

class _TrendingSection extends StatelessWidget {
  final WallpaperCollection collection;
  const _TrendingSection({required this.collection});

  @override
  Widget build(BuildContext context) {
    final idToUrl = <String, String>{};
    for (final c in collection.categories) {
      for (final w in c.wallpapers) {
        idToUrl[w.id] = '${collection.baseUrl}${c.folder}/${w.filename}';
      }
    }
    final urls = collection.trending
        .map((id) => idToUrl[id])
        .whereType<String>()
        .toList();

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (c, i) {
          return _TrendingWallpaperTile(
            imageUrl: urls[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                      WallpaperViewPage(wallpaperUrls: urls, initialIndex: i)),
            ),
          );
        },
      ),
    );
  }
}

class _TrendingWallpaperTile extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onTap;
  const _TrendingWallpaperTile({required this.imageUrl, required this.onTap});

  @override
  State<_TrendingWallpaperTile> createState() => _TrendingWallpaperTileState();
}

class _TrendingWallpaperTileState extends State<_TrendingWallpaperTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
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
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: child,
      ),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap();
        },
        onTapCancel: () => _controller.reverse(),
        child: Container(
          width: 160,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: widget.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                  decoration: const BoxDecoration(
                      gradient: LinearGradient(
                          colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight))),
              errorWidget: (context, url, error) =>
                  Container(color: const Color(0xFF1A1A1A)),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoriesSection extends StatelessWidget {
  final WallpaperCollection collection;
  const _CategoriesSection({required this.collection});

  @override
  Widget build(BuildContext context) {
    final shuffledCategories = List.of(collection.categories)..shuffle();

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shuffledCategories.length,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemBuilder: (ctx, i) {
          final cat = shuffledCategories[i];
          return _CategoryChip(
            label: cat.name,
            onTap: () {
              InterstitialAdService.showAd(
                onAdComplete: () => Future.microtask(() => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => CategoryPage(
                            category: cat, baseUrl: collection.baseUrl)))),
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryChip extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _CategoryChip({required this.label, required this.onTap});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _isPressed = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          margin: const EdgeInsets.only(right: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: Center(
                  child: Text(widget.label,
                      style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrorDisplay({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: Colors.white38, size: 64),
              const SizedBox(height: 20),
              const Text('Failed to Load Content',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Please check your network connection and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60, fontSize: 16)),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30))),
                child: const Text('Retry',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              )
            ],
          ),
        ),
      );
}
