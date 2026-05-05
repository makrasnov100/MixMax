import 'package:flutter/material.dart';
import 'package:mix_max/services/ui/navigation_service.dart';

class AppNavigatorObserver<R extends Route<dynamic>> extends RouteObserver<R> {
  AppNavigatorObserver();

  Destination? getRouteDestination(Route? route, {bool isPop = false}) {
    //If the route is unnamed return a null destination
    String? routeName = route?.settings.name;
    if (routeName == null) {
      return null;
    }

    Destination destination = Destination.experimentsList;
    if (routeName == "/" || routeName == "experimentsList") {
      destination = Destination.experimentsList;
    } else {
      destination = Destination.values.firstWhere(
        (e) => e.name == routeName,
        orElse: () {
          return Destination.experimentsList;
        },
      );
    }

    return destination;
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    // Destination? pushDestinationPrev = getRouteDestination(oldRoute);
    Destination? pushDestination = getRouteDestination(route);

    if (pushDestination == null) {
      //print("MODAL PUSHED");
    }

    if (pushDestination != null) {
      Navigation.onRouteChange(destination: pushDestination);
    }

    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    Destination? popDestination = getRouteDestination(previousRoute);
    Destination? popDestinationPrev = getRouteDestination(route, isPop: true);

    if (popDestination != null) {
      Navigation.onRouteChange(destination: popDestination);
    }
    if (popDestinationPrev == null) {
      //print("MODAL POPPED");
    }

    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    // Destination? replaceDestinationPrev = getRouteDestination(oldRoute);
    Destination? replaceDestination = getRouteDestination(newRoute);

    if (replaceDestination != null) {
      Navigation.onRouteChange(destination: replaceDestination);
    }

    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
