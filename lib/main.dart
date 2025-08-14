import 'package:provider/provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import '/main/AIWallpaperApp.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import 'flutter_flow/flutter_flow_util.dart';
import 'flutter_flow/nav/nav.dart';
import 'index.dart';
import 'services/InterstitialAdService.dart';

import '/flutter_flow/admob_util.dart';
// main.dart

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // The line below is not needed for the new setup, but can be kept.
  // GoRouter.optionURLReflectsImperativeAPIs = true;
  usePathUrlStrategy();

  // You can keep or remove the FlutterFlow and AdMob initializations
  // depending on whether you need them elsewhere in your app.
  await FlutterFlowTheme.initialize();
  adMobRequestConsent();
  adMobUpdateRequestConfiguration();
  InterstitialAdService.initialize();

  // The FFAppState and ChangeNotifierProvider are part of the old setup.
  // final appState = FFAppState();
  // await appState.initializePersistedState();

  // runApp(ChangeNotifierProvider(
  //   create: (context) => appState,
  //   child: MyApp(),
  // ));

  // --- NEW CODE ---
  // This will now be the entry point of your app.
  runApp(const AIWallpaperApp());
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  State<MyApp> createState() => _MyAppState();

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = FlutterFlowTheme.themeMode;

  late AppStateNotifier _appStateNotifier;
  late GoRouter _router;
  String getRoute([RouteMatch? routeMatch]) {
    final RouteMatch lastMatch =
        routeMatch ?? _router.routerDelegate.currentConfiguration.last;
    final RouteMatchList matchList = lastMatch is ImperativeRouteMatch
        ? lastMatch.matches
        : _router.routerDelegate.currentConfiguration;
    return matchList.uri.toString();
  }

  List<String> getRouteStack() =>
      _router.routerDelegate.currentConfiguration.matches
          .map((e) => getRoute(e))
          .toList();
  @override
  void initState() {
    super.initState();

    _appStateNotifier = AppStateNotifier.instance;
    _router = createRouter(_appStateNotifier);
  }

  void setThemeMode(ThemeMode mode) => safeSetState(() {
        _themeMode = mode;
        FlutterFlowTheme.saveThemeMode(mode);
      });

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Pixel Forge AI',
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en', '')],
      theme: ThemeData(
        brightness: Brightness.light,
        useMaterial3: false,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: false,
      ),
      themeMode: _themeMode,
      routerConfig: _router,
    );
  }
}
