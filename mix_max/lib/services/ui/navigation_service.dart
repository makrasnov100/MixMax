import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mix_max/pages/experiment_details_page.dart';
import 'package:mix_max/pages/experiments_list_page.dart';
import 'package:mix_max/pages/run_iteration_page.dart';

enum DrawerType { block, confirm }

enum Destination { experimentsList, experimentDetails, runIteration, unknown }

enum PageMoveType { push, replace }

class Navigation {
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Destination? lastDestination;
  static StreamController<Destination> changedAppDestination = StreamController<Destination>();

  static Future<dynamic> goTo({
    required BuildContext context,
    required Widget page,
    PageMoveType type = PageMoveType.push,
  }) async {
    Destination destination = Destination.unknown;
    if (page is ExperimentsListPage) {
      destination = Destination.experimentsList;
    } else if (page is ExperimentDetailsPage) {
      destination = Destination.experimentDetails;
    } else if (page is RunIterationPage) {
      destination = Destination.runIteration;
    }

    if (destination == Destination.unknown) {
      throw Exception("Unknown destination");
    }

    MaterialPageRoute route = MaterialPageRoute(
      settings: RouteSettings(name: destination.name),
      builder: (context) => page,
    );

    switch (type) {
      case PageMoveType.push:
        return Navigator.of(navigatorKey.currentContext!).push(route);
      case PageMoveType.replace:
        return Navigator.of(navigatorKey.currentContext!).pushReplacement(route);
    }
  }

  static void startOver({Widget? startPage}) {
    if (navigatorKey.currentState == null) {
      return;
    }

    Navigator.of(navigatorKey.currentContext!).popUntil((route) => route.isFirst);

    if (startPage != null) {
      goTo(context: navigatorKey.currentContext!, page: startPage, type: PageMoveType.replace);
    }
  }

  static void onRouteChange({required Destination destination}) {
    changedAppDestination.add(destination);
    lastDestination = destination;
  }
}
