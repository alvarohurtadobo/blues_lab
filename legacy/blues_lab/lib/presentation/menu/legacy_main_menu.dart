import 'package:flutter/material.dart';

/// One entry from PoMaTools `MSGS.MENU` in [assets/i18n/en.json] (legacy web app).
final class LegacyMainMenuItem {
  const LegacyMainMenuItem({
    required this.jsonKey,
    required this.title,
    required this.icon,
  });

  final String jsonKey;
  final String title;
  final IconData icon;
}

/// English labels matching the legacy export (`MSGS.MENU`).
const List<LegacyMainMenuItem> kLegacyMainMenuItems = [
  LegacyMainMenuItem(
    jsonKey: 'GRIDS',
    title: 'Sync Grids',
    icon: Icons.grid_view_rounded,
  ),
  LegacyMainMenuItem(
    jsonKey: 'EGGS',
    title: 'Egg Pokémon',
    icon: Icons.egg_outlined,
  ),
  LegacyMainMenuItem(
    jsonKey: 'TEAM',
    title: 'Team Builder',
    icon: Icons.groups_outlined,
  ),
  LegacyMainMenuItem(
    jsonKey: 'HELP',
    title: 'Information and help',
    icon: Icons.help_outline_rounded,
  ),
  LegacyMainMenuItem(
    jsonKey: 'FINDER',
    title: 'Move / Skill finder',
    icon: Icons.manage_search_rounded,
  ),
];

/// `MSGS.TITLES.MENU` — drawer / rail header label.
const String kLegacyMenuTitle = 'Menu';

enum LegacyMainMenuPresentation {
  /// Modal drawer (typically mobile).
  drawer,

  /// Persistent rail with icons + titles (desktop / tablet wide).
  sidebarExpanded,

  /// Minimized rail: icons + tooltips only.
  sidebarCollapsed,
}

/// Visual-only menu (no routes). [onItemPressed] is optional analytics hook later.
class LegacyMainMenuList extends StatelessWidget {
  const LegacyMainMenuList({
    super.key,
    required this.presentation,
    this.popDrawerOnTap = false,
    this.onItemPressed,
  });

  final LegacyMainMenuPresentation presentation;

  final bool popDrawerOnTap;

  final void Function(LegacyMainMenuItem item)? onItemPressed;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: kLegacyMainMenuItems.length,
      itemBuilder: (context, index) => _tile(context, kLegacyMainMenuItems[index]),
    );
  }

  Widget _tile(BuildContext context, LegacyMainMenuItem item) {
    void handle() {
      if (popDrawerOnTap) {
        Navigator.maybePop(context);
      }
      onItemPressed?.call(item);
    }

    if (presentation == LegacyMainMenuPresentation.sidebarCollapsed) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: IconButton(
          icon: Icon(item.icon),
          tooltip: item.title,
          onPressed: handle,
        ),
      );
    }

    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      dense: presentation == LegacyMainMenuPresentation.drawer,
      onTap: handle,
    );
  }
}
