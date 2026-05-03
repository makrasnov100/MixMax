import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';

//Grabs information that remains static throughout an app session when flutter fire has been initialized
class GeneralInfoService with ChangeNotifier {
  // [State]
  bool isLoading = true;

  // [App]
  bool inProduction = appFlavor != "dev";
  String appVersion = "9.9.9";

  // [Social]
  late String appSuffix;
  late String contactEmail;
  late String privacyPolicy;
  late String termsOfService;
  late String appWebsiteUrl;

  GeneralInfoService() {
    appSuffix = "template-flutter-app";
    contactEmail = "support+$appSuffix@myfortuna.app";
    privacyPolicy = "https://myfortuna.app/privacy-policy/$appSuffix/";
    termsOfService = "https://myfortuna.app/terms-of-service/$appSuffix/";
    appWebsiteUrl = "https://myfortuna.app/$appSuffix";
  }

  Future<void> syncCloudInfo() async {
    // - get app information version
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      appVersion = packageInfo.version;
    } catch (e) {
      print(e);
    }

    // - replace default data with cloud info
    try {
      final appDocSnapshot = await FirebaseFirestore.instance.collection("General").doc("app").get();
      if (!appDocSnapshot.exists) {
        throw Exception("App information not found in cloud firestore");
      }

      final appData = appDocSnapshot.data();
      contactEmail = appData?["social"]?["contactEmail"] ?? contactEmail;
      privacyPolicy = appData?["social"]?["privacyPolicy"] ?? privacyPolicy;
      termsOfService = appData?["social"]?["termsOfService"] ?? termsOfService;
    } catch (e) {
      print(e);
    } finally {
      isLoading = false;
    }

    notifyListeners();

    // DEBUG: Print all collected values
    // print("General Info Service: ");
    // print("  inProduction: $inProduction");
    // print("  contactEmail: $contactEmail");
    // print("  privacyPolicy: $privacyPolicy");
    // print("  termsOfService: $termsOfService");
  }

  String getBundleID() {
    if (Platform.isIOS) {
      return "app.myfortuna.mixMax";
    } else {
      return "app.myfortuna.mix_max";
    }
  }
}
