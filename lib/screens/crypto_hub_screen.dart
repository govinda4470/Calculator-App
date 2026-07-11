import 'package:flutter/material.dart';

import '../theme.dart';

class CryptoHubScreen extends StatefulWidget {
  const CryptoHubScreen({super.key});

  @override
  State<CryptoHubScreen> createState() => _CryptoHubScreenState();
}

class _CryptoHubScreenState extends State<CryptoHubScreen> {
  int _tab = 0;
  final List<_Asset> _assets = [
    const _Asset('Bitcoin', 'BTC', 0.245, 64231.20, 2.4, Color(0xFFF7931A)),
    const _Asset('Ethereum', 'ETH', 1.75, 3520.45, 1.8, Color(0xFF627EEA)),
    const _Asset('Solana', 'SOL', 21.25, 142.80, -0.5, Color(0xFF14F195)),
  ];

  double get _total => _assets.fold(0.0, (sum, asset) => sum + asset.amount * asset.price);

  @override
  Widget build(BuildContext context) {
    const titles = ['Portfolio', 'Markets', 'Analytics', 'Crypto Expert'];
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Close crypto workspace',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.warm),
        ),
        title: Text(titles[_tab], style: const TextStyle(color: AppColors.warm, fontSize: 24)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(color: AppColors.key, borderRadius: BorderRadius.circular(6)),
            child: const Text('SAMPLE', style: TextStyle(color: AppColors.muted, fontSize: 10, letterSpacing: 1.2)),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          _portfolio(),
          const _MarketsView(),
          _AnalyticsView(total: _total),
          const _ExpertView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 72,
        selectedIndex: _tab,
        backgroundColor: AppColors.panel,
        indicatorColor: AppColors.orange,
        onDestinationSelected: (value) => setState(() => _tab = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet, color: AppColors.ink), label: 'Portfolio'),
          NavigationDestination(icon: Icon(Icons.candlestick_chart_outlined), selectedIcon: Icon(Icons.candlestick_chart, color: AppColors.ink), label: 'Markets'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), selectedIcon: Icon(Icons.insights, color: AppColors.ink), label: 'Analytics'),
          NavigationDestination(icon: Icon(Icons.auto_awesome_outlined), selectedIcon: Icon(Icons.auto_awesome, color: AppColors.ink), label: 'Expert'),
        ],
      ),
    );
  }

  Widget _portfolio() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        const Text('TOTAL BALANCE', style: TextStyle(color: AppColors.muted, fontSize: 12, letterSpacing: 1.3)),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text('\$${_money(_total)}', style: const TextStyle(color: AppColors.text, fontSize: 52, fontWeight: FontWeight.w300)),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
          decoration: BoxDecoration(color: AppColors.key, borderRadius: BorderRadius.circular(22)),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.trending_up, color: AppColors.green, size: 20),
            SizedBox(width: 8),
            Text('+\$1,240.50 (5.3%)', style: TextStyle(color: Color(0xFF9ECAFF), fontSize: 17)),
            Spacer(),
            Text('24h', style: TextStyle(color: AppColors.muted)),
          ]),
        ),
        const SizedBox(height: 26),
        Row(children: [
          const Text('Your assets', style: TextStyle(color: AppColors.text, fontSize: 24, fontWeight: FontWeight.w500)),
          const Spacer(),
          TextButton.icon(onPressed: _addAsset, icon: const Icon(Icons.add), label: const Text('Track asset')),
        ]),
        const SizedBox(height: 6),
        ..._assets.map((asset) => _AssetCard(asset: asset, onDelete: () => setState(() => _assets.remove(asset)))),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _addAsset,
          icon: const Icon(Icons.add_circle_outline),
          label: const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Text('Track another asset')),
        ),
        const SizedBox(height: 20),
        const _InfoNote(text: 'Portfolio values are stored only for this session. Connect an authenticated market-data provider before using real funds.'),
      ],
    );
  }

  Future<void> _addAsset() async {
    String symbol = 'BTC';
    final amountController = TextEditingController(text: '0.01');
    const choices = {
      'BTC': ('Bitcoin', 64231.20, Color(0xFFF7931A)),
      'ETH': ('Ethereum', 3520.45, Color(0xFF627EEA)),
      'SOL': ('Solana', 142.80, Color(0xFF14F195)),
      'BNB': ('BNB', 585.30, Color(0xFFF3BA2F)),
      'ADA': ('Cardano', 0.45, Color(0xFF3CC8C8)),
    };
    final asset = await showDialog<_Asset>(
      context: context,
      builder: (context) => StatefulBuilder(builder: (context, setDialogState) {
        return AlertDialog(
          title: const Text('Track an asset'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: symbol,
              decoration: const InputDecoration(labelText: 'Asset'),
              items: choices.keys.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
              onChanged: (value) => setDialogState(() => symbol = value!),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.toll)),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;
                final data = choices[symbol]!;
                Navigator.pop(context, _Asset(data.$1, symbol, amount, data.$2, 0.0, data.$3));
              },
              child: const Text('Add'),
            ),
          ],
        );
      }),
    );
    amountController.dispose();
    if (asset != null && mounted) setState(() => _assets.add(asset));
  }

  String _money(double value) {
    final fixed = value.toStringAsFixed(2).split('.');
    final digits = fixed.first;
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return '$buffer.${fixed.last}';
  }
}

class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset, required this.onDelete});
  final _Asset asset;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final positive = asset.change >= 0;
    return Dismissible(
      key: ObjectKey(asset),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.only(right: 20),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(color: const Color(0xFF6A2028), borderRadius: BorderRadius.circular(13)),
        child: const Icon(Icons.delete_outline),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(13), border: Border.all(color: AppColors.stroke)),
        child: Row(children: [
          CircleAvatar(backgroundColor: asset.color.withValues(alpha: .18), child: Text(asset.symbol[0], style: TextStyle(color: asset.color, fontWeight: FontWeight.bold))),
          const SizedBox(width: 13),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(asset.name, style: const TextStyle(color: AppColors.text, fontSize: 18)),
            Text('${asset.amount} ${asset.symbol}', style: const TextStyle(color: AppColors.muted)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${(asset.amount * asset.price).toStringAsFixed(2)}', style: const TextStyle(color: AppColors.text, fontSize: 17)),
            Text('${positive ? '+' : ''}${asset.change}%', style: TextStyle(color: positive ? AppColors.green : const Color(0xFFF6465D))),
          ]),
        ]),
      ),
    );
  }
}

class _MarketsView extends StatefulWidget {
  const _MarketsView();
  @override
  State<_MarketsView> createState() => _MarketsViewState();
}

class _MarketsViewState extends State<_MarketsView> {
  final Set<String> _watching = {'BTC', 'ETH'};
  bool _alerts = false;
  static const _coins = [
    ('BTC', 'Bitcoin', '64,231.20', 2.4),
    ('ETH', 'Ethereum', '3,520.45', 1.8),
    ('SOL', 'Solana', '142.80', -0.5),
    ('BNB', 'BNB', '585.30', 0.9),
    ('ADA', 'Cardano', '0.45', -1.2),
    ('LINK', 'Chainlink', '14.27', 3.1),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        const _InfoNote(text: 'Sample market data for interface testing — not live prices.'),
        const SizedBox(height: 18),
        Row(children: [
          const Text('Market watch', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
          const Spacer(),
          const Text('Price alerts', style: TextStyle(color: AppColors.muted)),
          Switch(value: _alerts, onChanged: (value) => setState(() => _alerts = value)),
        ]),
        const SizedBox(height: 8),
        ..._coins.map((coin) {
          final positive = coin.$4 >= 0;
          final watching = _watching.contains(coin.$1);
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
            leading: CircleAvatar(backgroundColor: AppColors.key, child: Text(coin.$1[0], style: const TextStyle(color: AppColors.orange))),
            title: Text(coin.$2),
            subtitle: Text(coin.$1, style: const TextStyle(color: AppColors.muted)),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('\$${coin.$3}'),
                Text('${positive ? '+' : ''}${coin.$4}%', style: TextStyle(color: positive ? AppColors.green : const Color(0xFFF6465D))),
              ]),
              IconButton(
                tooltip: watching ? 'Remove from watchlist' : 'Add to watchlist',
                onPressed: () => setState(() => watching ? _watching.remove(coin.$1) : _watching.add(coin.$1)),
                icon: Icon(watching ? Icons.star : Icons.star_border, color: watching ? AppColors.orange : AppColors.muted),
              ),
            ]),
          );
        }),
        const SizedBox(height: 18),
        const Text('Market sentiment', style: TextStyle(fontSize: 21)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(13)),
          child: Column(children: [
            const Row(children: [Text('Fear', style: TextStyle(color: AppColors.muted)), Spacer(), Text('72 · Greed', style: TextStyle(color: AppColors.warm, fontSize: 18))]),
            const SizedBox(height: 12),
            ClipRRect(borderRadius: BorderRadius.circular(4), child: const LinearProgressIndicator(value: .72, minHeight: 9, color: AppColors.green, backgroundColor: Color(0xFF8D3C35))),
          ]),
        ),
      ],
    );
  }
}

class _AnalyticsView extends StatelessWidget {
  const _AnalyticsView({required this.total});
  final double total;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        const Text('Portfolio performance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Text('\$${total.toStringAsFixed(2)} total value', style: const TextStyle(color: AppColors.muted)),
        const SizedBox(height: 18),
        Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.stroke)),
          child: const Column(children: [
            Row(children: [Text('30 DAY TREND', style: TextStyle(color: AppColors.muted, fontSize: 11, letterSpacing: 1.1)), Spacer(), Text('+5.3%', style: TextStyle(color: AppColors.green))]),
            Expanded(child: CustomPaint(painter: _ChartPainter(), size: Size.infinite)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Jun 12', style: TextStyle(color: AppColors.muted, fontSize: 11)), Text('Jun 27', style: TextStyle(color: AppColors.muted, fontSize: 11)), Text('Today', style: TextStyle(color: AppColors.muted, fontSize: 11))]),
          ]),
        ),
        const SizedBox(height: 16),
        const Row(children: [
          Expanded(child: _MetricCard(label: 'Unrealized P&L', value: '+\$1,240', color: AppColors.green)),
          SizedBox(width: 12),
          Expanded(child: _MetricCard(label: '24h change', value: '+2.8%', color: AppColors.green)),
        ]),
        const SizedBox(height: 12),
        const Row(children: [
          Expanded(child: _MetricCard(label: 'Best asset', value: 'LINK', color: AppColors.warm)),
          SizedBox(width: 12),
          Expanded(child: _MetricCard(label: 'Risk level', value: 'Medium', color: Color(0xFFFFD166))),
        ]),
        const SizedBox(height: 22),
        const Text('Allocation', style: TextStyle(fontSize: 21)),
        const SizedBox(height: 12),
        const _Allocation(label: 'Bitcoin', value: .62, color: Color(0xFFF7931A)),
        const _Allocation(label: 'Ethereum', value: .25, color: Color(0xFF627EEA)),
        const _Allocation(label: 'Other assets', value: .13, color: AppColors.green),
        const SizedBox(height: 20),
        const _InfoNote(text: 'Analytics are estimates based on sample prices. They do not represent investment performance.'),
      ],
    );
  }
}

class _ExpertView extends StatefulWidget {
  const _ExpertView();
  @override
  State<_ExpertView> createState() => _ExpertViewState();
}

class _ExpertViewState extends State<_ExpertView> {
  final _controller = TextEditingController();
  String? _response;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: const Color(0xFF481A1C), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFF6465D))),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFFB4AB)),
            SizedBox(width: 12),
            Expanded(child: Text('Educational information only. This expert does not provide financial advice, execute trades, or guarantee future performance. Always do your own research.')),
          ]),
        ),
        const SizedBox(height: 20),
        const Text('Expert market pulse', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
        const SizedBox(height: 12),
        const _InsightCard(symbol: 'BTC/USD', change: '+1.24%', text: 'Consolidation above the 50-day moving average. Volume remains mixed near the recent resistance zone.', positive: true),
        const _InsightCard(symbol: 'ETH/USD', change: '-0.45%', text: 'Momentum trails Bitcoin while exchange flows remain balanced. Watch the nearby support range.', positive: false),
        const SizedBox(height: 20),
        const Text('High-signal watch items', style: TextStyle(fontSize: 21)),
        const SizedBox(height: 10),
        const _SignalTile(icon: Icons.show_chart, title: 'RSI divergence on SOL', detail: '1H timeframe · Bullish'),
        const _SignalTile(icon: Icons.waves, title: 'Whale accumulation on LINK', detail: 'On-chain · Unconfirmed'),
        const _SignalTile(icon: Icons.trending_down, title: 'Overbought momentum on ARB', detail: '4H timeframe · Caution'),
        const SizedBox(height: 18),
        TextField(
          controller: _controller,
          minLines: 1,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ask about a market concept…',
            filled: true,
            fillColor: AppColors.panel,
            suffixIcon: IconButton(onPressed: _answer, icon: const Icon(Icons.send_rounded, color: AppColors.orange)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.stroke)),
          ),
          onSubmitted: (_) => _answer(),
        ),
        if (_response != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.stroke)),
            child: Text(_response!),
          ),
        ],
      ],
    );
  }

  void _answer() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _response = 'Prototype expert: Consider price trend, trading volume, volatility, liquidity and your own risk tolerance together. No single indicator is sufficient. This offline demo cannot evaluate current market conditions.';
    });
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.symbol, required this.change, required this.text, required this.positive});
  final String symbol;
  final String change;
  final String text;
  final bool positive;
  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [Text(symbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)), const Spacer(), Text(change, style: TextStyle(color: positive ? AppColors.green : const Color(0xFFF6465D)))]),
          const SizedBox(height: 9),
          Text(text, style: const TextStyle(color: AppColors.muted, height: 1.4)),
        ]),
      );
}

class _SignalTile extends StatelessWidget {
  const _SignalTile({required this.icon, required this.title, required this.detail});
  final IconData icon;
  final String title;
  final String detail;
  @override
  Widget build(BuildContext context) => Card(
        color: AppColors.panel,
        child: ListTile(
          leading: Icon(icon, color: AppColors.blue),
          title: Text(title),
          subtitle: Text(detail, style: const TextStyle(color: AppColors.muted)),
          trailing: const Icon(Icons.chevron_right),
        ),
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: AppColors.panel, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.stroke)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          const SizedBox(height: 7),
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w600)),
        ]),
      );
}

class _Allocation extends StatelessWidget {
  const _Allocation({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(children: [
          Row(children: [Text(label), const Spacer(), Text('${(value * 100).round()}%', style: const TextStyle(color: AppColors.muted))]),
          const SizedBox(height: 6),
          ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: value, color: color, backgroundColor: AppColors.key, minHeight: 7)),
        ]),
      );
}

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: const Color(0xFF17232E), borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF25445D))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.info_outline, color: Color(0xFF9ECAFF), size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFB9CADB), fontSize: 12, height: 1.4))),
        ]),
      );
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = AppColors.stroke..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final points = <double>[.82, .74, .68, .57, .61, .49, .38, .43, .28, .34, .18, .25, .10];
    final path = Path();
    for (var i = 0; i < points.length; i++) {
      final point = Offset(size.width * i / (points.length - 1), size.height * points[i]);
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, Paint()..color = AppColors.warm..style = PaintingStyle.stroke..strokeWidth = 3..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Asset {
  const _Asset(this.name, this.symbol, this.amount, this.price, this.change, this.color);
  final String name;
  final String symbol;
  final double amount;
  final double price;
  final double change;
  final Color color;
}
