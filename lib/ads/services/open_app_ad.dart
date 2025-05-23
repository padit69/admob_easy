/*
 ********************************************************************************

    _____/\\\\\\\\\_____/\\\\\\\\\\\\\\\__/\\\\\\\\\\\__/\\\\\\\\\\\\\\\_
    ___/\\\\\\\\\\\\\__\///////\\\/////__\/////\\\///__\/\\\///////////__
    __/\\\/////////\\\_______\/\\\___________\/\\\_____\/\\\_____________
    _\/\\\_______\/\\\_______\/\\\___________\/\\\_____\/\\\\\\\\\\\_____
    _\/\\\\\\\\\\\\\\\_______\/\\\___________\/\\\_____\/\\\///////______
    _\/\\\/////////\\\_______\/\\\___________\/\\\_____\/\\\_____________
    _\/\\\_______\/\\\_______\/\\\___________\/\\\_____\/\\\_____________
    _\/\\\_______\/\\\_______\/\\\________/\\\\\\\\\\\_\/\\\_____________
    _\///________\///________\///________\///////////__\///______________

    Created by Muhammad Atif on 04/01/2024 : 10:14 pm.
    Portfolio https://atifnoori.web.app.
    +923085690603

 ********************************************************************************
 */

import 'package:admob_easy/ads/admob_easy.dart';
import 'package:admob_easy/ads/sources.dart';
import 'package:admob_easy/ads/utils/admob_easy_logger.dart';

/**
 *  create instance of AppLifecycleReactor in first screen
    late AppLifecycleReactor _appLifecycleReactor;

 * add these line in first screen in [initState]
    OpenAppAd.instance..loadOpenAppAd();
    // Create and listen to app lifecycle changes
    _appLifecycleReactor = AppLifecycleReactor();
    _appLifecycleReactor.listenToAppStateChanges();
 * */

/// Start the [OpenAppAd] class

mixin OpenAppAd {
  /// App open ads area
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  int _numAppOpenAdLoadAttempts = 0;

  /// <------------------------ Load AppOpenAd with Exponential Backoff ------------------------>
  void loadAppOpenAd({int maxLoadAttempts = 5, int attemptDelayFactorMs = 500, String? adId}) {
    final instance = AdmobEasy.instance;
    final appOpenAdID = adId ?? instance.appOpenAdID;
    if (appOpenAdID.isEmpty || _isShowingAd) return;

    // Dispose existing ad if present
    if (_appOpenAd != null) {
      _appOpenAd!.dispose();
      _appOpenAd = null;
    }

    AppOpenAd.load(
      adUnitId: appOpenAdID,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _numAppOpenAdLoadAttempts = 0; // Reset attempt counter
          AdmobEasyLogger.success('App open ad loaded');
        },
        onAdFailedToLoad: (error) async {
          AdmobEasyLogger.error('AppOpenAd failed to load: $error');
          _appOpenAd = null;
          _numAppOpenAdLoadAttempts += 1;

          // Retry with exponential backoff if attempts are less than maxLoadAttempts
          if (_numAppOpenAdLoadAttempts < maxLoadAttempts) {
            int delayMs = attemptDelayFactorMs * _numAppOpenAdLoadAttempts;
            await Future.delayed(Duration(milliseconds: delayMs));
            loadAppOpenAd(
              maxLoadAttempts: maxLoadAttempts,
              attemptDelayFactorMs: attemptDelayFactorMs,
              adId: adId,
            ); // Retry loading the app open ad
          } else {
            _numAppOpenAdLoadAttempts = 0; // Reset after reaching max attempts
          }
        },
      ),
    );
  }

  /// <------------------------ Show AppOpenAd ------------------------>
  void showOpenAppAd({
    void Function(OpenAppAd)? onAdDismissedFullScreenContent,
    void Function(OpenAppAd)? onAdFailedToShowFullScreenContent,
  }) {
    if (_appOpenAd == null || _isShowingAd) {
      loadAppOpenAd(); // Load an ad if none is available or already showing
      return;
    }
    _isShowingAd = true;

    // Set the fullScreenContentCallback to handle ad events
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        AdmobEasyLogger.info('$ad onAdShowedFullScreenContent');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        AdmobEasyLogger.error('$ad failed to show full screen content: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd(); // Load a new ad after failure
        onAdFailedToShowFullScreenContent?.call(ad);
      },
      onAdDismissedFullScreenContent: (ad) {
        AdmobEasyLogger.info('$ad dismissed');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        loadAppOpenAd(); // Preload a new ad after dismissal
        onAdDismissedFullScreenContent?.call(ad);
      },
    );

    // Show the app open ad
    _appOpenAd!.show();
  }
}

/// Listens for app foreground events and shows app open ads.
class AppLifecycleReactor {
  final admobEasy = AdmobEasy.instance; // Mixin instance

  AppLifecycleReactor();

  /// <------------------------ Start Listening for App State Changes ------------------------>
  void openAppAdListener() {
    AppStateEventNotifier.startListening();
    AppStateEventNotifier.appStateStream.forEach((state) => _onAppStateChanged(state));
  }

  /// <------------------------ Handle App State Changes ------------------------>
  void _onAppStateChanged(AppState appState) {
    if (appState == AppState.foreground) {
      AdmobEasyLogger.info('App moved to foreground');
      admobEasy.showOpenAppAd();
    }
  }
}
