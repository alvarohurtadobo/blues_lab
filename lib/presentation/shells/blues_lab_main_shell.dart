import 'package:flutter/material.dart';

import 'package:blues_lab/core/layout/responsive_breakpoints.dart';
import 'package:blues_lab/presentation/menu/legacy_main_menu.dart';
import 'package:blues_lab/presentation/widgets/blues_lab_collapsible_menu_sidebar.dart';

/// Main chrome: responsive drawer (compact) + collapsible legacy menu rail (wide).
///
/// [child] is the active [ShellRoute] branch (e.g. home). Routes outside the shell
/// (e.g. login) do not use this widget — see [appRouter] in `app_router.dart`.
class BluesLabMainShell extends StatefulWidget {
  const BluesLabMainShell({super.key, required this.child});

  final Widget child;

  @override
  State<BluesLabMainShell> createState() => _BluesLabMainShellState();
}

class _BluesLabMainShellState extends State<BluesLabMainShell> {
  bool _menuCollapsed = true;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useDrawer =
            ResponsiveBreakpoints.isCompact(constraints.maxWidth);
        final pagePad =
            ResponsiveBreakpoints.pageHorizontalPadding(constraints.maxWidth);

        return Scaffold(
          drawer: useDrawer ? _buildDrawer(context) : null,
          appBar: AppBar(
            automaticallyImplyLeading: useDrawer,
            title: const Text("Blue's Lab"),
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!useDrawer)
                BluesLabCollapsibleMenuSidebar(
                  collapsed: _menuCollapsed,
                  onToggleCollapsed: () =>
                      setState(() => _menuCollapsed = !_menuCollapsed),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pagePad),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: ResponsiveBreakpoints.contentMaxWidth,
                      ),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DrawerHeader(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.fromLTRB(20, 12, 16, 12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  kLegacyMenuTitle,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ),
            Expanded(
              child: LegacyMainMenuList(
                presentation: LegacyMainMenuPresentation.drawer,
                popDrawerOnTap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
