import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
// import 'package:mix_max/flavors/dev/firebase_options.dart' as dev;
import 'package:mix_max/flavors/prod/firebase_options.dart' as prod;

class FlutterFire {
  Completer<bool> onInitDone = Completer<bool>();
  bool initialized = false;
  String? lastError;

  Future<void> initializeFlutterFire() async {
    if (initialized && lastError != null) {
      return;
    }

    initialized = false;
    lastError = null;

    try {
      //bool inProduction = appFlavor != "dev";
      //FirebaseOptions options = inProduction ? prod.DefaultFirebaseOptions.currentPlatform : dev.DefaultFirebaseOptions.currentPlatform;
      await Firebase.initializeApp(options: prod.DefaultFirebaseOptions.currentPlatform);

      // Activate App Check after init but before any Firebase service is used.
      await _activateAppCheck();

      initialized = true;
      print("FLutter Fire Initialized!");
    } catch (e) {
      print("Flutter Fire Failed to Initialize!");
      lastError = e.toString();
    } finally {
      onInitDone.complete(initialized);
    }
  }

  Future<void> _activateAppCheck() async {
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
            kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
        appleProvider:
            kDebugMode ? AppleProvider.debug : AppleProvider.appAttest,
      );
      await FirebaseAppCheck.instance.setTokenAutoRefreshEnabled(true);
      await FirebaseAppCheck.instance
          .getToken()
          .timeout(const Duration(seconds: 3));

      print("App Check activated!");
    } catch (e) {
      // App Check failure must not block sign-in or the user document read.
      print("App Check activation failed (continuing without it): $e");
    }
  }

  bool isInitialized() {
    return initialized;
  }
}
