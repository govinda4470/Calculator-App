import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'market_data_service.dart';

class CryptoExpertService {
  CryptoExpertService({HttpClient? client}) : _client = client ?? HttpClient();
  final HttpClient _client;

  Future<String> askOnline({
    required String question,
    required String apiKey,
    required MarketSnapshot snapshot,
  }) async {
    if (apiKey.trim().isEmpty) throw const CryptoExpertException('Enter an API key first.');
    final request = await _client
        .postUrl(Uri.parse('https://openrouter.ai/api/v1/chat/completions'))
        .timeout(const Duration(seconds: 20));
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer ${apiKey.trim()}')
      ..set(HttpHeaders.contentTypeHeader, 'application/json')
      ..set('HTTP-Referer', 'https://github.com/govinda4470/Calculator-App')
      ..set('X-Title', 'Precision Calc');
    request.write(jsonEncode({
      'model': 'openrouter/auto',
      'temperature': 0.2,
      'max_tokens': 500,
      'messages': [
        {
          'role': 'system',
          'content':
              'You are an educational crypto market assistant inside a calculator app. '
              'Explain evidence, uncertainty, and risk concisely. Never promise returns, issue direct buy/sell instructions, '
              'or claim sample data is live. Mention that this is educational information, not financial advice.',
        },
        {
          'role': 'user',
          'content': '${_marketContext(snapshot)}\n\nQuestion: $question',
        },
      ],
    }));
    try {
      final response = await request.close().timeout(const Duration(seconds: 30));
      final body = await utf8.decoder.bind(response).join();
      final json = jsonDecode(body);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final message = json is Map ? json['error']?.toString() : null;
        throw CryptoExpertException(message ?? 'AI provider returned HTTP ${response.statusCode}.');
      }
      if (json is! Map) throw const CryptoExpertException('Unexpected AI response.');
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) throw const CryptoExpertException('The AI returned no answer.');
      final first = choices.first;
      final content = first is Map && first['message'] is Map ? first['message']['content'] : null;
      if (content is! String || content.trim().isEmpty) throw const CryptoExpertException('The AI returned an empty answer.');
      return content.trim();
    } on TimeoutException {
      throw const CryptoExpertException('The AI request timed out.');
    } on CryptoExpertException {
      rethrow;
    } on Object catch (error) {
      throw CryptoExpertException('AI request failed: $error');
    }
  }

  /// An offline, transparent fallback. This is intentionally called an expert
  /// engine rather than an LLM: it summarizes the available numeric evidence.
  String askOffline(String question, MarketSnapshot snapshot) {
    final normalized = question.toLowerCase();
    final symbols = snapshot.crypto.keys.where((symbol) => normalized.contains(symbol.toLowerCase())).toList();
    final selected = symbols.isEmpty ? snapshot.crypto.keys.take(3).toList() : symbols;
    final details = selected.map((symbol) {
      final quote = snapshot.crypto[symbol]!;
      final direction = quote.change24h > 1
          ? 'positive short-term momentum'
          : quote.change24h < -1
              ? 'negative short-term momentum'
              : 'mostly flat short-term momentum';
      return '$symbol is \$${quote.usd.toStringAsFixed(2)} with ${quote.change24h.toStringAsFixed(2)}% over 24h, indicating $direction.';
    }).join(' ');
    return '$details Price change alone is not enough for a decision; compare volume, liquidity, volatility, time horizon, and downside risk. '
        'This is an automated educational summary, not financial advice.';
  }

  static String _marketContext(MarketSnapshot snapshot) {
    final source = snapshot.isLive ? 'live CoinGecko snapshot' : 'offline sample snapshot';
    final quotes = snapshot.crypto.entries
        .map((entry) => '${entry.key}: USD ${entry.value.usd}, 24h ${entry.value.change24h.toStringAsFixed(2)}%')
        .join('; ');
    return 'Market context ($source, ${snapshot.updatedAt.toUtc().toIso8601String()}): $quotes';
  }

  void close() => _client.close(force: true);
}

class CryptoExpertException implements Exception {
  const CryptoExpertException(this.message);
  final String message;
  @override
  String toString() => message;
}
