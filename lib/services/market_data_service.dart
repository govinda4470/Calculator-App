import 'dart:async';
import 'dart:convert';
import 'dart:io';

class MarketDataException implements Exception {
  const MarketDataException(this.message);
  final String message;
  @override
  String toString() => message;
}

class CryptoQuote {
  const CryptoQuote({required this.usd, required this.inr, required this.change24h});
  final double usd;
  final double inr;
  final double change24h;
}

class MarketSnapshot {
  const MarketSnapshot({
    required this.crypto,
    required this.updatedAt,
    this.isLive = true,
    this.provider = 'CoinGecko',
  });

  final Map<String, CryptoQuote> crypto;
  final DateTime updatedAt;
  final bool isLive;
  final String provider;

  static MarketSnapshot sample() => MarketSnapshot(
        isLive: false,
        provider: 'Offline sample',
        updatedAt: DateTime.now(),
        crypto: const {
          'BTC': CryptoQuote(usd: 64231.20, inr: 5361538, change24h: 2.4),
          'ETH': CryptoQuote(usd: 3520.45, inr: 293879, change24h: 1.8),
          'SOL': CryptoQuote(usd: 142.80, inr: 11919, change24h: -0.5),
          'BNB': CryptoQuote(usd: 585.30, inr: 48849, change24h: 0.9),
          'USDT': CryptoQuote(usd: 1, inr: 83.47, change24h: 0),
        },
      );
}

/// Market-data client. Fiat reference rates come from Frankfurter
/// (ECB-derived). Crypto quotes use CoinGecko when anonymous access is
/// available and keyless Binance public tickers as a fallback.
class MarketDataService {
  MarketDataService({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;
  static const Duration _timeout = Duration(seconds: 12);
  static const int _maxResponseBytes = 1024 * 1024;
  static const Set<String> _allowedHosts = {
    'api.frankfurter.app',
    'api.coingecko.com',
    'api.binance.com',
  };
  static Map<String, double>? _fiatCache;
  static DateTime? _fiatCachedAt;
  static MarketSnapshot? _cryptoCache;

  Future<Map<String, double>> fetchUsdFiatFactors({bool forceRefresh = false}) async {
    final cachedAt = _fiatCachedAt;
    if (!forceRefresh &&
        _fiatCache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < const Duration(hours: 6)) {
      return Map.unmodifiable(_fiatCache!);
    }
    final json = await _getJson(Uri.parse('https://api.frankfurter.app/latest?from=USD'));
    final factors = parseFiatFactors(json);
    _fiatCache = Map.unmodifiable(factors);
    _fiatCachedAt = DateTime.now();
    return Map.unmodifiable(factors);
  }

  Future<MarketSnapshot> fetchCryptoSnapshot({bool forceRefresh = false}) async {
    final cached = _cryptoCache;
    if (!forceRefresh && cached != null && DateTime.now().difference(cached.updatedAt) < const Duration(minutes: 2)) {
      return cached;
    }
    final uri = Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price'
      '?ids=bitcoin,ethereum,solana,binancecoin,tether'
      '&vs_currencies=usd,inr&include_24hr_change=true',
    );
    try {
      final snapshot = parseCryptoSnapshot(await _getJson(uri), DateTime.now());
      _cryptoCache = snapshot;
      return snapshot;
    } on Object {
      // CoinGecko can require a demo key or throttle anonymous clients. Binance
      // public tickers provide a keyless fallback for the supported pairs.
      const pairs = {'BTC': 'BTCUSDT', 'ETH': 'ETHUSDT', 'SOL': 'SOLUSDT', 'BNB': 'BNBUSDT'};
      final responses = await Future.wait(
        pairs.entries.map((entry) async => MapEntry(
              entry.key,
              await _getJson(Uri.parse('https://api.binance.com/api/v3/ticker/24hr?symbol=${entry.value}')),
            )),
      );
      final snapshot = parseBinanceSnapshot(Map.fromEntries(responses), DateTime.now());
      _cryptoCache = snapshot;
      return snapshot;
    }
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    if (uri.scheme != 'https' || !_allowedHosts.contains(uri.host)) {
      throw const MarketDataException('Blocked an untrusted market-data endpoint.');
    }
    try {
      final request = await _client.getUrl(uri).timeout(_timeout);
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'PrecisionCalc/1.0');
      final response = await request.close().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MarketDataException('Provider returned HTTP ${response.statusCode}.');
      }
      if (response.contentLength > _maxResponseBytes) {
        throw const MarketDataException('Provider response was too large.');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(_timeout)) {
        if (bytes.length + chunk.length > _maxResponseBytes) {
          throw const MarketDataException('Provider response was too large.');
        }
        bytes.addAll(chunk);
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const MarketDataException('Provider returned an unexpected response.');
      }
      return decoded;
    } on TimeoutException {
      throw const MarketDataException('The market-data request timed out.');
    } on MarketDataException {
      rethrow;
    } on FormatException {
      throw const MarketDataException('Provider returned invalid market data.');
    } on SocketException {
      throw const MarketDataException('Market data is unavailable. Check your connection.');
    } on Object {
      // Do not expose socket, certificate, or internal provider details in UI.
      throw const MarketDataException('Market data is temporarily unavailable.');
    }
  }

  static void clearMemoryCache() {
    _fiatCache = null;
    _fiatCachedAt = null;
    _cryptoCache = null;
  }

  static Map<String, double> parseFiatFactors(Map<String, dynamic> json) {
    final rawRates = json['rates'];
    if (rawRates is! Map) throw const MarketDataException('Fiat rates are missing.');
    final factors = <String, double>{'USD': 1};
    for (final entry in rawRates.entries) {
      final rate = entry.value;
      if (rate is num && rate > 0) factors[entry.key.toString()] = 1 / rate.toDouble();
    }
    if (factors.length < 2) throw const MarketDataException('No valid fiat rates were returned.');
    return factors;
  }

  static MarketSnapshot parseCryptoSnapshot(Map<String, dynamic> json, DateTime updatedAt) {
    const ids = {
      'BTC': 'bitcoin',
      'ETH': 'ethereum',
      'SOL': 'solana',
      'BNB': 'binancecoin',
      'USDT': 'tether',
    };
    final quotes = <String, CryptoQuote>{};
    for (final entry in ids.entries) {
      final data = json[entry.value];
      if (data is! Map) continue;
      final usd = data['usd'];
      if (usd is! num || usd <= 0) continue;
      quotes[entry.key] = CryptoQuote(
        usd: usd.toDouble(),
        inr: (data['inr'] as num?)?.toDouble() ?? 0,
        change24h: (data['usd_24h_change'] as num?)?.toDouble() ?? 0,
      );
    }
    if (quotes.isEmpty) throw const MarketDataException('No valid crypto quotes were returned.');
    return MarketSnapshot(crypto: quotes, updatedAt: updatedAt);
  }

  static MarketSnapshot parseBinanceSnapshot(Map<String, Map<String, dynamic>> json, DateTime updatedAt) {
    final quotes = <String, CryptoQuote>{};
    for (final entry in json.entries) {
      final price = double.tryParse(entry.value['lastPrice']?.toString() ?? '');
      final change = double.tryParse(entry.value['priceChangePercent']?.toString() ?? '');
      if (price == null || price <= 0) continue;
      quotes[entry.key] = CryptoQuote(usd: price, inr: 0, change24h: change ?? 0);
    }
    quotes['USDT'] = const CryptoQuote(usd: 1, inr: 0, change24h: 0);
    if (quotes.length < 2) throw const MarketDataException('No valid Binance quotes were returned.');
    return MarketSnapshot(crypto: quotes, updatedAt: updatedAt, provider: 'Binance');
  }

  void close() => _client.close(force: true);
}
