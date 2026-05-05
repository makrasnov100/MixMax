import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:mix_max/services/firebase/auth_service.dart';
import 'package:mix_max/services/firebase/flutter_fire.dart';
import 'package:mix_max/services/general_info_service.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void initializeLateSingletons() async {
  if (getIt.isRegistered<AuthService>()) {
    return;
  }

  getIt.registerSingleton<AuthService>(AuthService());
  bool isComplete = await getIt<FlutterFire>().onInitDone.future;
  if (isComplete) {
    await getIt<GeneralInfoService>().syncCloudInfo();
  }

  // Enable crashlytics for non debug environments
  if (kDebugMode) {
    // Force disable Crashlytics collection while doing every day development.
    // Temporarily toggle this to true if you want to test crash reporting in your app.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
  } else {
    // Handle Crashlytics enabled status when not in Debug,
    // e.g. allow your users to opt-in to crash reporting.
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

    //Crashlytics setup
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }
}

void setupGetIt() {
  getIt.registerSingleton<FlutterFire>(FlutterFire());
  getIt.registerSingleton<GeneralInfoService>(GeneralInfoService());
}
