import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class InterstitialAdService {
  static InterstitialAd? _interstitialAd;
  static bool _isAdLoading = false;
  static bool isShowing = false; // ✅ New flag to track if ad is showing

  /// Load the interstitial ad
  static void loadAd() {
    if (_isAdLoading || _interstitialAd != null) return;

    _isAdLoading = true;
    InterstitialAd.load(
      adUnitId:
          'cca-app-pub-2643954879026808/8870779463', // ✅ Replace with your real ID
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isAdLoading = false;
          debugPrint('✅ Interstitial Ad loaded');
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('❌ Failed to load interstitial ad: $error');
          _isAdLoading = false;
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Show the ad if available, then reload
  static void showAd({required VoidCallback onAdComplete}) {
    if (_interstitialAd == null) {
      debugPrint('⚠️ Interstitial Ad not ready, executing callback.');
      onAdComplete();
      loadAd();
      return;
    }

    isShowing = true;

    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('🎬 Interstitial Ad is showing.');
      },
      onAdDismissedFullScreenContent: (InterstitialAd ad) {
        debugPrint('✅ Interstitial Ad dismissed.');
        isShowing = false;
        onAdComplete();
        ad.dispose();
        _interstitialAd = null;
        loadAd();
      },
      onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
        debugPrint('❌ Failed to show interstitial ad: $error');
        isShowing = false;
        onAdComplete();
        ad.dispose();
        _interstitialAd = null;
        loadAd();
      },
    );

    _interstitialAd!.show();
  }

  /// Call this at app startup
  static void initialize() {
    loadAd();
  }
}
