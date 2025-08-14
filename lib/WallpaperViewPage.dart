import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

// Import project-specific files
import 'services/InterstitialAdService.dart';

// ────────────────────────────────────────────────────────────
// REVAMPED: ULTRA-MODERN WALLPAPER VIEW PAGE
// ────────────────────────────────────────────────────────────
class WallpaperViewPage extends StatefulWidget {
  final List<String> wallpaperUrls;
  final int initialIndex;

  const WallpaperViewPage({
    super.key,
    required this.wallpaperUrls,
    required this.initialIndex,
  });

  @override
  State<WallpaperViewPage> createState() => _WallpaperViewPageState();
}

class _WallpaperViewPageState extends State<WallpaperViewPage> {
  late PageController _pageController;
  late Set<String> _favoriteWallpapers;
  bool _areControlsVisible = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialIndex);
    _favoriteWallpapers = {};
    _loadFavorites();
    // Enter immersive mode when the page is displayed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    // Exit immersive mode when the page is closed
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _pageController.dispose();
    super.dispose();
  }

  // --- Data & Logic ---

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _favoriteWallpapers =
          (prefs.getStringList('favoriteWallpapers') ?? []).toSet();
    });
  }

  Future<void> _toggleFavorite(String url) async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (_favoriteWallpapers.contains(url)) {
        _favoriteWallpapers.remove(url);
      } else {
        _favoriteWallpapers.add(url);
      }
    });
    await prefs.setStringList(
        'favoriteWallpapers', _favoriteWallpapers.toList());
  }

  Future<void> _downloadWallpaper(BuildContext context, String url) async {
    if (_isDownloading) return;

    setState(() => _isDownloading = true);

    try {
      final status = await Permission.storage.request();
      if (status.isGranted) {
        final tempDir = await getTemporaryDirectory();
        final path = '${tempDir.path}/${url.hashCode}.jpg';
        final response = await http.get(Uri.parse(url));
        await File(path).writeAsBytes(response.bodyBytes);

        final success =
            await GallerySaver.saveImage(path, albumName: 'Gemini Wallpapers');

        if (mounted && success == true) {
          _showStyledSnackBar('Wallpaper saved to Gallery!');
        } else {
          _showStyledSnackBar('Failed to save wallpaper.');
        }
      } else {
        _showStyledSnackBar('Storage permission is required.');
      }
    } catch (e) {
      if (mounted) {
        _showStyledSnackBar('An error occurred while saving.');
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  String _getCurrentUrl() {
    final page = _pageController.hasClients
        ? _pageController.page?.round()
        : widget.initialIndex;
    return widget.wallpaperUrls[page ?? widget.initialIndex];
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _areControlsVisible = !_areControlsVisible),
        child: Stack(
          children: [
            // Background Wallpaper
            _buildWallpaperViewer(),

            // Top Back Button
            _buildTopBar(),

            // Bottom Action Bar
            _buildBottomActionBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildWallpaperViewer() {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.wallpaperUrls.length,
      onPageChanged: (index) {
        // NOTE: Showing an ad on every swipe is very aggressive and may
        // lead to a poor user experience. Consider a less frequent trigger.
        InterstitialAdService.showAd(onAdComplete: () {});
        setState(() {}); // Update favorite button state on swipe
      },
      itemBuilder: (context, index) {
        return CachedNetworkImage(
          imageUrl: widget.wallpaperUrls[index],
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: const Color(0xFF1A1A1A),
          ),
          errorWidget: (context, url, error) => const Center(
            child: Icon(Icons.broken_image_outlined,
                color: Colors.white24, size: 48),
          ),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      top: _areControlsVisible ? MediaQuery.of(context).padding.top + 12 : -80,
      left: 20,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _areControlsVisible ? 1.0 : 0.0,
        child: _GlassIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      bottom: _areControlsVisible ? 30 : -120,
      left: 20,
      right: 20,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: _areControlsVisible ? 1.0 : 0.0,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              height: 80,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _GlassIconButton(
                    icon: Icons.download_rounded,
                    isLoading: _isDownloading,
                    onTap: () => InterstitialAdService.showAd(
                      onAdComplete: () => Future.microtask(
                        () => _downloadWallpaper(context, _getCurrentUrl()),
                      ),
                    ),
                  ),
                  _GlassIconButton(
                    icon: Icons.wallpaper_rounded,
                    onTap: () => InterstitialAdService.showAd(
                      onAdComplete: () => _showHowToSetDialog(context),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, _) {
                      final url = _getCurrentUrl();
                      final isFavorite = _favoriteWallpapers.contains(url);
                      return _GlassIconButton(
                        icon: isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        isActive: isFavorite,
                        onTap: () => InterstitialAdService.showAd(
                          onAdComplete: () => _toggleFavorite(url),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Dialogs & SnackBars ---

  void _showHowToSetDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How to Set',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 16),
                const Text(
                  '1. Go to your phone\'s Gallery/Photos app.\n'
                  '2. Find the wallpaper you just saved.\n'
                  '3. Tap the options menu (⋮) and choose "Set as wallpaper".',
                  style: TextStyle(
                      fontSize: 16, color: Colors.white70, height: 1.5),
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('GOT IT',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showStyledSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.black.withOpacity(0.7),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// HELPER WIDGET: _GlassIconButton
// ────────────────────────────────────────────────────────────
class _GlassIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isActive;
  final bool isLoading;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    this.isActive = false,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(isActive ? 0.2 : 0.1),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white),
                )
              : Icon(
                  icon,
                  color: isActive ? const Color(0xFFFF006E) : Colors.white,
                  size: 24,
                ),
        ),
      ),
    );
  }
}
