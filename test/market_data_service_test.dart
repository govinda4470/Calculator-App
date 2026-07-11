import 'package:flutter_test/flutter_test.dart';
import 'package:precision_calc/services/crypto_expert_service.dart';
import 'package:precision_calc/services/market_data_service.dart';

void main() {
  test('parses USD fiat factors into USD-per-unit values', () {
    final factors = MarketDataService.parseFiatFactors({
      'rates': {'EUR': 0.8, 'INR': 80},
    });
    expect(factors['USD'], 1);
    expect(factors['EUR'], 1.25);
    expect(factors['INR'], 0.0125);
  });

  test('parses CoinGecko crypto response', () {
    final time = DateTime.utc(2026, 1, 1);
    final snapshot = MarketDataService.parseCryptoSnapshot({
      'bitcoin': {'usd': 70000, 'inr': 5800000, 'usd_24h_change': 2.5},
      'ethereum': {'usd': 3500, 'inr': 290000, 'usd_24h_change': -1.25},
    }, time);
    expect(snapshot.isLive, isTrue);
    expect(snapshot.updatedAt, time);
    expect(snapshot.crypto['BTC']!.usd, 70000);
    expect(snapshot.crypto['ETH']!.change24h, -1.25);
  });

  test('offline expert uses the current snapshot', () {
    final expert = CryptoExpertService();
    final response = expert.askOffline('What is happening to BTC?', MarketSnapshot.sample());
    expert.close();
    expect(response, contains('BTC'));
    expect(response, contains('not financial advice'));
  });
}
