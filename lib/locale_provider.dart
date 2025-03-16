import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  String _selectedCurrency = 'USD';
  double _conversionRate = 1.0; // Default conversion rate (1.0 for USD)

  String get selectedCurrency => _selectedCurrency;
  double get conversionRate => _conversionRate;

  final Map<String, double> _currencyRates = {
    'USD': 1.0, // Base currency
    'THB': 35.0,
    'EUR': 0.85,
    'JPY': 110.0,
    'GBP': 0.75,
    'AUD': 1.4,
    'CAD': 1.3,
    'INR': 75.0,
    'CNY': 6.5,
    'KRW': 1200.0,
  };

  List<String> get availableCurrencies => _currencyRates.keys.toList();

  void setCurrency(String currency) {
    if (_currencyRates.containsKey(currency)) {
      _selectedCurrency = currency;
      _conversionRate = _currencyRates[currency]!;
      notifyListeners();
    }
  }

  String formatAmount(double amount) {
    return '${_selectedCurrency} ${(amount * _conversionRate).toStringAsFixed(2)}';
  }

  String get currencySymbol {
    switch (_selectedCurrency) {
      case 'USD':
        return '\$';
      case 'THB':
        return '฿';
      case 'EUR':
        return '€';
      case 'JPY':
        return '¥';
      case 'GBP':
        return '£';
      case 'AUD':
        return 'A\$';
      case 'CAD':
        return 'C\$';
      case 'INR':
        return '₹';
      case 'CNY':
        return '¥';
      case 'KRW':
        return '₩';
      default:
        return '\$';
    }
  }
}
