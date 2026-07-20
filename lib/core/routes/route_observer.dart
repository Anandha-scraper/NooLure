import 'package:flutter/material.dart';

/// Lets a screen know when it becomes visible again after a route pushed on
/// top of it (e.g. an edit screen) is popped — used to clear any "armed"
/// swipe-confirm state so a card left mid-swipe doesn't still show its
/// confirm UI when the user navigates back to it.
final RouteObserver<PageRoute<void>> appRouteObserver =
    RouteObserver<PageRoute<void>>();
