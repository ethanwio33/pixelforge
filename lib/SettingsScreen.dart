// lib/SettingsScreen.dart

// IMPORTANT: You must add the url_launcher package to your pubspec.yaml file
// for the Privacy Policy and Support links to work.
//
// dependencies:
//   flutter:
//     sdk: flutter
//   url_launcher: ^6.1.12 # or latest version

import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // Import the package
import 'StylesPage.dart'; // Make sure StylesPage.dart is in the same directory or imported correctly
import 'HowToSetWallpaperIOS.dart';

// Assuming AppColors is in a separate file. Let's define it here for clarity.
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

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // --- URLs for the buttons ---
  final Uri _privacyPolicyUrl = Uri.parse(
      'https://sites.google.com/view/ethanw22/home'); // <-- TODO: REPLACE WITH YOUR ACTUAL URL
  final Uri _supportUrl = Uri.parse(
      'mailto:ethanwio22@gmail.com?subject=App Support Request&body=Please describe your issue:');

  // --- Helper function to launch a URL ---
  Future<void> _launchUrl(Uri url) async {
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      // Show an error message if the URL can't be launched
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not launch $url'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          const SizedBox(
              height: 60), // Space for the AppBar from a potential MainScreen

          // --- The prominent "AI Verse" button ---
          GestureDetector(
            onTap: () {
              //Navigate to the StylesPage when the button is tapped
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => StylesPage()),
              );
            },
            child: const AiVerseButton(),
          ),

          const SizedBox(height: 30),

          // --- Section for General Settings ---
          // This section is now empty after removing the requested buttons.
          // We can remove the header if no items remain.
          // const SectionHeader(title: 'General Settings'),
          // const SizedBox(height: 10),

          // --- Section for About the App ---
          const SectionHeader(title: 'About'),
          const SizedBox(height: 10),
          GlassSettingButton(
            icon: CupertinoIcons.lock_shield_fill,
            text: 'Privacy Policy',
            onTap: () {
              // Launch the privacy policy URL
              _launchUrl(_privacyPolicyUrl);
            },
          ),
          const SizedBox(height: 12),
          GlassSettingButton(
            icon: CupertinoIcons.question_circle_fill,
            text: 'Support',
            onTap: () {
              // Launch the mail app for support
              _launchUrl(_supportUrl);
            },
          ),
          const SizedBox(height: 12),
          GlassSettingButton(
            icon: CupertinoIcons.photo_fill_on_rectangle_fill,
            text: 'How to Set Wallpaper',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const HowToSetWallpaperIOSPage(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// ---               Custom Reusable Widgets for this Screen       ---
// ===================================================================

/// A reusable header for settings sections
class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        color: AppColors.textColor.withOpacity(0.6),
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

/// The special, prominent button for "AI Verse"
class AiVerseButton extends StatelessWidget {
  const AiVerseButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.highlightColor.withOpacity(0.9),
                const Color(0xFFFEE715).withOpacity(0.6)
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.sparkles,
                color: AppColors.primaryColor,
                size: 28,
              ),
              SizedBox(width: 12),
              Text(
                'Enter AI Verse',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable layered panel button for standard settings
class GlassSettingButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const GlassSettingButton({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.secondaryColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.textColor.withOpacity(0.8), size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    color: AppColors.textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.right_chevron,
                color: AppColors.textColor.withOpacity(0.5),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A reusable layered panel with a toggle switch (Kept for potential future use)
class GlassSettingToggle extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassSettingToggle({
    super.key,
    required this.icon,
    required this.text,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
        decoration: BoxDecoration(
          color: AppColors.secondaryColor.withOpacity(0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textColor.withOpacity(0.8), size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.highlightColor,
              trackColor: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
