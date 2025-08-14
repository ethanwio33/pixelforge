// lib/AIPage.dart

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'openai_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

// A map to hold background images for each style
final Map<String, String> styleBackgrounds = {
  'Cyberpunk': 'assets/images/cyberpunk.jpg',
  'Nature': 'assets/images/nature.jpg',
  'Minimal': 'assets/images/minimal.jpg',
  'Vintage': 'assets/images/vintage.jpg',
  // Add other styles and their corresponding image paths here
};

class AIPage extends StatefulWidget {
  final String? initialPrompt;

  const AIPage({super.key, this.initialPrompt});

  @override
  State<AIPage> createState() => _AIPageState();
}

class AppColors {
  static const Color primaryColor = Color(0xFF101820);
  static const Color secondaryColor = Color(0xFF1D2939);
  static const Color accentColor = Color(0xFFFEE715);
  static const Color textColor = Color(0xFFF2F4F7);
}

class _AIPageState extends State<AIPage> with SingleTickerProviderStateMixin {
  final _textController = TextEditingController();
  final _openAIService = OpenAIService();
  String? _imageUrl;
  bool _isLoading = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation =
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
  }

  @override
  void dispose() {
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _generateWallpaper() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a description for the wallpaper.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _imageUrl = null; // Clear previous image
      _fadeController.reverse();
    });

    try {
      // Create an enhanced prompt by combining user input with the selected style
      final userPrompt = _textController.text;
      final style = widget.initialPrompt ?? 'digital art'; // fallback style
      final enhancedPrompt =
          '$userPrompt, in the style of $style, 4k, cinematic, highly detailed';

      final url = await _openAIService.generateImage(enhancedPrompt);
      setState(() {
        _imageUrl = url;
      });
      _fadeController.forward(); // Fade in the new image and buttons
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _downloadImage() async {
    if (_imageUrl == null) return;

    // 1. Request Permission using 'storage' to align with other pages.
    // This permission is generally used for adding files, not reading them.
    var status = await Permission.storage.request();

    if (status.isGranted) {
      setState(() {
        // You might want a loading indicator specifically for downloads
      });

      try {
        // 2. Download image using Dio
        final dio = Dio();
        final response = await dio.get(
          _imageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );

        // 3. Save to gallery
        await ImageGallerySaver.saveImage(
          Uint8List.fromList(response.data),
          quality: 100,
          name: "ai_wallpaper_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Wallpaper saved to gallery! ✅')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error saving image: ${e.toString()}')),
          );
        }
      } finally {
        setState(() {
          // Turn off download-specific loading indicator if you have one
        });
      }
    } else if (status.isPermanentlyDenied) {
      // Handle the case where user permanently denied permission
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Permission denied. Please enable it in app settings to save images.')),
        );
        // Optionally, open app settings
        // openAppSettings();
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Permission denied. Cannot save image.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the background image based on the selected style
    final backgroundAsset =
        styleBackgrounds[widget.initialPrompt] ?? 'assets/images/default.jpg';

    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Stack(
        children: [
          // --- Animated Background Image ---
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 700),
            child: Container(
              key: ValueKey<String>(_imageUrl ?? backgroundAsset),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: _imageUrl != null
                      ? CachedNetworkImageProvider(_imageUrl!)
                      : AssetImage(backgroundAsset) as ImageProvider,
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(color: Colors.black.withOpacity(0.4)),
              ),
            ),
          ),

          // --- Main UI Content ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // --- Header ---
                  _buildHeader(),
                  const Spacer(),

                  // --- Image Display Area ---
                  _buildImageDisplay(),
                  const Spacer(),

                  // --- Action Buttons (Download/Share) ---
                  _buildActionButtons(),

                  // --- Prompt Input & Generate Button ---
                  _buildPromptSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.white, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        Text(
          widget.initialPrompt ?? 'Generator',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 48), // To balance the back button
      ],
    );
  }

  Widget _buildImageDisplay() {
    return Expanded(
      flex: 8,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CupertinoActivityIndicator(
                        color: Colors.white, radius: 14),
                    const SizedBox(height: 15),
                    Text(
                      'Generating your vision...',
                      style: TextStyle(
                          color: AppColors.textColor.withOpacity(0.8)),
                    ),
                  ],
                ),
              )
            : _imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: CachedNetworkImage(
                      imageUrl: _imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) =>
                          Container(color: Colors.black12),
                    ),
                  )
                : const SizedBox(),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isLoading || _imageUrl == null) {
      return const SizedBox(height: 60); // Reserve space
    }
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Download Button ---
            ElevatedButton.icon(
              onPressed: _downloadImage,
              icon: const Icon(CupertinoIcons.arrow_down,
                  color: AppColors.primaryColor),
              label: const Text('Download'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                foregroundColor: AppColors.primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromptSection() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.only(left: 20, right: 8, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: AppColors.textColor),
                  decoration: const InputDecoration(
                    hintText: 'Describe your vision...',
                    hintStyle: TextStyle(color: AppColors.textColor),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // --- Generate Button ---
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.accentColor,
                child: IconButton(
                  icon: const Icon(
                    CupertinoIcons.sparkles,
                    color: AppColors.primaryColor,
                  ),
                  onPressed: _generateWallpaper,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
