import 'package:flutter/material.dart';

import '../calculator_engine.dart';
import '../theme.dart';
import '../widgets/keypad.dart';
import 'history_screen.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key, required this.onOpenSettings});
  final VoidCallback onOpenSettings;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final CalculatorEngine _engine = CalculatorEngine();
  bool _scientific = false;

  void _update(VoidCallback action) => setState(action);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final short = constraints.maxHeight < 700;
          return Column(
            children: [
              SizedBox(
                height: 62,
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Calculation history',
                      onPressed: _openHistory,
                      icon: const Icon(Icons.history_rounded, color: AppColors.warm, size: 28),
                    ),
                    const Expanded(
                      child: Text(
                        'Calculator',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.warm, fontSize: 25, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: widget.onOpenSettings,
                      icon: const Icon(Icons.settings_outlined, color: AppColors.warm, size: 28),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: short ? 2 : 3,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 10, 30, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        _engine.expression.isEmpty ? 'Ready' : _engine.expression,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.muted, fontSize: 19),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text(
                          _engine.display,
                          style: const TextStyle(color: AppColors.text, fontSize: 64, fontWeight: FontWeight.w300),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ModeToggle(
                        scientific: _scientific,
                        onChanged: (value) => setState(() => _scientific = value),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: _scientific ? 8 : 7,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16, _scientific ? 10 : 18, 16, short ? 8 : 14),
                  decoration: const BoxDecoration(
                    color: AppColors.panel,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  child: Column(
                    children: [
                      if (_scientific) ...[
                        _scientificRow(['sin', 'cos', 'tan', 'log', 'ln']),
                        _scientificRow(['√', 'x²', 'x!', 'π', 'e']),
                      ],
                      _row([
                        CalcKey(label: 'AC', type: CalcKeyType.function, onTap: () => _update(_engine.clear)),
                        CalcKey(label: 'Delete', icon: Icons.backspace_outlined, type: CalcKeyType.function, onTap: () => _update(_engine.backspace)),
                        CalcKey(label: '%', type: CalcKeyType.function, onTap: () => _update(_engine.percent)),
                        CalcKey(label: '÷', type: CalcKeyType.operator, onTap: () => _update(() => _engine.operator('÷'))),
                      ]),
                      _digitRow('7', '8', '9', '×'),
                      _digitRow('4', '5', '6', '−'),
                      _digitRow('1', '2', '3', '+'),
                      _row([
                        CalcKey(label: '0', flex: 2, onTap: () => _update(() => _engine.digit('0'))),
                        CalcKey(label: '.', onTap: () => _update(() => _engine.digit('.'))),
                        CalcKey(label: '=', type: CalcKeyType.operator, onTap: () => _update(_engine.equals)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(List<Widget> children) => Expanded(child: Row(children: children));

  Widget _digitRow(String a, String b, String c, String op) => _row([
        CalcKey(label: a, onTap: () => _update(() => _engine.digit(a))),
        CalcKey(label: b, onTap: () => _update(() => _engine.digit(b))),
        CalcKey(label: c, onTap: () => _update(() => _engine.digit(c))),
        CalcKey(label: op, type: CalcKeyType.operator, onTap: () => _update(() => _engine.operator(op))),
      ]);

  Widget _scientificRow(List<String> labels) {
    return SizedBox(
      height: 47,
      child: Row(
        children: labels.map((label) {
          return CalcKey(
            label: label,
            compact: true,
            type: CalcKeyType.function,
            onTap: () => _update(() {
              if (label == 'π') {
                _engine.constant(3.141592653589793, 'π');
              } else if (label == 'e') {
                _engine.constant(2.718281828459045, 'e');
              } else {
                _engine.scientific(label);
              }
            }),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _openHistory() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => HistoryScreen(history: _engine.history)),
    );
    if (!mounted) return;
    if (result == '__clear__') {
      setState(_engine.history.clear);
    } else if (result != null) {
      setState(() => _engine.useResult(result));
    }
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.scientific, required this.onChanged});
  final bool scientific;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        _item('Basic', !scientific, () => onChanged(false)),
        const SizedBox(width: 18),
        _item('Scientific', scientific, () => onChanged(true)),
      ],
    );
  }

  Widget _item(String text, bool selected, VoidCallback onTap) => InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            text,
            style: TextStyle(
              color: selected ? AppColors.orange : AppColors.muted,
              fontWeight: FontWeight.w600,
              decoration: selected ? TextDecoration.underline : null,
              decorationColor: AppColors.orange,
              decorationThickness: 2,
            ),
          ),
        ),
      );
}
