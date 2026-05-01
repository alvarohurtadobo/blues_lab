import 'package:flutter/material.dart';

import 'package:blues_lab/presentation/menu/legacy_main_menu.dart';

/// Desktop / wide layout: persistent legacy menu with a minimizable (collapsed) mode.
class BluesLabCollapsibleMenuSidebar extends StatelessWidget {
  const BluesLabCollapsibleMenuSidebar({
    super.key,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  static const double expandedWidth = 268;
  static const double collapsedWidth = 80;

  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final width = collapsed ? collapsedWidth : expandedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.65),
        border: Border(
          right: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: collapsed
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 52,
              child: collapsed
                  ? IconButton(
                      tooltip: 'Expand menu',
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: onToggleCollapsed,
                    )
                  : Row(
                      children: [
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            kLegacyMenuTitle,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Collapse menu',
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: onToggleCollapsed,
                        ),
                      ],
                    ),
            ),
            Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
            Expanded(
              child: LegacyMainMenuList(
                presentation: collapsed
                    ? LegacyMainMenuPresentation.sidebarCollapsed
                    : LegacyMainMenuPresentation.sidebarExpanded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
