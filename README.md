# Precision Calc

A polished Flutter calculator based on the supplied **Precision Dark** design.

## Features
- Basic and scientific calculator modes
- Calculation history with result reuse and clear action
- Length, weight, volume, temperature, currency, crypto, and data conversion
- Optional, hidden-by-default crypto workspace
- Live keyless fiat rates from Frankfurter with offline fallback and manual refresh
- Live crypto quotes from CoinGecko with visible freshness/error state
- Session portfolio tracking, watchlists, market overview, and portfolio analytics
- Transparent offline Crypto Expert engine using current quotes
- Optional online LLM answers through a user-supplied OpenRouter key (held only in memory)
- Clear stale/sample-data and financial-risk disclosures
- Swap units and responsive dark UI
- Settings for precision, haptics, rate updates, crypto visibility, and notifications

## Run
```bash
flutter pub get
flutter run
```

## Build APK
```bash
flutter build apk --release
```
