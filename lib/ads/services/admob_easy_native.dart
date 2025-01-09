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

    Created by Muhammad Atif on 15/08/2024.
    Portfolio https://atifnoori.web.app.
    Islo-AI

 ********************************************************************************
 */

import 'package:admob_easy/admob_easy.dart';
import 'package:flutter/material.dart';

///  A widget that displays a native ad from AdMob.
class AdmobEasyNative extends StatefulWidget {
  /// The minimum width of the ad.
  final double minWidth;

  /// The minimum height of the ad.
  final double minHeight;

  /// The maximum width of the ad.
  final double maxWidth;

  /// The maximum height of the ad.
  final double maxHeight;

  /// Called when the ad is clicked.
  final void Function(Ad)? onAdClicked;

  /// Called when the ad is impression.
  final void Function(Ad)? onAdImpression;

  /// Called when the ad is closed.
  final void Function(Ad)? onAdClosed;

  /// Called when the ad is opened.
  final void Function(Ad)? onAdOpened;

  /// Called when the ad will dismiss the screen.
  final void Function(Ad)? onAdWillDismissScreen;

  /// Called when the ad receives a paid event.
  final void Function(Ad, double, PrecisionType, String)? onPaidEvent;

  final NativeTemplateStyle? templateType;

  /// A small template for the native ad.
  const AdmobEasyNative.smallTemplate({
    this.minWidth = 320,
    this.minHeight = 90,
    this.maxWidth = 400,
    this.maxHeight = 200,
    this.templateType,
    super.key,
    this.onAdClicked,
    this.onAdClosed,
    this.onAdImpression,
    this.onAdOpened,
    this.onAdWillDismissScreen,
    this.onPaidEvent,
  });

  /// A medium template for the native ad.
  const AdmobEasyNative.mediumTemplate({
    this.minWidth = 320,
    this.minHeight = 320,
    this.maxWidth = 400,
    this.maxHeight = 400,
    this.templateType,
    super.key,
    this.onAdClicked,
    this.onAdClosed,
    this.onAdImpression,
    this.onAdOpened,
    this.onAdWillDismissScreen,
    this.onPaidEvent,
  });

  @override
  State<AdmobEasyNative> createState() => _AdmobEasyNativeState();
}

class _AdmobEasyNativeState extends State<AdmobEasyNative> {
  final _nativeAd = ValueNotifier<NativeAd?>(null);
  final _nativeAdIsLoaded = ValueNotifier<bool>(false);

  /// Initializes the native ad.
  Future<void> _init() async {
    if (!AdmobEasy.instance.isConnected.value || AdmobEasy.instance.nativeAdID.isEmpty) {
      AdmobEasyLogger.error('Admob not connected or ad unit ID is empty');
      _nativeAdIsLoaded.value = false;
      return;
    }

    _loadAd();
  }

  /// Loads a native ad.
  void _loadAd() {
    final ad = NativeAd(
      adUnitId: AdmobEasy.instance.nativeAdID,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          AdmobEasyLogger.success('NativeAd loaded.');
          _nativeAd.value = ad as NativeAd;
          _nativeAdIsLoaded.value = true;
        },
        onAdFailedToLoad: (ad, error) {
          AdmobEasyLogger.error('NativeAd failedToLoad: $error');
          ad.dispose();
          _nativeAdIsLoaded.value = false;
        },
        onAdClicked: widget.onAdClicked,
        onAdImpression: widget.onAdImpression,
        onAdClosed: widget.onAdClosed,
        onAdOpened: widget.onAdOpened,
        onAdWillDismissScreen: widget.onAdWillDismissScreen,
        onPaidEvent: widget.onPaidEvent,
      ),
      request: const AdRequest(),
      nativeTemplateStyle: widget.templateType,
    );

    ad.load();
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _nativeAd.value?.dispose();
    _nativeAdIsLoaded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _nativeAdIsLoaded,
      builder: (context, isAdLoaded, child) {
        if (!isAdLoaded || _nativeAd.value == null) {
          return Container(
            width: widget.minWidth,
            height: widget.minHeight,
            color: Colors.white,
            alignment: Alignment.topLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color(0xFFE88F1A),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                child: Text(
                  'Ad',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ); // Return an empty widget if ad is not loaded
        }

        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: widget.minWidth,
            minHeight: widget.minHeight,
            maxWidth: widget.maxWidth,
            maxHeight: widget.maxHeight,
          ),
          child: AdWidget(
            ad: _nativeAd.value!,
            key: ValueKey(_nativeAd.value!.hashCode),
          ),
        );
      },
    );
  }
}
