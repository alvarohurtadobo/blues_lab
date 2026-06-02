import 'package:flutter/material.dart';

import '../constants/type_data.dart' as consts;

class TypeRebuffDropdown extends StatelessWidget {
  const TypeRebuffDropdown({
    super.key,
    required this.type,
    required this.value,
    required this.onChanged,
    this.min = -3,
    this.max = 0,
  });

  final String type;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;

  @override
  Widget build(BuildContext context) {
    final color = consts.typeColors[type.toLowerCase()] ?? Colors.grey;
    final iconPath = consts.typeIcons[type.toLowerCase()];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: value != 0
            ? color.withValues(alpha: 0.2)
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: value != 0 ? color : color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (iconPath != null)
            Image.asset(iconPath, width: 18, height: 18)
          else
            Text(
              type,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          const SizedBox(width: 2),
          DropdownButton<int>(
            value: value,
            isDense: true,
            underline: const SizedBox(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: value < 0
                  ? Colors.green.shade800
                  : value > 0
                  ? Colors.red.shade800
                  : Colors.black,
            ),
            items: [
              for (int i = max; i >= min; i--)
                DropdownMenuItem(value: i, child: Text(i > 0 ? '+$i' : '$i')),
            ],
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
    );
  }
}
