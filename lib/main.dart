import 'package:flutter/material.dart';

import 'screens/calculator_screen.dart';
import 'screens/converter_screen.dart';
import 'screens/settings_screen.dart';
import 'theme.dart';

void main() => runApp(const PrecisionCalcApp());

class PrecisionCalcApp extends StatelessWidget {
  const PrecisionCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Precision Calc',
      debugShowCheckedModeBanner: false,
      theme: precisionTheme,
      home: const AppShell(),
    );
  }
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;
  bool _cryptoToolsEnabled = false;

  @override
  Widget build(BuildContext context) {
    final pages = [
      CalculatorScreen(onOpenSettings: () => setState(() => _index = 2)),
      ConverterScreen(
        cryptoToolsEnabled: _cryptoToolsEnabled,
        onCryptoToolsChanged: (value) => setState(() => _cryptoToolsEnabled = value),
      ),
      SettingsScreen(
        cryptoToolsEnabled: _cryptoToolsEnabled,
        onCryptoToolsChanged: (value) => setState(() => _cryptoToolsEnabled = value),
      ),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 82,
          decoration: const BoxDecoration(
            color: AppColors.panel,
            border: Border(top: BorderSide(color: AppColors.stroke)),
          ),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.calculate_outlined,
                label: 'Calculator',
                selected: _index == 0,
                onTap: () => setState(() => _index = 0),
              ),
              _NavItem(
                icon: Icons.swap_horiz_rounded,
                label: 'Converter',
                selected: _index == 1,
                onTap: () => setState(() => _index = 1),
              ),
              _NavItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                selected: _index == 2,
                onTap: () => setState(() => _index = 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.orange : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: selected ? AppColors.ink : AppColors.warm, size: 25),
                  const SizedBox(height: 3),
                  Text(label, style: TextStyle(color: selected ? AppColors.ink : AppColors.warm, fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
