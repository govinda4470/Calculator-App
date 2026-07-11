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
  });

  final Map<String, CryptoQuote> crypto;
  final DateTime updatedAt;
  final bool isLive;

  static MarketSnapshot sample() => MarketSnapshot(
        isLive: false,
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

/// Keyless market-data client. Fiat rates come from Frankfurter (ECB-derived)
/// and crypto quotes come from CoinGecko's public API.
class MarketDataService {
  MarketDataService({HttpClient? client}) : _client = client ?? HttpClient();

  final HttpClient _client;
  static const Duration _timeout = Duration(seconds: 12);

  Future<Map<String, double>> fetchUsdFiatFactors() async {
    final json = await _getJson(Uri.parse('https://api.frankfurter.app/latest?from=USD'));
    return parseFiatFactors(json);
  }

  Future<MarketSnapshot> fetchCryptoSnapshot() async {
    final uri = Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price'
      '?ids=bitcoin,ethereum,solana,binancecoin,tether'
      '&vs_currencies=usd,inr&include_24hr_change=true',
    );
    return parseCryptoSnapshot(await _getJson(uri), DateTime.now());
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final request = await _client.getUrl(uri).timeout(_timeout);
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.userAgentHeader, 'PrecisionCalc/1.0');
      final response = await request.close().timeout(_timeout);
      final body = await utf8.decoder.bind(response).join().timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw MarketDataException('Provider returned HTTP ${response.statusCode}.');
      }
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        throw const MarketDataException('Provider returned an unexpected response.');
      }
      return decoded;
    } on TimeoutException {
      throw const MarketDataException('The market-data request timed out.');
    } on MarketDataException {
      rethrow;
    } on Object catch (error) {
      throw MarketDataException('Could not load market data: $error');
    }
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

  void close() => _client.close(force: true);
}
