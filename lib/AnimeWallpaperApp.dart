import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:http/http.dart' as http;

// Assuming these are your page imports
import 'HomePage.dart';
import 'main/secondhomepage.dart';
import 'main/CategoriesPage.dart';
import 'FavoritesPage.dart';
import 'CategoriesListPage.dart';
import 'SettingsScreen.dart';
import 'services/InterstitialAdService.dart';

// AppColors for the "Cosmic Gradient" theme
class AppColors {
  static const Color primaryColor = Color(0xFF0A0A0A);
  static const Color secondaryColor = Color(0xFF1A1A2E);
  static const Color accentColor = Color(0xFF00F5FF);
  static const Color highlightColor = Color(0xFFFF006E);
  static const Color textColor = Color(0xFFFFFFFF);
  static const Color textSecondaryColor = Color(0xFF9B9B9B);
  static const Color surfaceColor = Color(0xFF16213E);
  static const Color gradientStart = Color(0xFF0F3460);
  static const Color gradientEnd = Color(0xFF533483);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color electricPurple = Color(0xFF8A2BE2);
}

// This is the outer app shell. It contains the top-level navigator.
class AnimeWallpaperApp extends StatelessWidget {
  const AnimeWallpaperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Anime Wallpaper App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primaryColor,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: AppColors.accentColor,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.primaryColor,
        fontFamily: 'Poppins',
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: AppColors.textColor),
          bodyMedium: TextStyle(color: AppColors.textColor),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primaryColor,
          elevation: 0,
          iconTheme: IconThemeData(color: AppColors.textColor),
          titleTextStyle: TextStyle(
            color: AppColors.accentColor,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
            letterSpacing: 1.5,
          ),
        ),
      ),
      home: const AppLoadingScreen(),
    );
  }
}

// --- CHANGE 1: THE NEW APP SHELL, MIMICKING YOUR TEST PAGE ---
// This is the widget we will navigate to. It is the gatekeeper.
class AppShell extends StatelessWidget {
  final Widget homePage;
  final Widget categoriesPage;

  const AppShell({
    required this.homePage,
    required this.categoriesPage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // This PopScope blocks back navigation, just like in your working test.
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        print("--- BACK GESTURE INTERCEPTED & BLOCKED BY APPSHELL ---");
      },
      // THE KEY: Its child is a new, nested MaterialApp.
      // This creates a new "navigation universe" that is trapped inside the PopScope.
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        // We copy the theme from the main app to keep the styling consistent.
        theme: ThemeData(
          primaryColor: AppColors.primaryColor,
          colorScheme: ColorScheme.fromSwatch().copyWith(
            secondary: AppColors.accentColor,
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: AppColors.primaryColor,
          fontFamily: 'Poppins',
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: AppColors.textColor),
            bodyMedium: TextStyle(color: AppColors.textColor),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primaryColor,
            elevation: 0,
            iconTheme: IconThemeData(color: AppColors.textColor),
            titleTextStyle: TextStyle(
              color: AppColors.accentColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              fontFamily: 'Poppins',
              letterSpacing: 1.5,
            ),
          ),
        ),
        home: MainScreen(
          homePage: homePage,
          categoriesPage: categoriesPage,
        ),
      ),
    );
  }
}

class AppLoadingScreen extends StatefulWidget {
  const AppLoadingScreen({super.key});

  @override
  State<AppLoadingScreen> createState() => _AppLoadingScreenState();
}

class _AppLoadingScreenState extends State<AppLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _fetchConfigAndNavigate();
  }

  Future<void> _fetchConfigAndNavigate() async {
    Widget homePage = const HomePage();
    Widget categoriesPage = const CategoriesListPage();

    try {
      final response = await http.get(Uri.parse(
          'https://www.alhyane.fun/ethanwalkerapps/anime/app_config.json'));

      if (response.statusCode == 200) {
        final config = json.decode(response.body);
        if (config['homePageVersion'] == 'B') {
          homePage = const SecondHomePage();
        }
        if (config['categoriesPageVersion'] == 'B') {
          categoriesPage = const CategoriesPage();
        }
      }
    } catch (e) {
      debugPrint("Failed to fetch app config: $e");
    }

    if (mounted) {
      // --- CHANGE 2: NAVIGATE TO THE NEW APPSHELL ---
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AppShell(
            // We navigate to our new protected shell
            homePage: homePage,
            categoriesPage: categoriesPage,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// MainScreen is unchanged. It's just the content inside our new protected universe.
class MainScreen extends StatefulWidget {
  final Widget homePage;
  final Widget categoriesPage;

  const MainScreen({
    required this.homePage,
    required this.categoriesPage,
    super.key,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      widget.homePage,
      widget.categoriesPage,
      const FavoritesPage(),
      const SettingsScreen(),
    ];
  }

  Widget _buildFloatingNavigationBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          borderRadius: BorderRadius.circular(32.0),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(icon: Icons.home_filled, text: 'Home', index: 0),
                _buildNavItem(
                    icon: Icons.category, text: 'Categories', index: 1),
                _buildNavItem(
                    icon: Icons.favorite, text: 'Favorites', index: 2),
                _buildNavItem(icon: Icons.settings, text: 'Settings', index: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String text,
    required int index,
  }) {
    bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (index == _currentIndex) return;
          setState(() {
            _currentIndex = index;
          });
        },
        behavior: HitTestBehavior.translucent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22.0,
              color: isSelected ? Colors.white : Colors.white60,
            ),
            const SizedBox(height: 4),
            AnimatedOpacity(
              opacity: isSelected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryColor,
      body: SafeArea(
        maintainBottomViewPadding: true,
        bottom: false,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 90.0),
              child: IndexedStack(
                index: _currentIndex,
                children: _pages,
              ),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildFloatingNavigationBar(),
            ),
          ],
        ),
      ),
    );
  }
}
