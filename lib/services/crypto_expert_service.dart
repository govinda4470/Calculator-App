import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'market_data_service.dart';

class CryptoExpertService {
  CryptoExpertService({HttpClient? client}) : _client = client ?? HttpClient();
  final HttpClient _client;
  static const int _maxResponseBytes = 256 * 1024;

  Future<String> askOnline({
    required String question,
    required String apiKey,
    required MarketSnapshot snapshot,
  }) async {
    final cleanQuestion = question.trim();
    final cleanKey = apiKey.trim();
    if (cleanQuestion.isEmpty || cleanQuestion.length > 600) {
      throw const CryptoExpertException('Questions must be between 1 and 600 characters.');
    }
    if (cleanKey.length < 16 || cleanKey.length > 256 || cleanKey.contains(RegExp(r'\s'))) {
      throw const CryptoExpertException('The AI credential format is invalid.');
    }
    final request = await _client
        .postUrl(Uri.parse('https://openrouter.ai/api/v1/chat/completions'))
        .timeout(const Duration(seconds: 20));
    request.followRedirects = false;
    request.headers
      ..set(HttpHeaders.authorizationHeader, 'Bearer $cleanKey')
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
          'content': '${_marketContext(snapshot)}\n\nQuestion: $cleanQuestion',
        },
      ],
    }));
    try {
      final response = await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CryptoExpertException('AI provider rejected the request (${response.statusCode}).');
      }
      if (response.contentLength > _maxResponseBytes) {
        throw const CryptoExpertException('The AI response was too large.');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 30))) {
        if (bytes.length + chunk.length > _maxResponseBytes) {
          throw const CryptoExpertException('The AI response was too large.');
        }
        bytes.addAll(chunk);
      }
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map) throw const CryptoExpertException('Unexpected AI response.');
      final choices = json['choices'];
      if (choices is! List || choices.isEmpty) throw const CryptoExpertException('The AI returned no answer.');
      final first = choices.first;
      final content = first is Map && first['message'] is Map ? first['message']['content'] : null;
      if (content is! String || content.trim().isEmpty) throw const CryptoExpertException('The AI returned an empty answer.');
      final cleanContent = content.trim();
      return cleanContent.length > 6000 ? cleanContent.substring(0, 6000) : cleanContent;
    } on TimeoutException {
      throw const CryptoExpertException('The AI request timed out.');
    } on CryptoExpertException {
      rethrow;
    } on FormatException {
      throw const CryptoExpertException('The AI provider returned invalid data.');
    } on SocketException {
      throw const CryptoExpertException('The AI service is unavailable. Check your connection.');
    } on Object {
      // Never surface transport internals or credentials in user-visible text.
      throw const CryptoExpertException('The AI request could not be completed securely.');
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
    final source = snapshot.isLive ? 'live ${snapshot.provider} snapshot' : 'offline sample snapshot';
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
