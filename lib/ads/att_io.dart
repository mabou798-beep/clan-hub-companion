/// Shows the iOS tracking prompt once, when it has not been answered yet.
library;

import 'dart:io';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';

Future<void> requestTrackingIfNeeded() async {
  if (!Platform.isIOS) return;
  try {
    final status = await AppTrackingTransparency.trackingAuthorizationStatus;
    if (status == TrackingStatus.notDetermined) {
      await AppTrackingTransparency.requestTrackingAuthorization();
    }
  } catch (_) {
    // The prompt is best effort; ads still work non-personalised.
  }
}
