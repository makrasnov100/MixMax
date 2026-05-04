import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:mix_max/pages/experiments_list_page.dart';
import 'package:mix_max/services/app_navigator_observer.dart';
import 'package:mix_max/services/globals.dart';
import 'package:mix_max/services/ui/app_colors.dart';
import 'package:mix_max/services/firebase/flutter_fire.dart';
import 'package:mix_max/services/get_it.dart';
import 'package:mix_max/services/ui/navigation_service.dart';
import 'package:mix_max/services/ui/size_config.dart';

AppNavigatorObserver<PageRoute> navigatorObserver = AppNavigatorObserver<PageRoute>();

void main() async {
  runZonedGuarded<Future<void>>(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      setupGetIt();

      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeRight,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      await getIt<FlutterFire>().initializeFlutterFire();
      await getIt<FlutterFire>().onInitDone.future;
      initializeLateSingletons();

      FlutterNativeSplash.remove();

      runApp(const MyApp());
    },
    (error, stack) {
      print("Error: $error");
      if (getIt<FlutterFire>().isInitialized()) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }
    },
  );
}

class MyApp extends StatelessWidget {
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver analyticsObserver = FirebaseAnalyticsObserver(analytics: analytics);

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: snackbarKey,
      theme: ThemeData(
        primarySwatch: AppColors.primary,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: false,
      ),
      home: const ExperimentsListPage(),
      navigatorKey: Navigation.navigatorKey,
      navigatorObservers: [navigatorObserver, analyticsObserver],
    );
  }
}
