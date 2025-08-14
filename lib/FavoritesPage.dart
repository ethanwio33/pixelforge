// lib/FavoritesPage.dart

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart'; // Import the package

// Import necessary widgets/pages
import 'HomePage.dart'; // For AppColors and other models if needed
import 'WallpaperViewPage.dart';

// NEW: Import the InterstitialAdService to show ads.
import 'services/InterstitialAdService.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  late Future<List<String>> _favoriteWallpapers;

  @override
  void initState() {
    super.initState();
    // Initial load is still necessary
    _loadFavorites();
  }

  // This method reloads the list of favorites from SharedPreferences
  void _loadFavorites() {
    // Check if the widget is still in the tree to avoid errors.
    if (mounted) {
      setState(() {
        _favoriteWallpapers = SharedPreferences.getInstance().then((prefs) {
          return prefs.getStringList('favoriteWallpapers') ?? [];
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap the Scaffold in a VisibilityDetector
    return VisibilityDetector(
      key: const Key('favorites-page-detector'),
      // This callback runs whenever the page's visibility changes
      onVisibilityChanged: (visibilityInfo) {
        // If the page is fully visible, reload the favorites.
        // This ensures the list is always fresh when the user navigates TO this tab.
        if (visibilityInfo.visibleFraction == 1.0) {
          _loadFavorites();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.primaryColor,
        body: FutureBuilder<List<String>>(
          future: _favoriteWallpapers,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.highlightColor));
            } else if (snapshot.hasError) {
              return const Center(
                  child: Text('Could not load favorites.',
                      style: TextStyle(color: AppColors.textColor)));
            } else if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final favorites = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: favorites.length,
                  itemBuilder: (context, index) {
                    final wallpaperUrl = favorites[index];
                    return GestureDetector(
                      // MODIFIED: Show an ad on tap, then navigate.
                      onTap: () {
                        InterstitialAdService.showAd(
                          onAdComplete: () {
                            // This logic runs after the ad is dismissed.
                            Future.microtask(() async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WallpaperViewPage(
                                    wallpaperUrls: favorites,
                                    initialIndex: index,
                                  ),
                                ),
                              );
                              // Reload favorites after returning from the view page.
                              _loadFavorites();
                            });
                          },
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.0),
                        child: Image.network(
                          wallpaperUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) =>
                              progress == null
                                  ? child
                                  : Container(
                                      color: AppColors.secondaryColor,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                            color: AppColors.highlightColor),
                                      ),
                                    ),
                          errorBuilder: (context, error, stack) => Container(
                            color: AppColors.secondaryColor,
                            child: const Icon(Icons.broken_image,
                                color: AppColors.textColor),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            } else {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.heart_slash_fill,
                        size: 80, color: AppColors.textColor),
                    SizedBox(height: 20),
                    Text('No Favorites Yet',
                        style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 22,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(
                      'Tap the heart on a wallpaper to save it here.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppColors.textColor, fontSize: 16),
                    ),
                  ],
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
