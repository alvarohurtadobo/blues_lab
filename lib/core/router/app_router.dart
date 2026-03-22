import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:blues_lab/core/router/app_route_paths.dart';
import 'package:blues_lab/presentation/screens/blues_lab_home_view.dart';
import 'package:blues_lab/presentation/screens/login_placeholder_screen.dart';
import 'package:blues_lab/presentation/screens/poma_tools_demo_screen.dart';
import 'package:blues_lab/presentation/shells/blues_lab_main_shell.dart';

/// Single [GoRouter] instance for the app (registered on [MaterialApp.router]).
///
/// **TODO(auth):** When a session layer exists (e.g. `SessionRepository` + Cubit):
/// 1. Add `refreshListenable` (e.g. `Listenable.merge([authCubit])`) so redirect
///    re-runs on login/logout.
/// 2. In [_globalRedirect], send unauthenticated users to [AppRoutePaths.login]
///    for protected routes (everything except `/login` and static assets).
/// 3. Send authenticated users away from `/login` to [AppRoutePaths.home].
/// 4. Optionally read tokens only from domain/use cases — keep redirect logic thin.
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutePaths.home,
  debugLogDiagnostics: kDebugMode,
  redirect: _globalRedirect,
  routes: [
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) {
        return BluesLabMainShell(child: child);
      },
      routes: [
        GoRoute(
          path: AppRoutePaths.home,
          name: AppRouteNames.home,
          pageBuilder: (BuildContext context, GoRouterState state) {
            return const NoTransitionPage<void>(child: BluesLabHomeView());
          },
        ),
      ],
    ),
    GoRoute(
      path: AppRoutePaths.pomaDemo,
      name: AppRouteNames.pomaDemo,
      builder: (BuildContext context, GoRouterState state) {
        return const PoMaHomePage();
      },
    ),
    GoRoute(
      path: AppRoutePaths.login,
      name: AppRouteNames.login,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return const MaterialPage<void>(child: LoginPlaceholderScreen());
      },
    ),
  ],
);

String? _globalRedirect(BuildContext context, GoRouterState state) {
  // TODO(auth): Replace with real session checks + refreshListenable on [GoRouter].
  //
  // Example (pseudocode):
  // final signedIn = context.read<AuthCubit>().state is Authenticated;
  // final loggingIn = state.matchedLocation == AppRoutePaths.login;
  // if (!signedIn && !loggingIn) return AppRoutePaths.login;
  // if (signedIn && loggingIn) return AppRoutePaths.home;
  return null;
}
