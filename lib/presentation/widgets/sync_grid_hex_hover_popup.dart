import 'package:flutter/material.dart';

import 'package:blues_lab/domain/value_objects/sync_grid_tile_style.dart';
import 'package:blues_lab/presentation/theme/sync_grid_tile_palette.dart';

/// Sync grid hover card styled like Pokémon Masters EX reference popups.
///
/// **Two layouts** (same as in-game screenshots):
/// - **Con descripción** (skills largos, etc.): título → caja interior más oscura con el
///   texto del efecto → pie "Energy / Orbs" en blanco negrita (sin pastilla).
/// - **Compacto** (stats, power +X sin texto largo): título → **pastilla** redondeada
///   con energía/orbes (como "Speed +5" o "Thunder Shock: Power +4").
///
/// El color del panel sigue el **tipo de casilla** (stat azul, passive amarillo,
/// sync morado, D-max rosa, powerup verde, learn cyan, etc.).
///
/// When [caretPointsUp] is true, the popup sits **below** the hex (caret apunta arriba).
/// When false, popup **above** the hex (caret apunta abajo).
class SyncGridHexHoverPopup extends StatelessWidget {
  const SyncGridHexHoverPopup({
    super.key,
    required this.title,
    required this.description,
    required this.energyOrbsLine,
    required this.styleClass,
    this.caretPointsUp = true,
  });

  final String title;
  final String description;
  final String energyOrbsLine;
  final SyncGridTileStyleClass styleClass;
  final bool caretPointsUp;

  static Color _panelColor(SyncGridTileStyleClass c) {
    final fill = SyncGridTilePalette.fill(c);
    if (c == SyncGridTileStyleClass.arc) {
      return Color.lerp(fill, const Color(0xFFC4A85A), 0.4)!
          .withValues(alpha: 0.96);
    }
    return fill.withValues(alpha: 0.94);
  }

  static Color _insetColor(SyncGridTileStyleClass c) {
    return Color.alphaBlend(
      Colors.black.withValues(alpha: 0.28),
      SyncGridTilePalette.dark(c),
    ).withValues(alpha: 0.92);
  }

  static Color _pillColor(SyncGridTileStyleClass c) {
    return Color.alphaBlend(
      Colors.black.withValues(alpha: 0.22),
      SyncGridTilePalette.dark(c),
    ).withValues(alpha: 0.94);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasDesc = description.trim().isNotEmpty;
    final panel = _panelColor(styleClass);
    final inset = _insetColor(styleClass);
    final pillBg = _pillColor(styleClass);

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          height: 1.2,
          fontSize: 13,
          shadows: const [
            Shadow(blurRadius: 2, color: Color(0x66000000), offset: Offset(0, 1)),
          ],
        ) ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 13,
          height: 1.2,
          shadows: [
            Shadow(blurRadius: 2, color: Color(0x66000000), offset: Offset(0, 1)),
          ],
        );

    final card = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 288),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.28),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, textAlign: TextAlign.center, style: titleStyle),
              if (hasDesc) ...[
                const SizedBox(height: 10),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: inset,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Text(
                      description,
                      textAlign: TextAlign.start,
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.96),
                            height: 1.35,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ) ??
                          TextStyle(
                            color: Colors.white.withValues(alpha: 0.96),
                            height: 1.35,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  energyOrbsLine,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ) ??
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                Center(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: pillBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        energyOrbsLine,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ) ??
                            TextStyle(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                              height: 1.2,
                            ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final caret = CustomPaint(
      size: const Size(18, 9),
      painter: _CaretTrianglePainter(color: panel, pointsUp: true),
    );
    final caretDown = CustomPaint(
      size: const Size(18, 9),
      painter: _CaretTrianglePainter(color: panel, pointsUp: false),
    );

    if (caretPointsUp) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [caret, card],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [card, caretDown],
    );
  }
}

class _CaretTrianglePainter extends CustomPainter {
  const _CaretTrianglePainter({required this.color, required this.pointsUp});

  final Color color;
  final bool pointsUp;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (pointsUp) {
      path
        ..moveTo(0, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width / 2, 0)
        ..close();
    } else {
      path
        ..moveTo(0, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width / 2, size.height)
        ..close();
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CaretTrianglePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointsUp != pointsUp;
}
