import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:precision_calc/calculator_engine.dart';

void main() {
  group('CalculatorEngine', () {
    test('adds numbers and stores history', () {
      final engine = CalculatorEngine();
      engine.digit('1');
      engine.digit('2');
      engine.operator('+');
      engine.digit('3');
      engine.equals();
      expect(engine.display, '15');
      expect(engine.history.single.expression, '12 + 3');
    });

    test('handles divide by zero', () {
      final engine = CalculatorEngine();
      engine.digit('8');
      engine.operator('÷');
      engine.digit('0');
      engine.equals();
      expect(engine.display, 'Error');
    });

    test('supports scientific operations', () {
      final engine = CalculatorEngine();
      engine.digit('9');
      engine.scientific('√');
      expect(engine.display, '3');
      engine.constant(math.pi, 'π');
      expect(double.parse(engine.display), closeTo(math.pi, 1e-9));
    });
  });
}
