import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:blues_lab/core/router/app_route_paths.dart';

/// Placeholder for the future sign-in flow.
///
/// **TODO(auth):** Replace with a real screen wired to `SessionRepository` /
/// auth use cases. Keep this route path stable ([AppRoutePaths.login]) so
/// [appRouter] redirect logic does not need URL changes.
class LoginPlaceholderScreen extends StatelessWidget {
  const LoginPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign in'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Login (coming soon)',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Session-only backend and UI will plug in here. '
                  'Router redirect hooks are prepared in app_router.dart.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => context.go(AppRoutePaths.home),
                  child: const Text('Back to home (temporary)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
