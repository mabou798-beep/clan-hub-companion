/// AdMob unit IDs. Release builds use the real IDs below; debug builds and
/// --dart-define=USE_TEST_ADS=true use Google's public test units.
///
/// Every real ID must start with ca-app-pub-5383120911029833. Empty IDs mean
/// "no ad", so a missing value never falls back to another publisher.
library;

import 'package:flutter/foundation.dart';

const _forceTestAds = bool.fromEnvironment('USE_TEST_ADS');

class AdIds {
  AdIds._();

  static const publisher = 'ca-app-pub-5383120911029833';

  // iOS units from the AdMob account (set 2026-10-24).
  static const _iosBanner = 'ca-app-pub-5383120911029833/2331998253';
  static const _iosInterstitial = 'ca-app-pub-5383120911029833/5643935188';
  static const _iosNative = 'ca-app-pub-5383120911029833/6327083583';
  static const _iosAppOpen = 'ca-app-pub-5383120911029833/1968328332';

  // Google sample units: https://developers.google.com/admob/ios/test-ads
  static const _testBanner = 'ca-app-pub-3940256099942544/2435281174';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/4411468910';
  static const _testNative = 'ca-app-pub-3940256099942544/3986624511';
  static const _testAppOpen = 'ca-app-pub-3940256099942544/5575463023';

  static bool get useTestAds => kDebugMode || _forceTestAds;

  static String get banner => useTestAds ? _testBanner : _iosBanner;
  static String get interstitial => useTestAds ? _testInterstitial : _iosInterstitial;
  static String get native => useTestAds ? _testNative : _iosNative;
  static String get appOpen => useTestAds ? _testAppOpen : _iosAppOpen;
}
