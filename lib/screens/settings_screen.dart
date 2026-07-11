import 'package:flutter/material.dart';

import '../theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _haptics = true;
  bool _autoRates = true;
  bool _lockAlerts = false;
  String _precision = '4';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 14, 20, 12),
            child: Row(
              children: [
                Icon(Icons.calculate_outlined, color: AppColors.warm),
                SizedBox(width: 12),
                Text('Precision Calc', style: TextStyle(color: AppColors.warm, fontSize: 25, fontWeight: FontWeight.w500)),
                Spacer(),
                Text('Settings', style: TextStyle(color: AppColors.text, fontSize: 21)),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
              children: [
                _section('General', [
                  const _SettingsTile(icon: Icons.dark_mode_outlined, title: 'Theme', subtitle: 'Dark', trailing: _ValueBadge('Dark')),
                  _SettingsTile(
                    icon: Icons.exposure_zero_outlined,
                    title: 'Precision',
                    subtitle: 'Decimal places',
                    trailing: DropdownButton<String>(
                      value: _precision,
                      underline: const SizedBox.shrink(),
                      dropdownColor: AppColors.key,
                      onChanged: (value) => setState(() => _precision = value!),
                      items: ['2', '4', '6', '8'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.vibration_outlined,
                    title: 'Vibration',
                    subtitle: 'Haptic feedback on press',
                    trailing: Switch(value: _haptics, onChanged: (value) => setState(() => _haptics = value)),
                  ),
                ]),
                _section('Converter', [
                  const _SettingsTile(icon: Icons.attach_money, title: 'Base Currency', subtitle: 'USD · US Dollar', trailing: Icon(Icons.chevron_right, color: AppColors.warm)),
                  _SettingsTile(
                    icon: Icons.sync,
                    title: 'Auto-update rates',
                    subtitle: 'Fetch latest exchange rates daily',
                    trailing: Switch(value: _autoRates, onChanged: (value) => setState(() => _autoRates = value)),
                  ),
                  _SettingsTile(
                    icon: Icons.delete_outline,
                    iconColor: Color(0xFFFFB4AB),
                    title: 'Clear Cache',
                    titleColor: Color(0xFFFFB4AB),
                    subtitle: 'Remove downloaded rate data',
                    onTap: _cacheCleared,
                  ),
                ]),
                _section('Notifications', [
                  const _SettingsTile(icon: Icons.notifications_active_outlined, title: 'Price Alert Sound', subtitle: 'Chime', trailing: Icon(Icons.chevron_right, color: AppColors.warm)),
                  _SettingsTile(
                    icon: Icons.lock_outline,
                    title: 'Lock Screen Alerts',
                    subtitle: 'Show notifications when locked',
                    trailing: Switch(value: _lockAlerts, onChanged: (value) => setState(() => _lockAlerts = value)),
                  ),
                ]),
                _section('About', const [
                  _SettingsTile(icon: Icons.info_outline, title: 'Version', trailing: Text('v1.0.0', style: TextStyle(color: AppColors.warm))),
                  _SettingsTile(icon: Icons.description_outlined, title: 'Terms of Service', trailing: Icon(Icons.open_in_new, color: AppColors.warm)),
                  _SettingsTile(icon: Icons.shield_outlined, title: 'Privacy Policy', trailing: Icon(Icons.open_in_new, color: AppColors.warm)),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(title, style: const TextStyle(color: AppColors.warm, fontSize: 18)),
          ),
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(color: AppColors.key, borderRadius: BorderRadius.circular(13)),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  void _cacheCleared() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cached rate data cleared')));
  }
}

class _ValueBadge extends StatelessWidget {
  const _ValueBadge(this.value);
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(color: AppColors.function, borderRadius: BorderRadius.circular(8)),
        child: Text(value),
      );
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.iconColor = AppColors.warm,
    this.titleColor = AppColors.text,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 76),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.stroke))),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 23),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: titleColor, fontSize: 17)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle!, style: const TextStyle(color: AppColors.muted, fontSize: 13)),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
