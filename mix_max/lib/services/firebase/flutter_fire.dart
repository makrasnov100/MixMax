import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
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

      initialized = true;
      print("FLutter Fire Initialized!");
    } catch (e) {
      print("Flutter Fire Failed to Initialize!");
      lastError = e.toString();
    } finally {
      onInitDone.complete(initialized);
    }
  }

  bool isInitialized() {
    return initialized;
  }
}
