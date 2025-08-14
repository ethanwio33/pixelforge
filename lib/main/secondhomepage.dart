// lib/secondhomepage.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../services/InterstitialAdService.dart';

// ────────────────────────────────────────────────────────────
//  PAGE IMPORTS
// ────────────────────────────────────────────────────────────
// Ensure these paths are correct for your project structure
import '../CategoryPage.dart';
import '../WallpaperViewPage.dart';
import '../HomePage.dart' as baseModels;

// ────────────────────────────────────────────────────────────
//  DATA MODELS
// ────────────────────────────────────────────────────────────
// Note: In a real app, these models should be in their own file
// to avoid duplication (e.g., 'lib/models/wallpaper_models.dart').
typedef Wallpaper = baseModels.Wallpaper;
typedef Category = baseModels.Category;
typedef WallpaperCollection = baseModels.WallpaperCollection;

// ────────────────────────────────────────────────────────────
//  APP COLOURS
// ────────────────────────────────────────────────────────────
// Note: This should also be in a central file (e.g., 'lib/theme/app_colors.dart').
class AppColors {
  static const Color primaryColor = Color(0xFF121212); // Very dark gray
  static const Color secondaryColor =
      Color(0xFF1A1A1A); // Slightly lighter dark gray for surfaces
  static const Color accentColor = Color(0xFFFFD700); // Gold
  static const Color highlightColor = Color(0xFFFFD700); // Gold
  static const Color textColor = Color(0xFFFFFFFF); // White
  static const Color textSecondaryColor =
      Color(0xFFC0C0C0); // Silver/Light Gray for unselected items
}

// ────────────────────────────────────────────────────────────
//  REUSABLE UI BITS
// ────────────────────────────────────────────────────────────
// Note: These widgets are perfect candidates for a shared widget file
// (e.g., 'lib/widgets/shared_widgets.dart').
class SectionTitle extends StatelessWidget {
  final String title;
  const SectionTitle(this.title, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          title,
          style: const TextStyle(
              color: AppColors.textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
      );
}

class ErrorDisplay extends StatelessWidget {
  final VoidCallback onRetry;
  const ErrorDisplay({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, color: AppColors.textColor, size: 80),
            const SizedBox(height: 20),
            const Text('Connection Error',
                style: TextStyle(color: AppColors.textColor, fontSize: 22)),
            const SizedBox(height: 10),
            const Text(
              'Could not connect to the server.\nPlease check your internet connection.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textColor, fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.highlightColor,
                  foregroundColor: AppColors.primaryColor),
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
}

// ────────────────────────────────────────────────────────────
//  WALLPAPER STRIPS
// ────────────────────────────────────────────────────────────
class _WallpaperThumb extends StatelessWidget {
  final String url;
  final List<String> allUrls;
  final int index;
  const _WallpaperThumb(
      {required this.url, required this.allUrls, required this.index});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          InterstitialAdService.showAd(
            onAdComplete: () {
              Future.microtask(() {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WallpaperViewPage(
                      wallpaperUrls: allUrls,
                      initialIndex: index,
                    ),
                  ),
                );
              });
            },
          );
        },
        child: Container(
          width: 150,
          margin: EdgeInsets.only(
              left: index == 0 ? 16 : 8,
              right: index == allUrls.length - 1 ? 16 : 8,
              top: 8,
              bottom: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (c, child, prog) => prog == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.highlightColor)),
              errorBuilder: (c, e, s) => Container(
                color: AppColors.secondaryColor,
                child:
                    const Icon(Icons.broken_image, color: AppColors.textColor),
              ),
            ),
          ),
        ),
      );
}

class TrendingWallpapers extends StatelessWidget {
  final WallpaperCollection collection;
  const TrendingWallpapers({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    final idToUrl = <String, String>{};
    for (final c in collection.categories) {
      for (final w in c.wallpapers) {
        idToUrl[w.id] = '${collection.baseUrl}${c.folder}/${w.filename}';
      }
    }
    // MODIFIED: Create a mutable list of URLs and shuffle them for a new order on each build.
    final urls = collection.trending
        .map((id) => idToUrl[id])
        .whereType<String>()
        .toList()
      ..shuffle();

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (c, i) =>
            _WallpaperThumb(url: urls[i], allUrls: urls, index: i),
      ),
    );
  }
}

class CategoryWallpapers extends StatelessWidget {
  final WallpaperCollection collection;
  final String categoryName;
  const CategoryWallpapers(
      {super.key, required this.collection, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final cat = collection.categories.firstWhere((c) => c.name == categoryName,
        orElse: () => Category(
            name: '', folder: '', thumbnail: '', wallpapers: const []));
    if (cat.wallpapers.isEmpty) return const SizedBox.shrink();

    // MODIFIED: Create a mutable list of URLs from the category's wallpapers and shuffle them.
    final urls = cat.wallpapers
        .map((w) => '${collection.baseUrl}${cat.folder}/${w.filename}')
        .toList()
      ..shuffle();

    return SizedBox(
      height: 250,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: urls.length,
        itemBuilder: (c, i) =>
            _WallpaperThumb(url: urls[i], allUrls: urls, index: i),
      ),
    );
  }
}

class CategoryList extends StatelessWidget {
  final WallpaperCollection collection;
  const CategoryList({super.key, required this.collection});

  @override
  Widget build(BuildContext context) {
    // MODIFIED: Create a mutable, shuffled copy of the categories list for a new order on each build.
    final shuffledCategories = List<Category>.from(collection.categories)
      ..shuffle();

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: shuffledCategories.length, // Use the shuffled list
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (ctx, i) {
          final cat = shuffledCategories[i]; // Use the shuffled list
          final thumb = '${collection.baseUrl}${cat.folder}/${cat.thumbnail}';

          return GestureDetector(
            onTap: () {
              InterstitialAdService.showAd(
                onAdComplete: () {
                  Future.microtask(() {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CategoryPage(
                          category: cat,
                          baseUrl: collection.baseUrl,
                        ),
                      ),
                    );
                  });
                },
              );
            },
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: 100,
                maxWidth: 200,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondaryColor,
                  borderRadius: BorderRadius.circular(30),
                  image: DecorationImage(
                    image: NetworkImage(thumb),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                        Colors.black.withOpacity(0.5), BlendMode.darken),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 5,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//  MAIN PAGE (STATEFUL) - RENAMED
// ────────────────────────────────────────────────────────────
class SecondHomePage extends StatefulWidget {
  const SecondHomePage({super.key});

  @override
  State<SecondHomePage> createState() => _SecondHomePageState();
}

class _SecondHomePageState extends State<SecondHomePage> {
  late Future<WallpaperCollection> _wallpaperCollection;

  @override
  void initState() {
    super.initState();
    _wallpaperCollection = _fetchWallpaperCollection();
  }

  void _retry() {
    final next = _fetchWallpaperCollection();
    setState(() {
      _wallpaperCollection = next;
    });
  }

  Future<WallpaperCollection> _fetchWallpaperCollection() async {
    try {
      final res = await http.get(Uri.parse(
          'https://www.alhyane.fun/geminiwallpapers/animewallpapers.json'));
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
  Widget build(BuildContext context) => FutureBuilder<WallpaperCollection>(
        future: _wallpaperCollection,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: AppColors.primaryColor,
              body: Center(
                  child: CircularProgressIndicator(
                      color: AppColors.highlightColor)),
            );
          }
          if (snap.hasError) {
            return Scaffold(
              backgroundColor: AppColors.primaryColor,
              body: ErrorDisplay(onRetry: _retry),
            );
          }
          if (!snap.hasData) {
            return const Scaffold(
              backgroundColor: AppColors.primaryColor,
              body: Center(
                  child: Text('No wallpapers found.',
                      style: TextStyle(color: AppColors.textColor))),
            );
          }

          final collection = snap.data!;
          return Scaffold(
            backgroundColor: AppColors.primaryColor,
            body: CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: SectionTitle('Categories')),
                SliverToBoxAdapter(child: CategoryList(collection: collection)),
                const SliverToBoxAdapter(
                    child: SectionTitle('Trending Wallpapers')),
                SliverToBoxAdapter(
                    child: CategoryWallpapers(
                        collection: collection,
                        categoryName: 'Trending Wallpapers')),
                const SliverToBoxAdapter(child: SectionTitle('New Arrivals')),
                SliverToBoxAdapter(
                    child: CategoryWallpapers(
                        collection: collection, categoryName: 'New Arrivals')),
                const SliverToBoxAdapter(child: SectionTitle('AI Generated')),
                SliverToBoxAdapter(
                    child: CategoryWallpapers(
                        collection: collection, categoryName: 'AI Generated')),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
            ),
          );
        },
      );
}
