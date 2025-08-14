// lib/CategoriesPage.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

// Assuming these pages and models exist from your original file structure.
import '../HomePage.dart';
import '../CategoryPage.dart';
// NEW: Import the InterstitialAdService to show ads on click.
import '../services/InterstitialAdService.dart';

// ===================================================================
// ---         NEW: REPOSITORY FOR DATA FETCHING & CACHING         ---
// ===================================================================
class WallpaperRepository {
  static const String _apiUrl =
      'https://www.alhyane.fun/geminiwallpapers/animewallpapers.json';
  static const String _cacheFileName = 'wallpapers_cache.json';

  Future<File> _getCacheFile() async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/$_cacheFileName');
  }

  /// Fetches wallpaper collection with a cache-first strategy.
  Future<WallpaperCollection> getWallpaperCollection() async {
    final cacheFile = await _getCacheFile();

    // Try fetching from network first.
    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        // If successful, save to cache and return parsed data.
        await cacheFile.writeAsString(response.body);
        return WallpaperCollection.fromJson(json.decode(response.body));
      } else {
        // If server returns an error, try using the cache.
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      // On network error (timeout, no connection, etc.), try loading from cache.
      if (await cacheFile.exists()) {
        final cachedContent = await cacheFile.readAsString();
        return WallpaperCollection.fromJson(json.decode(cachedContent));
      }
      // If network fails and no cache exists, re-throw the original error.
      throw Exception('Failed to fetch data and no cache available: $e');
    }
  }
}

// ===================================================================
// ---               MAIN CATEGORIES LIST PAGE WIDGET              ---
// ===================================================================
class CategoriesPage extends StatefulWidget {
  const CategoriesPage({super.key});

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final WallpaperRepository _repository = WallpaperRepository();
  late Future<WallpaperCollection> _wallpaperCollection;

  @override
  void initState() {
    super.initState();
    _wallpaperCollection = _repository.getWallpaperCollection();
  }

  void _retry() {
    setState(() {
      _wallpaperCollection = _repository.getWallpaperCollection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<WallpaperCollection>(
      future: _wallpaperCollection,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child:
                  CircularProgressIndicator(color: AppColors.highlightColor));
        }
        if (snapshot.hasError) {
          return ErrorDisplay(
              errorMessage: snapshot.error.toString(), onRetry: _retry);
        }
        if (snapshot.hasData) {
          final collection = snapshot.data!;
          // MODIFIED: Create a mutable, shuffled copy of the categories to display them in a random order.
          final categories = List<Category>.from(collection.categories)
            ..shuffle();
          final baseUrl = collection.baseUrl;

          return MasonryGridView.count(
            padding: const EdgeInsets.all(16.0),
            crossAxisCount: 2,
            mainAxisSpacing: 16.0,
            crossAxisSpacing: 16.0,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final height = (index % 3 + 4) * 50.0;
              return GlassCategoryTile(
                category: category,
                baseUrl: baseUrl,
                height: height,
                // MODIFIED: The onTap callback now shows an ad first, then navigates.
                onTap: () {
                  InterstitialAdService.showAd(
                    onAdComplete: () {
                      // Using Future.microtask ensures navigation happens safely after the ad context is dismissed.
                      Future.microtask(() {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CategoryPage(
                              category: category,
                              baseUrl: baseUrl,
                            ),
                          ),
                        );
                      });
                    },
                  );
                },
              );
            },
          );
        }
        return const Center(
          child: Text('No categories found.',
              style: TextStyle(color: AppColors.textColor)),
        );
      },
    );
  }
}

// ===================================================================
// ---        CREATIVE WIDGET: GlassCategoryTile (with Caching)    ---
// ===================================================================
class GlassCategoryTile extends StatelessWidget {
  final Category category;
  final String baseUrl;
  final double height;
  final VoidCallback onTap;

  const GlassCategoryTile({
    super.key,
    required this.category,
    required this.baseUrl,
    required this.height,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = '$baseUrl${category.folder}/${category.thumbnail}';

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- Layer 1: The Background Image (NOW CACHED) ---
              CachedNetworkImage(
                imageUrl: thumbnailUrl,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    Container(color: AppColors.secondaryColor.withOpacity(0.5)),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.secondaryColor,
                  child: const Icon(Icons.broken_image_rounded,
                      color: AppColors.textColor, size: 40),
                ),
              ),

              // --- Layer 2: The Glass Effect (Unchanged) ---
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24.0),
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              // --- Layer 3: The Content (Unchanged) ---
              Positioned(
                bottom: 12.0,
                left: 16.0,
                right: 16.0,
                child: Text(
                  category.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black,
                        offset: Offset(0, 2),
                      ),
                    ],
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

// NOTE: Ensure these widgets/classes are defined elsewhere in your project as they were in the original code.
// No changes were made to these helper widgets.
class ErrorDisplay extends StatelessWidget {
  final VoidCallback onRetry;
  final String errorMessage;
  const ErrorDisplay(
      {super.key,
      required this.onRetry,
      this.errorMessage = "An error occurred."});

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(errorMessage, style: const TextStyle(color: AppColors.textColor)),
      const SizedBox(height: 20),
      ElevatedButton(onPressed: onRetry, child: const Text('Retry'))
    ]));
  }
}

class AppColors {
  static const Color primaryColor = Color(0xFF101820);
  static const Color secondaryColor = Color(0xFF1D2939);
  static const Color highlightColor = Color(0xFFFEE715);
  static const Color textColor = Color(0xFFF2F4F7);
}
