import 'package:flutter/material.dart';

import '../theme.dart';

enum CalcKeyType { number, function, operator }

class CalcKey extends StatelessWidget {
  const CalcKey({
    super.key,
    required this.label,
    required this.onTap,
    this.type = CalcKeyType.number,
    this.flex = 1,
    this.compact = false,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final CalcKeyType type;
  final int flex;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final background = switch (type) {
      CalcKeyType.number => AppColors.key,
      CalcKeyType.function => AppColors.function,
      CalcKeyType.operator => AppColors.orange,
    };
    final foreground = switch (type) {
      CalcKeyType.number => AppColors.text,
      CalcKeyType.function => AppColors.blue,
      CalcKeyType.operator => Colors.white,
    };
    return Expanded(
      flex: flex,
      child: Semantics(
        button: true,
        label: label,
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Material(
            color: background,
            borderRadius: BorderRadius.circular(compact ? 12 : 999),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: Container(
                constraints: BoxConstraints(minHeight: compact ? 38 : 58),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(compact ? 12 : 999),
                  border: const Border(top: BorderSide(color: Colors.white10)),
                ),
                alignment: Alignment.center,
                child: icon != null
                    ? Icon(icon, color: foreground, size: compact ? 22 : 25)
                    : Text(
                        label,
                        style: TextStyle(
                          color: foreground,
                          fontSize: compact ? 18 : 23,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
