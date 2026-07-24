import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../core/routes/app_routes.dart';
import '../core/theme/text_styles.dart';
import 'app_drawer.dart';

/// One Scaffold for every screen, so navigation affordances and screen-title
/// typography stop varying per file.
///
/// The important part is the leading widget. Section screens used to be
/// reached with `pushReplacementNamed`, which destroyed the root route (the
/// AuthGate wrapping Home) and left a single-route stack with no AppBar — so
/// no back button, no hamburger, and Android back quit the app. Sections are
/// now *pushed* on top of Home, which means a plain `pop()` always lands back
/// on Home and the system back gesture does the right thing for free.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.drawerRoute,
    this.showBack = true,
    this.actions,
    this.floatingActionButton,
    this.titleStyle,
    this.centerTitle = false,
    this.bottomBar,
  });

  /// A section screen (Tasks, Notes, …) passes its own route here to get the
  /// drawer with the right item highlighted. Detail screens pass null.
  final String? drawerRoute;

  final String title;
  final Widget body;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final TextStyle? titleStyle;
  final bool centerTitle;

  /// Optional footer, e.g. the notes editor's undo/redo bar. Forwarded
  /// straight to [Scaffold.bottomNavigationBar]; left null everywhere else.
  final Widget? bottomBar;

  bool get _isHome => drawerRoute == AppRoutes.home;

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      drawer: drawerRoute == null
          ? null
          : AppDrawer(currentRoute: drawerRoute!),
      appBar: AppBar(
        centerTitle: centerTitle,
        titleSpacing: 0,
        title: Text(
          title,
          style: titleStyle ?? TextStyles.h4(color: onSurface),
        ),
        leading: _leading(context),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomBar,
      body: SafeArea(top: false, child: body),
    );
  }

  Widget? _leading(BuildContext context) {
    // Home is the root: it opens the drawer instead of going back.
    if (_isHome) {
      return Builder(
        builder: (context) => IconButton(
          icon: const Icon(LucideIcons.menu),
          tooltip: 'Menu',
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      );
    }
    if (!showBack) return null;

    return IconButton(
      icon: const Icon(LucideIcons.chevronLeft),
      tooltip: 'Back',
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}

/// Jump to a top-level section, keeping Home as the one route underneath.
///
/// Called from the drawer. Popping back to the root first means the stack
/// never grows past `[Home, section]` no matter how many times the user
/// hops between sections, and Home is always what Back returns to.
void goToSection(BuildContext context, String route) {
  final navigator = Navigator.of(context);
  navigator.popUntil((r) => r.isFirst);
  if (route != AppRoutes.home) navigator.pushNamed(route);
}
