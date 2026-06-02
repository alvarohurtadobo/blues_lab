import 'package:flutter/material.dart';

import '../constants/type_data.dart' as consts;

class MoveCard extends StatefulWidget {
  const MoveCard({
    super.key,
    required this.moveName,
    required this.typeColor,
    this.typeChip,
    required this.powerBonus,
    required this.accBonus,
    required this.basePower,
    this.moveCategory = '',
    this.moveType = '',
    this.moveAccuracy = '',
    this.moveGauge = '',
    this.moveTarget = '',
    this.moveDescription = '',
    this.isSync = false,
    this.teraBoost = false,
    this.syncTechBoost = false,
  });

  final String moveName;
  final Color typeColor;
  final Widget? typeChip;
  final int powerBonus;
  final int accBonus;
  final String basePower;
  final String moveCategory;
  final String moveType;
  final String moveAccuracy;
  final String moveGauge;
  final String moveTarget;
  final String moveDescription;
  final bool isSync;
  final bool teraBoost;
  final bool syncTechBoost;

  @override
  State<MoveCard> createState() => _MoveCardState();
}

class _MoveCardState extends State<MoveCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final hasDesc = widget.moveDescription.isNotEmpty;
    final basePowerNum = int.tryParse(widget.basePower);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: widget.moveType.isNotEmpty
            ? widget.typeColor.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.moveType.isNotEmpty
              ? widget.typeColor.withValues(alpha: 0.5)
              : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: hasDesc ? () => setState(() => _expanded = !_expanded) : null,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.isSync)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.star,
                        size: 14,
                        color: Colors.purple.shade300,
                      ),
                    ),
                  Expanded(
                    child: Text(
                      widget.moveName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (hasDesc)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        _expanded ? Icons.expand_less : Icons.expand_more,
                        size: 18,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  if (widget.typeChip != null) widget.typeChip!,
                ],
              ),
              if (_expanded && hasDesc)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    widget.moveDescription,
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              if (widget.basePower.isNotEmpty ||
                  widget.moveAccuracy.isNotEmpty ||
                  widget.moveGauge.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Wrap(
                    spacing: 12,
                    children: [
                      if (widget.basePower.isNotEmpty &&
                          widget.basePower != '--')
                        Builder(
                          builder: (_) {
                            final base = basePowerNum ?? 0;
                            final syncTechBase = widget.syncTechBoost
                                ? (base * 1.5).floor()
                                : base;
                            final teraBase = widget.teraBoost
                                ? (syncTechBase * 1.5).floor()
                                : syncTechBase;
                            final finalPower = teraBase + widget.powerBonus;
                            String label;
                            if (widget.teraBoost &&
                                widget.powerBonus > 0 &&
                                basePowerNum != null) {
                              label =
                                  '⚔ ${widget.basePower} × 1.5 = $teraBase + ${widget.powerBonus} = $finalPower';
                            } else if (widget.teraBoost &&
                                basePowerNum != null) {
                              label = '⚔ ${widget.basePower} × 1.5 = $teraBase';
                            } else if (widget.syncTechBoost &&
                                widget.powerBonus > 0 &&
                                basePowerNum != null) {
                              label =
                                  '⚔ ${widget.basePower} × 1.5 = $syncTechBase + ${widget.powerBonus} = $finalPower';
                            } else if (widget.syncTechBoost &&
                                basePowerNum != null) {
                              label =
                                  '⚔ ${widget.basePower} × 1.5 = $syncTechBase';
                            } else if (widget.powerBonus > 0 &&
                                basePowerNum != null) {
                              label =
                                  '⚔ ${widget.basePower} + ${widget.powerBonus} = $finalPower';
                            } else {
                              label = '⚔ ${widget.basePower}';
                            }
                            return Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    (widget.powerBonus > 0 || widget.teraBoost)
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                      if (widget.moveAccuracy.isNotEmpty &&
                          widget.moveAccuracy != '--')
                        Builder(
                          builder: (_) {
                            final baseAcc = int.tryParse(widget.moveAccuracy);
                            return Text(
                              widget.accBonus > 0 && baseAcc != null
                                  ? '🎯 ${widget.moveAccuracy} + ${widget.accBonus} = ${baseAcc + widget.accBonus}'
                                  : '🎯 ${widget.moveAccuracy}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: widget.accBonus > 0
                                    ? FontWeight.w700
                                    : FontWeight.normal,
                              ),
                            );
                          },
                        ),
                      if (widget.moveGauge.isNotEmpty &&
                          widget.moveGauge != '--')
                        Text(
                          '⚡ ${widget.moveGauge}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      if (widget.moveTarget.isNotEmpty &&
                          widget.moveTarget != '--')
                        Text(
                          '🎯 ${widget.moveTarget}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      if (widget.moveCategory.isNotEmpty)
                        Text(
                          widget.moveCategory,
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class CalcMoveCard extends StatelessWidget {
  const CalcMoveCard({
    super.key,
    required this.move,
    this.totalBp,
    this.baseBp,
    this.hasBpMod = false,
    this.teraBoost = false,
    this.isExtendedRange = false,
    this.isAreaSync = false,
    this.autoSyncBoosts = 0,
    this.atkStat,
    this.rolls,
    this.enemyHp = 1,
    this.tooltipText = '',
  });

  final MoveCardData move;
  final int? totalBp;
  final int? baseBp;
  final bool hasBpMod;
  final bool teraBoost;
  final bool isExtendedRange;
  final bool isAreaSync;
  final int autoSyncBoosts;
  final int? atkStat;
  final List<int>? rolls;
  final int enemyHp;
  final String tooltipText;

  @override
  Widget build(BuildContext context) {
    String? pctLabel;
    if (rolls != null && rolls!.isNotEmpty && enemyHp > 0) {
      final minPct = (rolls!.first / enemyHp * 100).toStringAsFixed(1);
      final maxPct = (rolls!.last / enemyHp * 100).toStringAsFixed(1);
      pctLabel = '$minPct-$maxPct%';
    }
    final typeC = consts.typeColor(move.type);
    final hasBp = totalBp != null;
    return Tooltip(
      message: tooltipText,
      waitDuration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color:
              typeC.withValues(alpha: 0.12) ??
              Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: typeC.withValues(alpha: 0.5) ?? Colors.grey.shade300,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (move.isSync)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.purple.shade300,
                    ),
                  ),
                Expanded(
                  child: Text(
                    move.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (isExtendedRange)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.teal, width: 0.5),
                    ),
                    child: const Text(
                      'Extended Range',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.teal,
                      ),
                    ),
                  ),
                if (isAreaSync)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.purple, width: 0.5),
                    ),
                    child: const Text(
                      'Area',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.purple,
                      ),
                    ),
                  ),
                if (autoSyncBoosts > 0)
                  Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.blue, width: 0.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.flash_on,
                          size: 10,
                          color: Colors.blue,
                        ),
                        Text(
                          '+$autoSyncBoosts',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (move.category.isNotEmpty)
                  Text(
                    move.category,
                    style: TextStyle(
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                if (pctLabel != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Text(
                      pctLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            if (hasBp)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: [
                    if (atkStat != null)
                      Text(
                        'Stat: $atkStat - ',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    Text(
                      'Power: ',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    if (hasBpMod && baseBp != null) ...[
                      Text(
                        '$baseBp',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        ' → ',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                      Text(
                        '$totalBp',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: teraBoost
                              ? const Color(0xFF6C5CE7)
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ] else
                      Text(
                        '$totalBp',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                  ],
                ),
              ),
            if (rolls != null && rolls!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Wrap(
                  spacing: 4,
                  children: [
                    for (int i = 0; i < rolls!.length; i++)
                      Text(
                        '${rolls![i]}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: i == rolls!.length - 1
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: i == rolls!.length - 1
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MoveCardData {
  const MoveCardData({
    required this.name,
    required this.type,
    required this.category,
    this.isSync = false,
  });

  final String name;
  final String type;
  final String category;
  final bool isSync;
}
