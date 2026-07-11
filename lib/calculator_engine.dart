import 'dart:math' as math;

class Calculation {
  const Calculation(this.expression, this.result);
  final String expression;
  final String result;
}

class CalculatorEngine {
  String display = '0';
  String expression = '';
  double? _accumulator;
  String? _operator;
  bool _replace = true;
  final List<Calculation> history = [];

  static String format(double value, {int precision = 10}) {
    if (value.isNaN || value.isInfinite) return 'Error';
    if (value.abs() > 999999999999 || (value != 0 && value.abs() < 0.000000001)) {
      return value.toStringAsExponential(6).replaceAll(RegExp(r'\.?0+e'), 'e');
    }
    var text = value.toStringAsFixed(precision);
    text = text.replaceFirst(RegExp(r'\.?0+$'), '');
    return text == '-0' ? '0' : text;
  }

  void digit(String value) {
    if (_replace || display == 'Error') {
      display = value == '.' ? '0.' : value;
      _replace = false;
    } else if (value == '.' && display.contains('.')) {
      return;
    } else if (display.replaceAll('-', '').replaceAll('.', '').length < 12) {
      display += value;
    }
  }

  void clear() {
    display = '0';
    expression = '';
    _accumulator = null;
    _operator = null;
    _replace = true;
  }

  void backspace() {
    if (_replace) return;
    display = display.length <= 1 || (display.length == 2 && display.startsWith('-'))
        ? '0'
        : display.substring(0, display.length - 1);
  }

  void sign() {
    if (display == '0' || display == 'Error') return;
    display = display.startsWith('-') ? display.substring(1) : '-$display';
  }

  void percent() {
    final value = double.tryParse(display);
    if (value == null) return;
    display = format(value / 100);
    _replace = true;
  }

  void operator(String next) {
    final current = double.tryParse(display);
    if (current == null) return;
    if (_accumulator != null && _operator != null && !_replace) {
      _accumulator = _apply(_accumulator!, current, _operator!);
      display = format(_accumulator!);
    } else {
      _accumulator = current;
    }
    _operator = next;
    expression = '${format(_accumulator!)} $next';
    _replace = true;
  }

  void equals() {
    final current = double.tryParse(display);
    if (current == null || _accumulator == null || _operator == null) return;
    final left = _accumulator!;
    final op = _operator!;
    final result = _apply(left, current, op);
    final exp = '${format(left)} $op ${format(current)}';
    display = format(result);
    expression = exp;
    history.insert(0, Calculation(exp, display));
    _accumulator = result.isFinite ? result : null;
    _operator = null;
    _replace = true;
  }

  double _apply(double a, double b, String op) {
    return switch (op) {
      '+' => a + b,
      '−' => a - b,
      '×' => a * b,
      '÷' => b == 0 ? double.nan : a / b,
      '^' => math.pow(a, b).toDouble(),
      _ => b,
    };
  }

  void constant(double value, String symbol) {
    display = format(value);
    expression = symbol;
    _replace = true;
  }

  void scientific(String function) {
    final value = double.tryParse(display);
    if (value == null) return;
    double result;
    switch (function) {
      case 'sin':
        result = math.sin(value * math.pi / 180);
        break;
      case 'cos':
        result = math.cos(value * math.pi / 180);
        break;
      case 'tan':
        result = math.tan(value * math.pi / 180);
        break;
      case 'log':
        result = value > 0 ? math.log(value) / math.ln10 : double.nan;
        break;
      case 'ln':
        result = value > 0 ? math.log(value) : double.nan;
        break;
      case '√':
        result = value >= 0 ? math.sqrt(value) : double.nan;
        break;
      case 'x²':
        result = value * value;
        break;
      case '1/x':
        result = value == 0 ? double.nan : 1 / value;
        break;
      case 'x!':
        result = _factorial(value);
        break;
      default:
        return;
    }
    final exp = '$function(${format(value)})';
    display = format(result);
    expression = exp;
    history.insert(0, Calculation(exp, display));
    _replace = true;
  }

  double _factorial(double value) {
    if (value < 0 || value > 170 || value != value.roundToDouble()) return double.nan;
    var result = 1.0;
    for (var i = 2; i <= value.toInt(); i++) {
      result *= i;
    }
    return result;
  }

  void useResult(String result) {
    display = result;
    expression = '';
    _accumulator = null;
    _operator = null;
    _replace = true;
  }
}
