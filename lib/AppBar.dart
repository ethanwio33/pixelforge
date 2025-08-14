import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Import all possible pages
import 'HomePage.dart';
import 'FavoritesPage.dart';
import 'CategoriesListPage.dart';
import 'SettingsScreen.dart';
import 'main/secondhomepage.dart';
import 'main/CategoriesPage.dart';

class MainTabLayout extends StatefulWidget {
  const MainTabLayout({super.key});

  @override
  State<MainTabLayout> createState() => _MainTabLayoutState();
}

class _MainTabLayoutState extends State<MainTabLayout> {
  // A state variable to hold the list of pages.
  // It will be updated after we fetch the config.
  List<Widget> _pages = [];

  // A state variable to show a loading indicator.
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Fetch the configuration when the widget is first created.
    _loadPageConfig();
  }

  Future<void> _loadPageConfig() async {
    // Define the default "A" version pages first.
    Widget homeWidget = const HomePage();
    Widget categoriesWidget = const CategoriesListPage();
    const String configUrl =
        'https://www.alhyane.fun/ethanwalkerapps/anime/app_config.json';

    try {
      final response = await http.get(Uri.parse(configUrl));
      if (response.statusCode == 200) {
        final config = json.decode(response.body);

        // Check the version for the home page.
        if (config['homePageVersion'] == 'B') {
          homeWidget = const SecondHomePage();
        }

        // Check the version for the categories page.
        if (config['categoriesPageVersion'] == 'B') {
          categoriesWidget = const CategoriesPage();
        }
      }
    } catch (e) {
      print("Failed to load page config: $e. Using default pages.");
    }

    // Use setState to rebuild the widget with the correct pages.
    if (mounted) {
      setState(() {
        _pages = [
          homeWidget,
          categoriesWidget,
          const FavoritesPage(),
          const SettingsScreen(),
        ];
        _isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while fetching the config.
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).indicatorColor,
          ),
        ),
      );
    }

    // Once loaded, build the main UI, keeping WillPopScope intact.
    return WillPopScope(
      onWillPop: () async {
        print("Back navigation attempt blocked.");
        return false;
      },
      child: DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Anime App'),
            automaticallyImplyLeading: false,
            bottom: const TabBar(
              isScrollable: false,
              indicatorWeight: 3.0,
              tabs: [
                Tab(icon: Icon(Icons.home), text: 'Home'),
                Tab(icon: Icon(Icons.category), text: 'Categories'),
                Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
                Tab(icon: Icon(Icons.settings), text: 'Settings'),
              ],
            ),
          ),
          // The TabBarView now uses our state variable `_pages`.
          body: TabBarView(
            children: _pages,
          ),
        ),
      ),
    );
  }
}
