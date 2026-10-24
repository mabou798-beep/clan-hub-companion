/// Google Mobile Ads, per the standing ad plan:
/// - anchored adaptive banner above the tab bar, always;
/// - interstitial only at the end of a quiz round, >= 3 min apart, max 3 per
///   session;
/// - App Open ad on every return to foreground after the cold start;
/// - native tiles inside long lists, labelled "Sponsored".
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../theme.dart';
import 'ad_ids.dart';

class Ads {
  Ads._();

  static final ready = ValueNotifier<bool>(false);
  static bool _fullScreenShowing = false;

  static Future<void> init() async {
    if (ready.value) return;
    await MobileAds.instance.initialize();
    ready.value = true;
    _Interstitials.preload();
    _AppOpen.start();
  }

  /// Natural break: the player just finished a quiz round.
  static void onQuizRoundEnd() => _Interstitials.maybeShow();
}

class _Interstitials {
  static const _minGap = Duration(minutes: 3);
  static const _maxPerSession = 3;
  static InterstitialAd? _ad;
  static DateTime? _lastShown;
  static int _shown = 0;
  static bool _loading = false;

  static void preload() {
    if (_ad != null || _loading || _shown >= _maxPerSession) return;
    if (AdIds.interstitial.isEmpty) return;
    _loading = true;
    InterstitialAd.load(
      adUnitId: AdIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loading = false;
        },
        onAdFailedToLoad: (_) => _loading = false,
      ),
    );
  }

  static void maybeShow() {
    final ad = _ad;
    final now = DateTime.now();
    final last = _lastShown;
    if (ad == null || _shown >= _maxPerSession) return;
    if (last != null && now.difference(last) < _minGap) return;
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => Ads._fullScreenShowing = true,
      onAdDismissedFullScreenContent: (a) {
        Ads._fullScreenShowing = false;
        _AppOpen.suppressNextResume();
        a.dispose();
        preload();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        Ads._fullScreenShowing = false;
        a.dispose();
        preload();
      },
    );
    _shown++;
    _lastShown = now;
    ad.show();
  }
}

class _AppOpen {
  static const _maxAge = Duration(hours: 4);
  static AppOpenAd? _ad;
  static DateTime? _loadedAt;
  static bool _loading = false;
  static bool _suppress = false;
  static StreamSubscription<AppState>? _sub;

  static void start() {
    if (AdIds.appOpen.isEmpty) return;
    _load();
    AppStateEventNotifier.startListening();
    _sub ??= AppStateEventNotifier.appStateStream.listen((s) {
      if (s == AppState.foreground) _onForeground();
    });
  }

  /// Returning from our own interstitial is not a "return to the app".
  static void suppressNextResume() => _suppress = true;

  static void _load() {
    if (_loading || _ad != null) return;
    _loading = true;
    AppOpenAd.load(
      adUnitId: AdIds.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          _loading = false;
        },
        onAdFailedToLoad: (_) => _loading = false,
      ),
    );
  }

  static void _onForeground() {
    if (_suppress) {
      _suppress = false;
      return;
    }
    final ad = _ad;
    if (ad == null || Ads._fullScreenShowing) {
      _load();
      return;
    }
    if (DateTime.now().difference(_loadedAt!) > _maxAge) {
      ad.dispose();
      _ad = null;
      _load();
      return;
    }
    _ad = null;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) => Ads._fullScreenShowing = true,
      onAdDismissedFullScreenContent: (a) {
        Ads._fullScreenShowing = false;
        a.dispose();
        _load();
      },
      onAdFailedToShowFullScreenContent: (a, _) {
        Ads._fullScreenShowing = false;
        a.dispose();
        _load();
      },
    );
    ad.show();
  }
}

/// Anchored adaptive banner. Reserves no space until an ad has loaded.
class AnchoredBanner extends StatefulWidget {
  const AnchoredBanner({super.key});

  @override
  State<AnchoredBanner> createState() => _AnchoredBannerState();
}

class _AnchoredBannerState extends State<AnchoredBanner> {
  BannerAd? _ad;
  bool _loaded = false;
  int? _width;

  @override
  void initState() {
    super.initState();
    Ads.ready.addListener(_maybeLoad);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeLoad();
  }

  Future<void> _maybeLoad() async {
    if (!mounted || !Ads.ready.value || AdIds.banner.isEmpty) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    if (_width == width && _ad != null) return;
    _width = width;
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    if (size == null || !mounted) return;
    _ad?.dispose();
    _loaded = false;
    _ad = BannerAd(
      adUnitId: AdIds.banner,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    Ads.ready.removeListener(_maybeLoad);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return ColoredBox(
      color: Palette.night,
      child: SafeArea(
        top: false,
        bottom: false,
        child: SizedBox(
          width: ad.size.width.toDouble(),
          height: ad.size.height.toDouble(),
          child: AdWidget(ad: ad),
        ),
      ),
    );
  }
}

/// Native ad rendered with the SDK's template, under a visible label.
/// Collapses to nothing when no ad is available.
class NativeAdTile extends StatefulWidget {
  const NativeAdTile({super.key});

  @override
  State<NativeAdTile> createState() => _NativeAdTileState();
}

class _NativeAdTileState extends State<NativeAdTile> {
  NativeAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    Ads.ready.addListener(_load);
    _load();
  }

  void _load() {
    if (!Ads.ready.value || _ad != null || AdIds.native.isEmpty) return;
    _ad = NativeAd(
      adUnitId: AdIds.native,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (_) => mounted ? setState(() => _loaded = true) : null,
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Palette.stone,
        cornerRadius: 14,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Palette.night,
          backgroundColor: Palette.gold,
          style: NativeTemplateFontStyle.bold,
          size: 14,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Palette.ink,
          style: NativeTemplateFontStyle.bold,
          size: 15,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Palette.inkSoft,
          size: 13,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Palette.inkFaint,
          size: 12,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    Ads.ready.removeListener(_load);
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null || !_loaded) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              'Sponsored',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Palette.inkFaint),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 90, maxHeight: 120),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AdWidget(ad: ad),
            ),
          ),
        ],
      ),
    );
  }
}
