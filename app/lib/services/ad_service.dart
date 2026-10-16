import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static const String appId = 'ca-app-pub-6560293652268094~7276146281';

  // Production Ad Unit IDs
  static const String _prodBannerId = 'ca-app-pub-6560293652268094/8237874162';
  static const String _prodInterstitialId = 'ca-app-pub-6560293652268094/4056095737';

  // Google Test IDs (safe for debug / test builds so AdMob accounts aren't flagged during testing)
  static const String _testBannerId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _testInterstitialId = 'ca-app-pub-3940256099942544/1033173712';

  static String get bannerAdUnitId {
    if (!Platform.isAndroid) return '';
    return kReleaseMode ? _prodBannerId : _testBannerId;
  }

  static String get interstitialAdUnitId {
    if (!Platform.isAndroid) return '';
    return kReleaseMode ? _prodInterstitialId : _testInterstitialId;
  }

  static bool _initialized = false;
  static InterstitialAd? _interstitialAd;
  static bool _isInterstitialLoading = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      loadInterstitialAd();
    } catch (e) {
      debugPrint('AdService initialize error: $e');
    }
  }

  static void loadInterstitialAd() {
    if (!Platform.isAndroid || _isInterstitialLoading || _interstitialAd != null) return;
    _isInterstitialLoading = true;

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoading = false;
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _interstitialAd = null;
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('InterstitialAd failed to load: $error');
          _interstitialAd = null;
          _isInterstitialLoading = false;
        },
      ),
    );
  }

  static void showInterstitialAd({VoidCallback? onComplete}) {
    if (_interstitialAd != null) {
      _interstitialAd!.show();
      onComplete?.call();
    } else {
      loadInterstitialAd();
      onComplete?.call();
    }
  }
}

class LunaBannerAdWidget extends StatefulWidget {
  const LunaBannerAdWidget({super.key});

  @override
  State<LunaBannerAdWidget> createState() => _LunaBannerAdWidgetState();
}

class _LunaBannerAdWidgetState extends State<LunaBannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  void _loadBanner() {
    if (!Platform.isAndroid) return;
    _bannerAd = BannerAd(
      adUnitId: AdService.bannerAdUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isLoaded = false;
            });
          }
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }
    return Container(
      alignment: Alignment.center,
      width: _bannerAd!.size.width.toDouble(),
      height: _bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}
