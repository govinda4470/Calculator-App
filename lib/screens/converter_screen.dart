import 'package:flutter/material.dart';

import '../calculator_engine.dart';
import '../theme.dart';
import '../services/market_data_service.dart';
import '../widgets/keypad.dart';
import 'crypto_hub_screen.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({
    super.key,
    required this.cryptoToolsEnabled,
    required this.onCryptoToolsChanged,
  });

  final bool cryptoToolsEnabled;
  final ValueChanged<bool> onCryptoToolsChanged;

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final _marketData = MarketDataService();
  final _categories = <_Category>[
    _Category('Length', Icons.straighten, {'Meters': 1, 'Kilometers': 1000, 'Centimeters': .01, 'Miles': 1609.344, 'Feet': .3048, 'Inches': .0254}),
    _Category('Weight', Icons.fitness_center, {'Kilograms': 1, 'Grams': .001, 'Pounds': .45359237, 'Ounces': .0283495, 'Tonnes': 1000}),
    _Category('Volume', Icons.water_drop_outlined, {'Liters': 1, 'Milliliters': .001, 'Gallons (US)': 3.7854118, 'Cups': .236588, 'Fluid ounces': .0295735}),
    _Category('Temperature', Icons.thermostat_outlined, {'Celsius': 1, 'Fahrenheit': 1, 'Kelvin': 1}),
    _Category('Currency', Icons.attach_money, {'USD': 1, 'EUR': 1.087, 'GBP': 1.278, 'JPY': .0067, 'INR': .01198, 'AUD': .658}),
    _Category('Crypto', Icons.currency_bitcoin, {'BTC': 64231.20, 'USD': 1, 'ETH': 3520.45, 'SOL': 142.80, 'BNB': 585.30, 'USDT': 1, 'INR': .01198}),
    _Category('Data', Icons.storage_outlined, {'Bytes': 1, 'Kilobytes': 1024, 'Megabytes': 1048576, 'Gigabytes': 1073741824, 'Terabytes': 1099511627776}),
  ];

  int _categoryIndex = 0;
  String _input = '1';
  late String _from;
  late String _to;
  bool _refreshingRates = true;
  bool _fiatLive = false;
  bool _cryptoLive = false;
  String? _rateError;
  DateTime? _ratesUpdatedAt;

  _Category get _category => _categories[_categoryIndex];

  @override
  void initState() {
    super.initState();
    _from = _categories.first.units.keys.first;
    _to = _categories.first.units.keys.elementAt(1);
    _refreshRates();
  }

  @override
  void dispose() {
    _marketData.close();
    super.dispose();
  }

  Future<void> _refreshRates() async {
    setState(() {
      _refreshingRates = true;
      _rateError = null;
    });
    String? error;
    try {
      final factors = await _marketData.fetchUsdFiatFactors();
      final currency = _categories.firstWhere((item) => item.name == 'Currency');
      for (final symbol in currency.units.keys.toList()) {
        if (factors[symbol] != null) currency.units[symbol] = factors[symbol]!;
      }
      final crypto = _categories.firstWhere((item) => item.name == 'Crypto');
      if (factors['INR'] != null) crypto.units['INR'] = factors['INR']!;
      _fiatLive = true;
    } on Object catch (exception) {
      error = exception.toString();
      _fiatLive = false;
    }
    try {
      final snapshot = await _marketData.fetchCryptoSnapshot();
      final crypto = _categories.firstWhere((item) => item.name == 'Crypto');
      for (final entry in snapshot.crypto.entries) {
        crypto.units[entry.key] = entry.value.usd;
      }
      _cryptoLive = true;
    } on Object catch (exception) {
      error = error == null ? exception.toString() : '$error Crypto: $exception';
      _cryptoLive = false;
    }
    if (!mounted) return;
    setState(() {
      _refreshingRates = false;
      _rateError = error;
      if (_fiatLive || _cryptoLive) _ratesUpdatedAt = DateTime.now();
    });
  }

  double get _result {
    final value = double.tryParse(_input) ?? 0;
    if (_category.name == 'Temperature') return _convertTemperature(value, _from, _to);
    return value * _category.units[_from]! / _category.units[_to]!;
  }

  void _selectCategory(int index) {
    setState(() {
      _categoryIndex = index;
      _from = _category.units.keys.first;
      _to = _category.units.keys.elementAt(1);
    });
  }

  void _type(String value) {
    setState(() {
      if (value == '.' && _input.contains('.')) return;
      if (_input == '0' && value != '.') {
        _input = value;
      } else if (_input.replaceAll('-', '').replaceAll('.', '').length < 12) {
        _input += value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Icon(Icons.calculate_outlined, color: AppColors.warm),
                SizedBox(width: 10),
                Text('Precision Calc', style: TextStyle(color: AppColors.warm, fontSize: 29, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, index) {
                final category = _categories[index];
                final selected = index == _categoryIndex;
                return ChoiceChip(
                  selected: selected,
                  onSelected: (_) => _selectCategory(index),
                  showCheckmark: false,
                  avatar: Icon(category.icon, size: 19, color: selected ? AppColors.ink : AppColors.warm),
                  label: Text(category.name),
                  labelStyle: TextStyle(color: selected ? AppColors.ink : AppColors.text, fontSize: 15),
                  selectedColor: AppColors.orange,
                  backgroundColor: AppColors.key,
                  side: BorderSide.none,
                  shape: const StadiumBorder(),
                );
              },
            ),
          ),
          if (_category.name == 'Crypto')
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 2, 18, 5),
              child: Material(
                color: widget.cryptoToolsEnabled ? const Color(0xFF30291E) : AppColors.panel,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: _openCryptoTools,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        Icon(
                          widget.cryptoToolsEnabled ? Icons.insights_rounded : Icons.visibility_off_outlined,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.cryptoToolsEnabled ? 'Open crypto workspace' : 'Enable optional crypto tools',
                            style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.warm),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              final compact = constraints.maxHeight < 650;
              return Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(24, compact ? 6 : 18, 24, compact ? 8 : 18),
                      child: Column(
                        children: [
                          if (_category.name == 'Currency' || _category.name == 'Crypto')
                            _RateStatus(
                              loading: _refreshingRates,
                              live: _category.name == 'Crypto' ? _cryptoLive : _fiatLive,
                              updatedAt: _ratesUpdatedAt,
                              error: _rateError,
                              onRefresh: _refreshRates,
                            ),
                          const Spacer(),
                          _ValuePanel(
                            unit: _from,
                            units: _category.units.keys.toList(),
                            value: _input,
                            valueColor: AppColors.text,
                            onChanged: (value) => setState(() => _from = value!),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: compact ? 8 : 18),
                            child: Row(children: [
                              const Expanded(child: Divider()),
                              Material(
                                color: AppColors.key,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: 'Swap units',
                                  onPressed: () => setState(() {
                                    final converted = _result;
                                    final old = _from;
                                    _from = _to;
                                    _to = old;
                                    _input = CalculatorEngine.format(converted, precision: 8);
                                  }),
                                  icon: const Icon(Icons.swap_vert_rounded, color: AppColors.warm),
                                ),
                              ),
                              const Expanded(child: Divider()),
                            ]),
                          ),
                          _ValuePanel(
                            unit: _to,
                            units: _category.units.keys.toList(),
                            value: CalculatorEngine.format(_result, precision: 6),
                            valueColor: AppColors.warm,
                            onChanged: (value) => setState(() => _to = value!),
                          ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    height: compact ? 288 : 326,
                    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                    decoration: const BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
                    child: Column(children: [
                      _keyRow([
                        CalcKey(label: 'AC', compact: true, type: CalcKeyType.function, onTap: () => setState(() => _input = '0')),
                        CalcKey(label: 'Delete', compact: true, icon: Icons.backspace_outlined, type: CalcKeyType.function, onTap: () => setState(() => _input = _input.length <= 1 ? '0' : _input.substring(0, _input.length - 1))),
                        CalcKey(label: '+/−', compact: true, type: CalcKeyType.function, onTap: () => setState(() => _input = _input.startsWith('-') ? _input.substring(1) : '-$_input')),
                      ]),
                      _numberRow('7', '8', '9'),
                      _numberRow('4', '5', '6'),
                      _numberRow('1', '2', '3'),
                      _keyRow([
                        CalcKey(label: '0', compact: true, flex: 2, onTap: () => _type('0')),
                        CalcKey(label: '.', compact: true, onTap: () => _type('.')),
                      ]),
                    ]),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _keyRow(List<Widget> keys) => Expanded(child: Row(children: keys));
  Widget _numberRow(String a, String b, String c) => _keyRow([
        CalcKey(label: a, compact: true, onTap: () => _type(a)),
        CalcKey(label: b, compact: true, onTap: () => _type(b)),
        CalcKey(label: c, compact: true, onTap: () => _type(c)),
      ]);

  Future<void> _openCryptoTools() async {
    if (!widget.cryptoToolsEnabled) {
      final enabled = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.currency_bitcoin, color: AppColors.orange, size: 38),
          title: const Text('Enable crypto workspace?'),
          content: const Text(
            'This optional area adds portfolio tracking, market analytics and educational expert insights. '
            'It remains hidden when disabled. Prices in this prototype are sample data and are not financial advice.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Not now')),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enable')),
          ],
        ),
      );
      if (enabled != true || !mounted) return;
      widget.onCryptoToolsChanged(true);
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CryptoHubScreen()),
    );
  }

  double _convertTemperature(double value, String from, String to) {
    final celsius = switch (from) {
      'Fahrenheit' => (value - 32) * 5 / 9,
      'Kelvin' => value - 273.15,
      _ => value,
    };
    return switch (to) {
      'Fahrenheit' => celsius * 9 / 5 + 32,
      'Kelvin' => celsius + 273.15,
      _ => celsius,
    };
  }
}

class _RateStatus extends StatelessWidget {
  const _RateStatus({
    required this.loading,
    required this.live,
    required this.updatedAt,
    required this.error,
    required this.onRefresh,
  });

  final bool loading;
  final bool live;
  final DateTime? updatedAt;
  final String? error;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final time = updatedAt == null
        ? 'Using cached sample rates'
        : 'Updated ${updatedAt!.hour.toString().padLeft(2, '0')}:${updatedAt!.minute.toString().padLeft(2, '0')}';
    return Row(children: [
      if (loading)
        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
      else
        Icon(Icons.circle, color: live ? AppColors.green : AppColors.orange, size: 11),
      const SizedBox(width: 7),
      Text(
        loading ? 'UPDATING RATES' : live ? 'LIVE RATES' : 'OFFLINE RATES',
        style: const TextStyle(color: AppColors.text, fontSize: 12, letterSpacing: 1.2),
      ),
      const Spacer(),
      Flexible(
        child: Text(
          error != null && !live ? 'Tap to retry' : time,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.muted, fontSize: 11),
        ),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        tooltip: 'Refresh rates',
        onPressed: loading ? null : onRefresh,
        icon: const Icon(Icons.refresh, size: 18, color: AppColors.warm),
      ),
    ]);
  }
}

class _Category {
  const _Category(this.name, this.icon, this.units);
  final String name;
  final IconData icon;
  final Map<String, double> units;
}

class _ValuePanel extends StatelessWidget {
  const _ValuePanel({required this.unit, required this.units, required this.value, required this.valueColor, required this.onChanged});
  final String unit;
  final List<String> units;
  final String value;
  final Color valueColor;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(8)),
          child: DropdownButton<String>(
            value: unit,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.panel,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.text),
            style: const TextStyle(color: Color(0xFFC7D9FF), fontSize: 17),
            onChanged: onChanged,
            items: units.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
          ),
        ),
        const SizedBox(height: 5),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(value, style: TextStyle(color: valueColor, fontSize: 43, fontWeight: FontWeight.w300)),
        ),
      ],
    );
  }
}
