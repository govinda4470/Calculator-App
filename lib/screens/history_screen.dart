import 'package:flutter/material.dart';

import '../calculator_engine.dart';
import '../theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, required this.history});
  final List<Calculation> history;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.warm),
        ),
        title: const Text('History', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w500)),
        actions: [
          IconButton(
            tooltip: 'Clear history',
            onPressed: history.isEmpty ? null : () => _confirmClear(context),
            icon: const Icon(Icons.delete_sweep_outlined),
          ),
        ],
      ),
      body: history.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 52, color: AppColors.muted),
                  SizedBox(height: 14),
                  Text('No calculations yet', style: TextStyle(fontSize: 20, color: AppColors.text)),
                  SizedBox(height: 6),
                  Text('Your completed calculations will appear here', style: TextStyle(color: AppColors.muted)),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
              children: [
                const Text('Today', style: TextStyle(color: AppColors.warm, fontSize: 20)),
                const SizedBox(height: 12),
                ...history.map((item) => InkWell(
                      onTap: () => Navigator.pop(context, item.result),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.stroke)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(item.expression, style: const TextStyle(color: AppColors.muted, fontSize: 18)),
                            const SizedBox(height: 5),
                            Text('= ${item.result}', style: const TextStyle(color: AppColors.text, fontSize: 27)),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final clear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text('This will remove all saved calculations.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Clear')),
        ],
      ),
    );
    if (clear == true && context.mounted) Navigator.pop(context, '__clear__');
  }
}
